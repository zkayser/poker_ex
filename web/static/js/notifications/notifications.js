import {Socket} from "phoenix";
import $ from 'jquery';
import PlayerUpdates from "./updates/player-updates";

export default class Notifications {
  constructor() {}
  
  static init() {
    let profile = document.getElementById("player-profile");
    let playerId = profile.getAttribute("data-player-id");
    let declineBtns = document.getElementsByClassName("decline-btn");
    
    let socket = new Socket('/socket', {params: {
     token: window.playerToken
    }});
    
    socket.connect();
    
    let channel = socket.channel(`notifications:${playerId}`);
    
    channel.join()
    .receive("ok", resp => {
      PlayerUpdates.init(channel);
      console.log("successfully joined notifications channel for player: ", playerId);
    })
    .receive("error", reason => {
      console.log("joining notifications channel failed for reason: ", reason);
    });
    
    for (let i = 0; i < declineBtns.length; i++) {
      declineBtns[i].addEventListener('click', (e) => {
        console.log("decline btn pressed: ", e.target.parentElement);
        let id = e.target.parentElement.id;
        id = id.split("-")[1];
        channel.push("decline_invitation", {room: id});
      });
    }
    
    channel.on("declined_invitation", (payload) => {
      let id = payload.remove;
      $(`#${id}`).css('transition', 'background-color 0.75s ease').css('background-color', 'red');
      $(`#${id}`).slideUp('slow');
      
      let current = $("#invitation-number").text();
      let update = parseInt(current, 10) - 1;
      $("#invitation-number").text(`${update}`);
    });
    
    channel.on("decline_error", (payload) => {
      window.Materialize.toast(`Failed to decline invitation to ${payload.room}`, 3000, 'red-toast');
    });
    
    channel.on("invitation_received", ({title, id, participants, owner}) => {
      if (!($("#invitations-table-body") == undefined)) {
        let fragment = document.createDocumentFragment();
        let tr = document.createElement('tr');
        let td1 = document.createElement('td');
        td1.innerText = title;
        let td2 = document.createElement('td');
        td2.innerText = participants.length;
        let td3 = document.createElement('td');
        td3.innerHTML = `<a class="btn-floating green" href="/private/rooms/${id}">Go</a>`;
        let tds = [td1, td2, td3];
        tds.forEach(el => {
          tr.appendChild(el);
        });
        fragment.appendChild(tr);
        document.querySelector("#invitations-table-body").appendChild(fragment);
      }
      window.Materialize.toast(`${owner} has invited you to join ${title}`, 3000);
    });
  }
}