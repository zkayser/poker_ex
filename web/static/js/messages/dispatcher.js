import $ from 'jquery';

import Controls from '../components/controls';
import Table from '../table';
import PlayerToolbar from '../components/player-toolbar';
import RaiseControl from '../components/raise-control';
import Card from '../card';


export default class Dispatcher {
  
  static dispatch(message, payload, ...extra) {
    // Define messages
    switch (message) {
      case 'advance': 
        console.log("Got advance message in Dispatcher...", message, payload, extra);
        break;
      case 'game_finished':
        let game = extra[0];
        game.table.clear();
        break;
      case 'started_game':
        console.log("STARTING GAME...", payload);
        game = extra[0];
        $("#start-btn").slideUp();
        $("#start-info-item").html('<a href="#player-account-modal" class="white-text waves-effect waves-light"><i class="material-icons">account_circle</i></a>');
        // Init the table state, player controls, and raise control panel
        let data = game.dataFormatter.format(game.addUser(payload));
        data.channel = game.channel;
        game.table = new Table(data);
        game.controls = new Controls(data);
        game.raiseControl = new RaiseControl(data);
        Card.renderPlayerCards(data.playerHand);
        game.table.init(data);
        game.controls.update(data);
        game.raiseControl.init(); 
      console.log("AFTER STARTED GAME: ", game);
      case 'game_started':
        game = extra[0];
        data = game.dataFormatter.format(game.addUser(payload));
        game.table.update(data);
        game.controls.update(data);
        game.raiseControl.update(data);
        break;
    default:
      console.log("dispatch switch statement did not catch any defined messages; message, state, ...extra: ", message, payload, extra);
    }
     
  }
}