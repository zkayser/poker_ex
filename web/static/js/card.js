import {CARDS} from './card_codes'

export default class Card {
  constructor(rank, suit) {
    this.rank = rank;
    this.suit = suit;
  }
  
  render() {
    // implement later
  }
  
  static renderPlayerCards(cards) {
    let cardArray = [];
    cards.forEach((card) => {
      let text = CARDS[card.suit.toUpperCase()][card.rank];
      let paragraph = document.createElement('p');
      paragraph.innerText = text;
      // Set red font if suit is hearts or diamonds
      if (card.suit === 'hearts' || card.suit === 'diamonds') {
        paragraph.setAttribute('id', 'red-suit'); 
      } else {
        paragraph.setAttribute('id', 'black-suit');
      }
      paragraph.setAttribute('class', 'player-cards');
      cardArray.push(paragraph);
    });
    return cardArray;
  }
}