import {Socket} from 'phoenix';
import MainView from '../main-view';
import $ from 'jquery';
import SpinnerAnimation from '../../animations/spinner-animations';
import Table from '../../table';
import Card from '../../card';
import TableConcerns from '../../table-concerns';
import PlayerMessages from '../../messages/player-messages';
import RoomMessages from '../../messages/room-messages';

export default class PrivateRoomShowView extends MainView {
  
  mount() {
    super.mount();
    console.log("PrivateRoomShowView mounted...");
    
    let div = document.getElementById("room-row");
    let roomTitle = div.dataset.roomTitle;
    let player = div.dataset.userName;
    let joinBtn = $("#join-btn");
    let leaveBtn = $("#leave-btn");
    
    let socket = new Socket('/socket', {params: {token: window.playerToken}});
    
    socket.connect();
    let channel = socket.channel(`players:${roomTitle}`, {type: "private"});
    
    channel.join()
    .receive("ok", params => {
      console.log("Channel joined; callback params received: ", params);
      joinBtn.click(() => {
        channel.push("add_player", {player: player, room: roomTitle});
        joinBtn.slideUp();
      });
      leaveBtn.click(() => {
        channel.push("remove_player", {player: player, room: roomTitle});
        leaveBtn.slideUp();
      });
    })
    .receive("error", params => {
      console.log("Something went wrong when joining channel: ", params);
    });
    
    // Initialize the table UI and player info section in this callback, then init TableConcerns
    channel.on("private_room_join", state => {
      console.log("private_room_join received with: ", state);
      SpinnerAnimation.onJoinPrivateRoom();
      Table.renderPlayers(state.seating);
      Table.addActiveClass(state.active);
      this.handlePlayerHands(player, state.player_hands);
      this.setPot(state.pot);
      TableConcerns.init(channel, player, {}, state);
      PlayerMessages.init(channel, player);
      RoomMessages.init(channel);
    });
    
    channel.on("join_room_success", () => {
      console.log("Room joined successfully!");
    });
    
    channel.on("error_on_room_join", (payload) => {
      console.log("An error occured when joining the room: ", payload);
    });
  }
  
  handlePlayerHands(player, player_hands) {
    let players = player_hands.map((obj) => {
      obj.player;
    });
    if (players.includes(player)) {
      $("#offscreen-left").addClass("slide-onscreen-right");
      let cardHolder = document.querySelector(".card-holder");
      cardHolder.style.visibility = "visible";
      let filtered = player_hands.filter((obj) => {
        if (obj.player == player) {
          return true;
        }
      });
      let {hand} = filtered[0].hand;
      let playerCards = document.getElementById("player-cards");
      let children = playerCards.childNodes;
      let cards = Card.renderPlayerCards(hand);
      
      for (let i = children.length - 1; i >= 0; i-- ) {
        playerCards.removeChild(children[i]);
      }
      cards.forEach((card) => {
        playerCards.appendChild(card);
      });
    }
  }
  
  setPot(pot) {
    $("#pot").text(pot);
  }
  
  unmount() {
    super.unmount();
  }
}