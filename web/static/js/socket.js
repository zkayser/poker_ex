import {Socket} from "phoenix";

import Player from "./player";
import PlayerMessages from './messages/player-messages';
import TableConcerns from "./table-concerns";
import RoomMessages from './messages/room-messages';
import Signup from "./signup";
import MessageBox from './message-box';

let Connection = {
  
  init(name){
    let socket = new Socket('/socket', {params: {name: name}});
    socket.connect();
    let channel = socket.channel("players:lobby", {});
    TableConcerns.init(channel, name);
    PlayerMessages.init(channel, name);
    RoomMessages.init(channel);
    this.me = name;
    
    channel.join()
    .receive("ok", initialPlayers => {
      Signup.fadeOnSignin();
      console.log("joined lobby", name);
      if(!(initialPlayers.players === null)) {
        initialPlayers.players.forEach(player => {
          let msg = Player.addToList(player.name);
          MessageBox.appendAndScroll(msg);
        });
      }
      channel.push("new_msg", {body: name});
    });
    
  },
};

export default Connection;
