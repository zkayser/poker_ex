import MainView from '../main-view';
import Game from '../../game';

export default class PrivateRoomShowView extends MainView {
  
  mount() {
    super.mount();
    console.log("PrivateRoomShowView mounted...");
    
    let div = document.getElementById("room-row");
    let roomTitle = div.dataset.roomTitle;
    let player = div.dataset.userName;
    
    let game = new Game(player, roomTitle);
    game.init();
  }
  
  unmount() {
    super.unmount();
  }
}