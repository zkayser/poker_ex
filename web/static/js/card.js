import $ from 'jquery';
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
    let imgRight = $(".card-image-right");
    let imgLeft = $(".card-image-left");
    
    let pathLeft = CARDS[cards[0].suit.toUpperCase()][cards[0].rank];
    let pathRight = CARDS[cards[1].suit.toUpperCase()][cards[1].rank];
    
    let base = window.basePath || 'https://phoenix-experiment-zkayser.c9users.io/';
    imgLeft.attr('src', base + pathLeft);
    imgRight.attr('src', base + pathRight);
  }
}