import {Socket} from "phoenix";
import $ from 'jquery';

import PlayerMessages from './messages/player-messages';
import TableConcerns from "./table-concerns";
import RoomMessages from './messages/room-messages';
import LobbyMessages from "./messages/lobby-messages";
import SpinnerAnimation from "./animations/spinner-animations";
import RoomsListAnimation from "./animations/rooms-list-animation";


let Connection = {
  
  init(){
    let Materialize = window.Materialize;
    
    let socket = new Socket('/socket', {params: 
      {token: window.playerToken},
      logger: (kind, msg, data) => {console.log(`${kind}:${msg}`, data)}
      });
      
    socket.connect();
    let channel = socket.channel("players:lobby", {});
    
    
    channel.join()
    .receive("ok", ({name}) => {
      console.log("Joined players lobby: ", name);
      SpinnerAnimation.fadeOnSignin();
      LobbyMessages.init(channel);
      channel.push("get_num_players", {});
      this.setRoomsLinks(socket, name, channel);
      RoomsListAnimation.animate();
    });
    
  },
  
  setRoomsLinks(socket, name, lobby) {
    let links = document.getElementsByTagName('a');
    let classArray = [];
    let roomRegEx = new RegExp("room_");
    
    for (let i = 0; i < links.length; i++) {
      if (roomRegEx.test(links[i].className)) {
        classArray.push(links[i].className);
      }
    }
    
    
    classArray.forEach((klass) => {
      $(`a.${klass}`).click(() => {
        SpinnerAnimation.initiateSpinnerOnElement($(".join-spinner"), $(".collection"));
        SpinnerAnimation.onJoinRoom();
        
        let room = klass;
        let roomChan = socket.channel(`players:${room}`, {player: name});
        roomChan.join()
        .receive("ok", ({players}) => {
          TableConcerns.init(roomChan, name, players, {});
          PlayerMessages.init(roomChan, name);
          RoomMessages.init(roomChan);
        });
      });
    });
  
  }
};

export default Connection;
