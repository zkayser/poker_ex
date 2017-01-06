import Table from './table';
import Card from './card';

export default class TableConcerns {
  constructor() {}
  
  static init(channel) {
    let table = new Table();
    
    channel.on("game_started", (payload) => {
      console.log(table);
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
      table.removeCards();
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
    });
    
    channel.on("call_amount_update", ({amount}) => {
      table.callAmount = amount;
      console.log("table object: ", table)
      console.log("call_amount_update", amount);
    });
  }
  
}