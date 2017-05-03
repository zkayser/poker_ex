import MainView from '../main-view';
import Notifications from '../../notifications/notifications';
import $ from 'jquery';

export default class PlayerShowView extends MainView {
  mount() {
    super.mount();
    console.log("PlayerShowView mounted");
    
    // Connect to a socket and subscribe to notifications to the 
    // player model, invites to games, and messages.
    Notifications.init();
    setTimeout(() => {
      if (window.FB) {
        let FB = window.FB;
        $("#fb-invite-btn").click(() => {
          FB.ui({method: 'apprequests',
            message: "Join me for a game of Poker on PokerEX!"
            }, function(response){
            console.log(response);
          });
        });
      }
    }, 500);
  }
  
  unmount() {
    super.unmount();
    
    console.log("PlayerShowView unmounted");
  }
}