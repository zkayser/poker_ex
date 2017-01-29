import $ from 'jquery';
import Player from '../player';
import Card from '../card';
import MessageBox from '../message-box';

export default class PlayerMessages {
  constructor() {
    this.player = undefined;
  }
  
  static init(channel, name) {
    $(".raise-btn").click(() => {
      let raiseAmount = document.getElementById("raise-amount");
      let amount = raiseAmount.value;
      raiseAmount.value = "";
      if (amount.length > 0) {
        Player.raise(name, amount, channel);
      }
    });
    
    $(".call-btn").click(() => {
      Player.call(name, channel);
    });
    
    $(".check-btn").click(() => {
      Player.check(name, channel);
    });
    
    $(".fold-btn").click(() => {
      Player.fold(name, channel);
    });
    
    channel.on("room_joined", ({player}) => {
      console.log("got room_joined with player: ", player);
      
      let p = new Player(player.name, player.chips);
      if (p.name == name) {
        this.player = p;
        // p.renderPlayerInfo();
      }
      let msg = Player.addToList(player);
      MessageBox.appendAndScroll(msg);
      
    });
    
    /*
    channel.on("player_joined", ({player}) => {
      let p = new Player(player.name, player.chips);
      if (p.name == name) {
        this.player = p;
        p.renderPlayerInfo();
      }
      let msg = Player.addToList(player);
      MessageBox.appendAndScroll(msg);
    }); */
    
    channel.on("chip_update", (payload) => {
      console.log("got chip_update with payload: ", payload);

      if (name == payload.player && this.player == undefined) {
        if (this.player == undefined) {
         this.player = new Player(payload.player, payload.chips); 
        }
        this.player.chips = payload.chips;
        this.player.renderPlayerInfo();
      } else if (name == payload.player) {
        this.player.chips = payload.chips;
        this.player.renderPlayerInfo();
      } 
    });
    
    channel.on("game_started", (payload) => {
      $("#offscreen-left").addClass("slide-onscreen-right");
      let cardHolder = document.querySelector(".card-holder");
      cardHolder.style.visibility = "visible";
      payload.hands.forEach((obj) => {
        if (obj.player == name) {
          let playerCards = document.getElementById("player-cards");
          let children = playerCards.childNodes;
          let cards = Card.renderPlayerCards(obj.hand);

          for (let i = children.length - 1; i >= 0; i--) {
              playerCards.removeChild(children[i]);  
            }
          cards.forEach((card) => {
            playerCards.appendChild(card);
          });
        }
      });
    });
  }
}