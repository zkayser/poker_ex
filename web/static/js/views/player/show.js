import MainView from '../main-view';
import Notifications from '../../notifications/notifications';

export default class PlayerShowView extends MainView {
  mount() {
    super.mount();
    console.log("PlayerShowView mounted");
    
    // Connect to a socket and subscribe to notifications to the 
    // player model, invites to games, and messages.
    Notifications.init();
  }
  
  unmount() {
    super.unmount();
    
    console.log("PlayerShowView unmounted");
  }
}