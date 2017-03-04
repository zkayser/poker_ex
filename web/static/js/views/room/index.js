import MainView from '../main-view';
import RoomMonitor from '../../components/room-monitor';

export default class RoomIndexView extends MainView {
  mount() {
    super.mount();
    console.log("RoomIndexView mounted");
    
    let monitor = new RoomMonitor();
    monitor.init();
  }
  
  unmount() {
    super.unmount();
    
    console.log("RoomIndexView unmounted");
  }
}