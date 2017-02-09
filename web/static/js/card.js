import {CARDS} from './card_codes';

export default class Card {
  constructor(rank, suit) {
    this.rank = rank;
    this.suit = suit;
    this.rendered = false;
  }
  
  render() {
    let path = CARDS[this.suit.toUpperCase()][this.rank];
    let image = document.createElement('img');
    if (window.basePath) {
      image.src = window.basePath + path;
    } else {
      image.src = "../" + path; 
    }
    if (this.suit == 'hearts' || this.suit == 'diamonds') {
      image.setAttribute('id', 'deck-red-suit');
    } else {
      image.setAttribute('id', 'deck-black-suit');
    }
    return image;
  }
  
  static renderPlayerCards(cards) {
    let cardArray = [];
    cards.forEach((card) => {
      let path = CARDS[card.suit.toUpperCase()][card.rank];
      let image = document.createElement('img');
      if (window.basePath) {
        image.src = window.basePath + path;
      } else {
        image.src = "../" + path;
      }
      // Set red font if suit is hearts or diamonds
      if (card.suit === 'hearts' || card.suit === 'diamonds') {
        image.setAttribute('id', 'red-suit'); 
      } else {
        image.setAttribute('id', 'black-suit');
      }
      image.setAttribute('class', 'player-cards');
      cardArray.push(image);
    });
    return cardArray;
  }
}