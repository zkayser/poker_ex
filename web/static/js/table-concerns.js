import $ from 'jquery';

import Table from './table';
import Card from './card';
import Player from './player';

export default class TableConcerns {
  constructor(table) {
    this.table = table;
  }
  
  init(channel) {
    console.log("tableConcern instance initiated");
    this.table.renderCards();
    this.table.renderPlayers();
    
    channel.on("player_seated", ({position, player}) => {
      this.table.seating[player] = position;
      this.table.renderNewPlayer(player, position);
    });
    
    channel.on("game_started", (payload) => {
      payload.players.forEach((player) => {
        this.table.players.push(new Player(player.name, player.chips));
      });
      this.table.addActiveClass(payload.active);
    });
    
    channel.on("pot_update", ({amount}) => {
      this.table.pot += amount;
      $("#pot").text(this.table.pot);
    });
    
    channel.on("flop_dealt", ({cards}) => {
      if (this.table) {
        cards.forEach((card) => {
          let c = new Card(card.rank, card.suit);
          this.table.cards.push(c);
        });
        this.table.renderCards();
      }
    });
    
    channel.on("card_dealt", ({card}) => {
      card.forEach((c) => {
        let newCard = new Card(c.rank, c.suit);
        this.table.cards.push(newCard);
      });
      this.table.renderCards();
    });
    
    channel.on("game_finished", (payload) => {
      this.table.pot = 0;
      this.table.cards = [];
      this.table.removeCards();
      this.table.players = [];
    });
    
    channel.on("clear_table", (payload) => {
      if (payload.player == this.table.user) {
        this.table.removeCards();
        this.table = null;
      }
    });
    
    channel.on("advance", ({player}) => {
      this.table.removeActiveClass();
      this.table.addActiveClass(player);
      let p = null;
      this.table.players.forEach((pl) => {
        if (pl.name === player) {
          p = pl;
        } 
      });
      if (player === this.table.user) {
        // Handles the situation before the game_started event completes
        // and the table.players array is empty. This is just a temporary hack
        if (p) {
          p.renderPlayerControls(this.table.callAmount, this.table.paidInRound[player] || 0);
        } else {
         Player.renderPlayerControls(this.table.callAmount, this.table.paidInRound[player]); 
        }
      } else {
        Player.hidePlayerControls();
      }
      
      if (player == this.table.user) {
        let amountToCall = this.table.callAmount - this.table.paidInRound[player];
        if (amountToCall > 0) {
          window.Materialize.toast(`${amountToCall} to call.`, 2000); 
        }
      }
    });
    
    channel.on("call_amount_update", ({amount}) => {
      this.table.callAmount = amount;
    });
    
    channel.on("paid_in_round_update", (payload) => {
      this.table.paidInRound = payload;
    });
    
    channel.on("player_joined", payload => {
      console.log("player_joined called with payload: ", payload);
        if (payload.seating.length > 0) {
          payload.seating.forEach((seat) => {
            this.table.seating[seat.name] = seat.position;
          });
        } 
        Table.renderPlayers(this.table.seating);
    });
    
    channel.on("update_seating", payload => {
      this.table.clearPlayers();
      this.table.seating = payload;
      Table.renderPlayers(this.table.seating);
    });
    
    channel.on("player_got_up", payload => {
      this.table.removePlayerEmblem(payload.player);
      // markedToFold deprecated...
      this.table.markedToFold.push(payload.player);
      
      if (this.table.user == payload.player) {
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
      let names = this.table.players.map(player => {
        player.name;
      });
      
      let index = names.indexOf(payload.body.name);
      if (!index === -1) {
        let p = this.table.players.splice(index, 1);
        this.table.markedToFold.push(p[0]);
      }
      
      delete this.table.seating[payload.body.name];
      
      let messages = document.getElementById("messages");
      for (var i = 0; i < messages.children.length; i++) {
        if(messages.children[i].innerText == payload.body.name) {
          messages.removeChild(messages.children[i]);
        }
      }
    });
  }
  
  static init(channel, name, initialPlayers, tableData) {
    let Materialize = window.Materialize;
    
    let table = new Table(tableData);
    console.log("new table initiated from TableConcerns class with table and tableData: ", table, tableData);
    table.user = name;
    let earlierPlayersSeen = false;
    // Initializes the table cards for private
    // visitors returning to a table
    if (table.type == "private") {
      table.renderCards();
    }
    
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
    
    // untested; keep an eye on any issues;
    channel.on("clear_ui", (payload) => {
      table.pot = 0;
      table.cards = [];
      table.removeCards();
      table.players = [];
      
    });
    
    channel.on("clear_table", (payload) => {
      if (payload.player == table.user) {
        table.removeCards();
        table = null;
      }
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
          p.renderPlayerControls(table.callAmount, table.paidInRound[player] || 0);
        } else {
         Player.renderPlayerControls(table.callAmount, table.paidInRound[player]); 
        }
      } else {
        Player.hidePlayerControls();
      }
      
      if (player == table.user) {
        let amountToCall = table.callAmount - table.paidInRound[player];
        if (amountToCall > 0) {
          Materialize.toast(`${amountToCall} to call.`, 2000); 
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