import {Socket} from "phoenix";
import $ from 'jquery';

import Player from "./player";
import PlayerMessages from './messages/player-messages';
import TableConcerns from "./table-concerns";
import RoomMessages from './messages/room-messages';
import SpinnerAnimation from "./animations/spinner-animations";
import MessageBox from './message-box';

let Connection = {
  
  setRoomsLinks(socket, name) {
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
        
        let room = klass;
        let roomChan = socket.channel(`players:${room}`, {player: name});
        roomChan.join()
        .receive("ok", payload => {
          console.log(`Room channel players:${room} joined with payload: `, payload);
        });
        
        // Test code
        roomChan.on("room_joined", (payload) => {
          TableConcerns.init(roomChan, name);
          PlayerMessages.init(roomChan, name);
          RoomMessages.init(roomChan);
          console.log("room_joined", payload);
        });
      });
    });
  
    console.log("setRoomsLinks called and classArray: ", classArray);
  },
   
  init(name){
    let Materialize = window.Materialize;
    let socket = new Socket('/socket', {params: {name: name}});
    socket.connect();
    let channel = socket.channel("players:lobby", {});
    
    /*
    TableConcerns.init(channel, name);
    PlayerMessages.init(channel, name);
    RoomMessages.init(channel);
    */
    this.me = name;
    
    
    channel.join()
    .receive("ok", initialPlayers => {
      SpinnerAnimation.fadeOnSignin();
      Materialize.toast(`Welcome to PokerEx, ${name}`, 3000, 'rounded');
      this.setRoomsLinks(socket, name);
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
