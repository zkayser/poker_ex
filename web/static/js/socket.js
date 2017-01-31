import {Socket} from "phoenix";
import $ from 'jquery';

import Player from "./player";
import PlayerMessages from './messages/player-messages';
import TableConcerns from "./table-concerns";
import RoomMessages from './messages/room-messages';
import SpinnerAnimation from "./animations/spinner-animations";
import MessageBox from './message-box';

let Connection = {
  
  setRoomsLinks(socket, name, lobby) {
    let links = document.getElementsByTagName('a');
    let classArray = [];
    let roomRegEx = new RegExp("room_");
    
    for (let i = 0; i < links.length; i++) {
      if (roomRegEx.test(links[i].className)) {
        classArray.push(links[i].className);
      }
    }
    
    // Does not work when you click on a link and issue
    // a new request. You need a new strategy.
    
    classArray.forEach((klass) => {
      $(`a.${klass}`).click(() => {
        SpinnerAnimation.initiateSpinnerOnElement($(".join-spinner"), $(".collection"));
        SpinnerAnimation.onJoinRoom();
        lobby.leave();
        
        let room = klass;
        let roomChan = socket.channel(`players:${room}`, {player: name});
        roomChan.join()
        .receive("ok", ({players}) => {
          console.log(`Room channel players:${room} joined with players: `, players);
          TableConcerns.init(roomChan, name, players);
          PlayerMessages.init(roomChan, name);
          RoomMessages.init(roomChan);
        });
      });
    });
  
    console.log("setRoomsLinks called and classArray: ", classArray);
  },
   
  init(name){
    let Materialize = window.Materialize;
    // The server will now give you back a player_id rather than a name.
    // Consequently, the params will be modified to {token: window.playerToken}
    // rather than {name: name}
    let socket = new Socket('/socket', {params: 
      {token: window.playerToken},
      logger: (kind, msg, data) => {console.log(`${kind}:${msg}`, data)}
      });
    socket.connect();
    let channel = socket.channel("players:lobby", {});
    
    this.me = name;
    
    
    channel.join()
    .receive("ok", initialPlayers => {
      SpinnerAnimation.fadeOnSignin();
      Materialize.toast(`Welcome to PokerEx, ${name}`, 3000, 'rounded');
      this.setRoomsLinks(socket, name, channel);
      console.log("joined lobby", name);
      /* if(!(initialPlayers.players === null)) {
        initialPlayers.players.forEach(player => {
          let msg = Player.addToList(player.name);
          MessageBox.appendAndScroll(msg);
        });
      } */
      channel.push("new_msg", {body: name});
    });
    
  },
};

export default Connection;
