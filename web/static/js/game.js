import {Socket} from 'phoenix';
import $ from 'jquery';

import Table from './table';
import Card from './card';
import Controls from './components/controls';
import RaiseControl from './components/raise-control';
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
      this.setButtons(channel);
      console.log("joined");
    })
    .receive("error", () => {
      console.log("could not join channel");
    });
    
    const MESSAGES = ["private_room_join", "started_game", "game_started", "update"];
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
  setButtons(channel) {
    let buttons = [$("#join-btn"), $("#leave-btn"), $("#start-btn")];
    let messages = ["add_player", "remove_player", "start_game"];
    let params = [{player: this.userName, room: this.roomTitle}, {player: this.userName, room: this.roomTitle}, {room: this.roomTitle}];
    for (let i = 0; i < buttons.length; i++) {
      buttons[i].click(() => {
        console.log("sending message, channel: ", channel, messages[i]);
        channel.push(messages[i], params[i]);
        buttons[i].slideUp();
      });
    }
  }
  
  setup(payload, channel) {
    console.log("payload: ", payload);
    let data = this.dataFormatter.format(this.addUser(payload));
    data.channel = channel;
    this.table = new Table(data);
    this.controls = new Controls(data);
    this.raiseControl = new RaiseControl(data);
    Card.renderPlayerCards(data.playerHand);
    this.table.init(data);
    this.controls.update(data);
    this.raiseControl.init();
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