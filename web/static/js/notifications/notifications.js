import {Socket} from "phoenix";
import $ from 'jquery';
import PlayerUpdates from "./updates/player-updates";

export default class Notifications {
  constructor() {}
  
  static init() {
    let profile = document.getElementById("player-profile");
    let playerId = profile.getAttribute("data-player-id");
    
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