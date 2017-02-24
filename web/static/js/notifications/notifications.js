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
      console.log("receiving update_pages: ", payload);
      pagination.update(payload);
    });
    
    for (let i = 0; i < declineBtns.length; i++) {
      declineBtns[i].addEventListener('click', (e) => {
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
    
    let initInvitationTableMarkup = (title, id, participants, owner) => {
      return $(`<table class="centered responsive-table" id="invitations-table">
          <thead>
            <tr>
              <th data-field="title">Game</th>
              <th data-field="participants">Players</th>
              <th data-field="button">Go</th>
              <th data-field="decline">Decline</th>
            </tr>
          </thead>
          <tbody id="invitations-table-body">
            <tr id="row-${id}">
              <td>${title}</td>
              <td>${participants}</td>
              <td><a class="btn-floating green waves-effect" href="/private/rooms/${id}">Go</a></td>
              <td>
                <button type="button" class="btn-floating pink decline-btn waves-effect" id="decline-${id}">
                  <i class="material-icons">clear</i>
                </button>
              </td>
            </tr>
          </tbody>`);
    };
    
    channel.on("invitation_received", ({title, id, participants, owner}) => {
      console.log('invitation_received event received');
      let appendInvitation = () => {
        let markup = `<tr id="row-${id}">
                        <td>${title}</td>
                        <td>${participants}</td>
                        <td><a class="btn-floating green waves-effect" href="/private/rooms/${id}">Go</a></td>
                        <td>
                          <button type="button" class="btn-floating pink decline-btn waves-effect" id="decline-${id}">
                            <i class="material-icons">clear</i>
                          </button>
                        </td>
                      </tr>`;
        $("#invitations-table-body").append(markup);
        $(`#decline-${id}`).on('click', () => {
          channel.push('decline_invitation', {room: id});
        });
      };
      if (!($("#invitations-table-body") == undefined)) {
        appendInvitation();
      } else {
        let markup = initInvitationTableMarkup(title, id, participants, owner);
        console.log('inside else statement with markup: ', markup);
        $("#invitations-card").append(markup);
        $(`#decline-${id}`).on('click', () => {
          channel.push('decline_invitation', {room: id});
        });
      }
      window.Materialize.toast(`${owner} has invited you to ${title}`, 3000, 'green-toast');
    });
  }
}