import $ from 'jquery';

import Table from './table';
import Card from './card';
import Player from './player';

export default class TableConcerns {
  constructor() {}
  
  static init(channel, name, initialPlayers) {
    let Materialize = window.Materialize;
    
    let table = new Table();
    table.user = name;
    let earlierPlayersSeen = false;
    
    channel.on("player_seated", ({position, player}) => {
      table.seating[player] = position;
      Table.renderNewPlayer(player, position);
    });
    
    channel.on("game_started", (payload) => {
      payload.players.forEach((player) => {
        table.players.push(new Player(player.name, player.chips));
      });
      table.addActiveClass(payload.active);
    });
    
    channel.on("pot_update", ({amount}) => {
      table.pot += amount;
      $("#pot").text(table.pot);
    });
    
    channel.on("flop_dealt", ({cards}) => {
      if (table) {
        cards.forEach((card) => {
          let c = new Card(card.rank, card.suit);
          table.cards.push(c);
        });
        table.renderCards();
      }
    });
    
    channel.on("card_dealt", ({card}) => {
      card.forEach((c) => {
        let newCard = new Card(c.rank, c.suit);
        table.cards.push(newCard);
      });
      table.renderCards();
    });
    
    channel.on("game_finished", (payload) => {
      table.pot = 0;
      table.cards = [];
      table.removeCards();
      table.players = [];
    });
    
    channel.on("advance", ({player}) => {
      table.removeActiveClass();
      table.addActiveClass(player);
      let p = null;
      table.players.forEach((pl) => {
        if (pl.name === player) {
          p = pl;
        } 
      });
      if (player === table.user) {
        // Handles the situation before the game_started event completes
        // and the table.players array is empty. This is just a temporary hack
        if (p) {
          p.renderPlayerControls(table.callAmount, table.paidInRound[player]);
        } else {
         Player.renderPlayerControls(table.callAmount, table.paidInRound[player]); 
        }
      } else {
        Player.hidePlayerControls();
      }
      
      if (player == table.user) {
        let amountToCall = table.callAmount - table.paidInRound[player];
        if (amountToCall > 0) {
          Materialize.toast(`${amountToCall} to call.`, 2000, 'rounded'); 
        }
      }
    });
    
    channel.on("call_amount_update", ({amount}) => {
      table.callAmount = amount;
    });
    
    channel.on("paid_in_round_update", (payload) => {
      table.paidInRound = payload;
    });
    
    channel.on("player_joined", payload => {
      if (!earlierPlayersSeen) {
        if (payload.seating.length > 0) {
          payload.seating.forEach((seat) => {
            table.seating[seat.name] = seat.position;
          });
        } 
        Table.renderPlayers(table.seating);
        earlierPlayersSeen = true; 
      }
    });
    
    channel.on("update_seating", payload => {
      table.clearPlayers();
      table.seating = payload;
      Table.renderPlayers(table.seating);
    });
    
    channel.on("player_got_up", payload => {
      table.removePlayerEmblem(payload.player);
      // markedToFold deprecated...
      table.markedToFold.push(payload.player);
      
      if (table.user == payload.player) {
        channel.leave();
      }
      
      let messages = document.getElementById("messages");
      for (var i = 0; i < messages.children.length; i++) {
        if(messages.children[i].innerText == payload.player) {
          messages.removeChild(messages.children[i]);
        }
      }
    });
    
    channel.on("player_left", payload => {
      let names = table.players.map(player => {
        player.name;
      });
      
      let index = names.indexOf(payload.body.name);
      if (!index === -1) {
        let p = table.players.splice(index, 1);
        table.markedToFold.push(p[0]);
      }
      
      delete table.seating[payload.body.name];
      
      let messages = document.getElementById("messages");
      for (var i = 0; i < messages.children.length; i++) {
        if(messages.children[i].innerText == payload.body.name) {
          messages.removeChild(messages.children[i]);
        }
      }
    });
    
  }
}