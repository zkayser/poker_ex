export default class RoomMessages {
  constructor() {}
  
  static init(channel) {
    
    channel.on("new_msg", payload => {
      Materialize.toast(`${payload.body} joined the lobby`, 3000, 'rounded')
    });
    
    channel.on("winner_message", payload => {
      console.log("winner_message", payload.message);
    });
    
    channel.on("player_left", payload => {
      Materialize.toast(`${payload.body.name} left`, 3000, 'rounded');
    });
  }
}