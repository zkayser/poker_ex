import {Socket} from 'phoenix';
import $ from 'jquery';
import MainView from './main-view';

export default class OnlineView extends MainView {
  mount() {
    super.mount();
    console.log("Mounting OnlineView");
    
    let playerID = $("meta[name='player-id']").attr("content");
    
    let socket = new Socket('/socket', {params: {
     token: window.playerToken
    }});
    
    socket.connect();
    
    let notifications = socket.channel(`notifications:${playerID}`);
    
    notifications.join()
    .receive("ok", resp => {
      console.log("Awaiting notifications...");
    })
    .receive("error", resp => {
      console.log("Could not connect to notifications channel");
    });
    
    notifications.on("invitation_received", ({title, owner}) => {
      window.Materialize.toast(`${owner} has invited you to join ${title}`, 3000, 'blue-toast');
    });
  }
  
  unmount() {
    super.unmount();
    console.log("Unmounting online-view");
  }
}