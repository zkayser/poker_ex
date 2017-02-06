import {Socket} from 'phoenix';

export default class Online {
  
  static init() {
    let socket = new Socket('/socket', {params: {
     token: window.playerToken
    }});
    
    socket.connect();
    
    let channel = socket.channel("online:lobby");
    
    channel.join()
    .receive("ok", resp => {
      console.log("joined online:lobby channel");
    })
    .receive("error", resp => {
      console.log("something went wrong connecting");
    });
  }
}