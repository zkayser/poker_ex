import Controls from '../components/controls';
import Table from '../table';
import PlayerToolbar from '../components/player-toolbar';
import RaiseControl from '../components/raise-control';


export default class Dispatcher {
  
  static dispatch(message, state, ...extra) {
    // Define messages
    switch (message) {
      case 'advance': 
        console.log("Got advance message in Dispatcher...", message, state, extra);
        break;
    default:
      console.log("dispatch switch statement did not catch any defined messages; message, state, ...extra: ", message, state, extra);
    }
     
  }
}