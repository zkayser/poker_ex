import $ from 'jquery';
import {Socket} from 'phoenix';

import RoomsListAnimation from '../animations/rooms-list-animation';

export default class RoomMonitor {
  
  init() {
    let socket = new Socket('/socket', {params: 
      {token: window.playerToken}
    });
    
    socket.connect();
    let channel = socket.channel("players:lobby", {});
    
    channel.join()
    .receive("ok", () => {
      channel.push("get_num_players", {});
      RoomsListAnimation.animate();
    });
    
    channel.on("update_num_players", (payload) => {
      let message = this.message(payload.length);
      $(`#${payload.room}-players`).text(message);
    });
    
    setInterval(() => {
      channel.push("get_num_players", {});
    }, 5000);
  }
  
  message(length) {
    switch (length) {
      case 0:
        return "There are no players currently at this table.";
      case 1:
        return "There is 1 player waiting at this table.";
      default:
        return `There are ${length} players at the table.`;
    }
  }
}