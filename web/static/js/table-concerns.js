import Table from './table';
import Card from './card';

export default class TableConcerns {
  constructor() {}
  
  static init(channel, name) {
    
    let table = new Table();
    table.user = name;
    let earlierPlayersSeen = false;
    
    channel.on("player_seated", ({position, player}) => {
      table.seating[player] = position;
      Table.renderNewPlayer(player, position);
    });
    
    channel.on("game_started", (payload) => {
      Object.keys(table.seating).forEach((key) => {
        table.players.push(key);
      });
      console.log(payload);
      table.addActiveClass(payload.active);
    });
    
    channel.on("pot_update", ({amount}) => {
      table.pot += amount;
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
    });
    
    channel.on("call_amount_update", ({amount}) => {
      table.callAmount = amount;
      console.log("table object: ", table);
      console.log("call_amount_update", amount);
    });
    
    
    channel.on("player_joined", payload => {
      if (!earlierPlayersSeen) {
        if (payload.seating.length > 0) {
          payload.seating.forEach((seat) => {
            table.seating[seat.name] = seat.position;
          });
        } 
        /*
        if (!Object.keys(table.seating).includes(name)) {
          table.seating[name] = payload.seating.length; 
        } */
        Table.renderPlayers(table.seating);
        earlierPlayersSeen = true; 
      } else {
        console.log("players have been seen");
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