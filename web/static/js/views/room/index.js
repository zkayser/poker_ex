import MainView from '../main-view';
import RoomMonitor from '../../components/room-monitor';
import Connection from '../../socket';

export default class RoomIndexView extends MainView {
  mount() {
    super.mount();
    console.log("RoomIndexView mounted");
    
    let monitor = new RoomMonitor();
    monitor.init();
    // Connection.init();
  }
  
  unmount() {
    super.unmount();
    
    console.log("RoomIndexView unmounted");
  }
}