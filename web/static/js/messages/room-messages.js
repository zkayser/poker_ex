export default class RoomMessages {
  constructor() {}
  
  static init(channel) {
    let Materialize = window.Materialize;
    
    channel.on("new_msg", payload => {
      Materialize.toast(`${payload.body} joined the lobby`, 3000, 'rounded');
    });
    
    channel.on("winner_message", payload => {
      Materialize.toast(`${payload.message}`, 2000, 'rounded');
    });
    
    channel.on("welcome_player", payload => {
      Materialize.toast(`Welcome to the lobby.`, 2000, 'rounded');
    });
    
    channel.on("game_finished", payload => {
      setTimeout(() => {
        Materialize.toast(`${payload.message}`, 2000, 'rounded');
      }, 1000);
    });
    
    channel.on("player_left", payload => {
      Materialize.toast(`${payload.body.name} left`, 3000, 'rounded');
    });
    
    channel.on("player_got_up", payload => {
      Materialize.toast(`${payload.player} left`, 3000, 'rounded');
    });
  }
}