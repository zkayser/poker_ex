import {Socket} from 'phoenix';
import $ from 'jquery';

import Table from './table';
import Card from './card';
import Controls from './components/controls';
import RaiseControl from './components/raise-control';
import PlayerToolbar from './components/player-toolbar';
import ChatComponent from './components/chat-component';
import SpinnerAnimation from './animations/spinner-animations';
import DataFormatter from './data-formatter';
import Dispatcher from './messages/dispatcher';

export default class Game {
  
  constructor(userName, roomTitle) {
    this.userName = userName;
    this.roomTitle = roomTitle;
    this.dataFormatter = new DataFormatter("game");
  }
  
  init() {
    SpinnerAnimation.onJoinPrivateRoom();
    let socket = new Socket('/socket', {params: 
      {token: window.playerToken},
      logger: (kind, msg, data) => {console.log(`${kind}:${msg}`, data)}
      });
      
    socket.connect();
    let channel = socket.channel(`players:${this.roomTitle}`, {type: "private"});
    
    channel.join()
    .receive("ok", () => {
      console.log("joined");
    })
    .receive("error", () => {
      console.log("could not join channel");
    });
    
    this.playerToolbar = new PlayerToolbar(this.userName, this.roomTitle, channel);
    this.chatComponent = new ChatComponent(this.userName, channel);
    this.chatComponent.init();
    
    const MESSAGES = [
      "private_room_join",
      "started_game", 
      "game_started",
      "update",
      "add_player_success",
      "player_seated",
      "game_finished",
      "winner_message",
      "new_message"];
    MESSAGES.forEach((message) => {
      channel.on(message, (payload) => {
        Dispatcher.dispatch(message, payload, {
          game: this,
          channel: channel
        });
      });
    });
  }
  
  // private
  setup(payload, channel) {
    delete this.chatComponent;
    let data = this.dataFormatter.format(this.addUser(payload));
    data.channel = channel;
    this.playerToolbar.update(data);
    this.table = new Table(data);
    this.controls = new Controls(data);
    this.raiseControl = new RaiseControl(data);
    this.chatComponent = new ChatComponent(this.userName, channel);
    Card.renderPlayerCards(data.playerHand);
    this.table.init(data);
    this.controls.update(data);
    this.raiseControl.init();
    this.chatComponent.init();
  }
  
  update(payload, channel) {
    let data = this.dataFormatter.format(this.addUser(payload));
    data.channel = channel;
    this.table.update(data);
    this.controls.update(data);
    this.raiseControl.update(data);
  }
  
  addUser(data) {
    data.user = this.userName;
    return data;
  }
}