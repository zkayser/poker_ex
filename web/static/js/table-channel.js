import Table from './table';
import Card from './card';

export default class TableChannel {
  constructor() {}
  
  static init(channel) {
    let table = undefined;
    let pot = 0;
    
    channel.on("game_started", (payload) => {
      table = new Table();
      table.pot = pot;
      console.log(table);
    });
    
    channel.on("pot_update", ({amount}) => {
      pot += amount;
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
  }
  
}