import MainView from '../main-view';
import Connection from '../../socket';

export default class RoomIndexView extends MainView {
  mount() {
    super.mount();
    console.log("RoomIndexView mounted");
    
    Connection.init();
  }
  
  unmount() {
    super.unmount();
    
    console.log("RoomIndexView unmounted");
  }
}