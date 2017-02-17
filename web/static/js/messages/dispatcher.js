import $ from 'jquery';

import Controls from '../components/controls';
import Table from '../table';
import PlayerToolbar from '../components/player-toolbar';
import RaiseControl from '../components/raise-control';
import Card from '../card';


export default class Dispatcher {
  
  static dispatch(message, payload, options) {
    let game = options.game;
    let channel = options.channel;
    // Define messages
    switch (message) {
      case "private_room_join":
        if (payload.state == "idle" || payload.state == "between_rounds") {
          console.log("Game currently in state: ", payload.state);
        } else {
          game.setup(payload, channel);
        }
        break;
      case "started_game":
        game.setup(payload, channel);
        break;
      case "game_started":
        game.table.clear();
        game.setup(payload, channel);
        break;
      case "update":
        game.update(payload, channel);
        break;
    default:
      console.log("dispatch switch statement did not catch any defined messages; message, state, ...extra: ", message, payload, options);
    }
  }
}