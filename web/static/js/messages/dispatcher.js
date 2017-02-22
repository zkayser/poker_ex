import Table from '../table';

export default class Dispatcher {
  
  static dispatch(message, payload, options) {
    let game = options.game;
    let channel = options.channel;
    // Define messages
    switch (message) {
      case "private_room_join":
        game.playerToolbar.init(game.dataFormatter.format(game.addUser(payload)));
        if (payload.state == "idle" || payload.state == "between_rounds") {
          console.log("Game currently in state: ", payload.state);
          if (!game.table) {
            game.table = new Table(game.dataFormatter.format(game.addUser(payload)));
            game.table.renderPlayers();
          }
        } else {
          game.setup(payload, channel);
        }
        break;
      case "started_game":
        game.setup(payload, channel);
        break;
      case "game_started":
        if (game.controls) {
          game.controls.clear();
        }
        game.table.clear();
        game.setup(payload, channel);
        break;
      case "add_player_success":
        game.playerToolbar.update(game.dataFormatter.format(payload));
        Table.renderPlayers(game.dataFormatter.format(payload).seating);
        break;
      case "update":
        game.update(payload, channel);
        break;
      case "game_finished":
        window.Materialize.toast(payload.message, 3000);
        break;
      case "winner_message":
        window.Materialize.toast(payload.message, 3000);
        break;
      case "new_message":
        if (!(payload.name == game.userName)) {
          window.Materialize.toast(`${payload.name} says: ${payload.text}`, 3000, 'green-toast');
        }
        game.chatComponent.update(payload);
        break;
    default:
      console.log("dispatch switch statement did not catch any defined messages; message, state, ...extra: ", message, payload, options);
    }
  }
}