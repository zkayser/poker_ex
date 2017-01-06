// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix";
import Player from "./player";
import TableConcerns from "./table-concerns";
import Card from "./card";

let Connection = {
  me: null,
  players: [],
  messages: document.querySelector("#messages"),
  cardTable: document.querySelector(".card-table"),
  cardHolder: document.querySelector(".card-holder"),
  playerCards: document.getElementById("player-cards"),
  playerInfo: document.getElementById("player-info"),
  raiseButton: document.querySelector(".raise-btn"),
  checkButton: document.querySelector(".check-btn"),
  callButton: document.querySelector(".call-btn"),
  foldButton: document.querySelector(".fold-btn"),
  raiseAmount: document.getElementById("raise-amount"),
  
  init(name){
    let socket = new Socket('/socket', {params: {name: name}});
    socket.connect();
    let channel = socket.channel("players:lobby", {});
    TableConcerns.init(channel);
    this.me = name;
    this.player = undefined;
    
    this.raiseButton.addEventListener('click', () => {
      let amount = this.raiseAmount.value;
      this.raiseAmount.value = "";
      if (amount.length > 0) {
        Player.raise(this.me, amount, channel);
      }
    }),
    
    this.callButton.addEventListener('click', () => {
      Player.call(this.player, channel);
    }),
    
    this.foldButton.addEventListener('click', () => {
      Player.fold(this.player, channel);
    }),
    
    this.checkButton.addEventListener('click', () => {
      Player.check(this.player, channel);
    }),
    
    channel.join()
    .receive("ok", initialPlayers => {
      console.log(initialPlayers);
      console.log("Joined channel");
      if(!(initialPlayers.players === null)) {
        this.players = initialPlayers.players;
        this.players.forEach(player => {
          let pl = new Player(player.name, player.chips);
          let msg = Player.addToList(pl);
          this.appendAndScroll(msg);
        });
      }
      channel.push("new_msg", {body: this.me});
    });
    
    channel.on("player_joined", payload => {
      let player = new Player(payload.player.name, payload.player.chips);
      if (player.name == this.me) {
        this.player = player;
        player.renderPlayerInfo();
      }
      let msg = Player.addToList(player);
      this.appendAndScroll(msg);
      this.players.push(player);
    });
    
    channel.on("new_msg", payload => {
      Materialize.toast(`${payload.body} joined the lobby`, 3000, 'rounded')
    });
    
    channel.on("chip_update", (payload) => {
      if (this.me == payload.player) {
        this.player.chips = payload.chips;
        this.player.renderPlayerInfo();
      } 
    });
    
    channel.on("advance", payload => {
      if (payload.player == this.me) {
        Player.renderPlayerControls();
      } else {
        Player.hidePlayerControls();
      }
    });
    
    channel.on("flop_dealt", payload => {
      console.log("flop_dealt", payload);
      let cards = [];
      payload.cards.forEach((card) => {
        let c = new Card(card.rank, card.suit);
        cards.push(c);
      });
    });
    
    channel.on("card_dealt", payload => {
      console.log("card_dealt", payload);
    });
    
    channel.on("game_started", payload => {
      // payload.hands is an array of objects
      // with a hand -- which is an array of card
      // objects -- and a player string
      this.cardHolder.style.visibility = "visible";
      payload.hands.forEach((obj) => {
        if (obj.player == this.me) {
          let children = this.playerCards.childNodes;
          let cards = Card.renderPlayerCards(obj.hand);
          cards.forEach((card) => {
            if (children.length > 2) {
              this.playerCards.replaceChild(card, children[1]);
            } else {
              this.playerCards.appendChild(card);
            }
          });
        }
      });
    });
    
    channel.on("game_finished", payload => {
      console.log("game_finished", payload);
    });
    
    channel.on("winner_message", payload => {
      console.log("winner_message", payload.message);
    });
    
    channel.on("player_left", payload => {
      let names = this.players.map(player => {
        player.name;
      });
      let index = names.indexOf(payload.body.name);
      this.players.splice(index, 1);
      Materialize.toast(`${payload.body.name} left`, 3000, 'rounded')
      for (var i = 0; i < this.messages.children.length; i++) {
        if(this.messages.children[i].innerText == payload.body.name) {
          this.messages.removeChild(this.messages.children[i]);
        }
      }
    });
  },
  
  appendAndScroll(element) {
    this.messages.append(element);
    this.messages.scrollTop = 0;
  }
};

export default Connection;
