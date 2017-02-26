import {Socket} from "phoenix";
import $ from 'jquery';

import PlayerUpdates from "./updates/player-updates";
import Pagination from '../components/pagination';

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
    
    let pagination = new Pagination({channel: channel});
    pagination.init();
    
    channel.on("update_pages", (payload) => {
      pagination.update(payload);
    });
    
    for (let i = 0; i < declineBtns.length; i++) {
      declineBtns[i].addEventListener('click', (e) => {
        let id = e.target.parentElement.id;
        console.log('id: ', id);
        let regex = /\d+/;
        let res = id.match(regex);
        id = res[0];
        channel.push("decline_invitation", {room: id});
      });
    }
    
    channel.on("declined_invitation", (payload) => {
      let id = payload.remove;
      $(`#${id}`).css('background-color', 'red !important').css('transition', 'background-color 0.7s ease');
      $(`#${id}`).slideUp('slow');
      
      let current = $("#invitation-number").text();
      let update = parseInt(current, 10) - 1;
      $("#invitation-number").text(`${update}`);
    });
    
    channel.on("decline_error", (payload) => {
      window.Materialize.toast(`Failed to decline invitation to ${payload.room}`, 3000, 'red-toast');
    });
    
    channel.on("invitation_received", ({title, id, participants, owner}) => {
      let appendInvitation = () => {
        let markup = `
                      <li class="collection-item blue white-text" id="row-${id}">
                        <span class="left" id="invitation-title">${title}</span>  
                        <span id="num-players-invitation">PLAYERS: ${title}</span>
                        <div id="go-decline">
                          <span id="go-btn-span">
                            <a href="/private/rooms/${id}" class="btn-floating green waves-effect">Go</a>
                          </span>
                          <span id="invitation-decline">
                            <button type="button" class="btn-floating pink decline-btn waves-effect" id="decline-${id}">
                              <i class="material-icons">clear</i>
                            </button>
                          </span>
                        </div>
                    </li>`;
        $(".invitation-list").append(markup);
        $(`#decline-${id}`).on('click', () => {
          channel.push('decline_invitation', {room: id});
        });
      };
      if (!($(".invitation-list") == undefined)) {
        appendInvitation();
      }
      window.Materialize.toast(`${owner} has invited you to ${title}`, 3000, 'green-toast');
    });
  }
}