import $ from 'jquery';

export default class LobbyMessages {
  
  constructor() {}
  
  static init(channel) {
    
    channel.on("update_num_players", ({room, number}) => {
      let string = "";
      if (number == 1) {
         string = "1 player currently at table";
      } else if (number == 0 || number == null) {
        string = "There are no players currently at table";
      } else {
        string = `${number} players currently at table`; 
      }
      $(`#${room}-players`).empty().text(string);
    });
  }
}