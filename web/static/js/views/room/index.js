import MainView from '../main-view';

export default class RoomIndexView extends MainView {
  mount() {
    super.mount();
    
    // RoomIndex specific logic goes here.
    console.log("RoomIndexView mounted");
  }
  
  unmount() {
    super.unmount();
    
    console.log("RoomIndexView unmounted");
  }
}