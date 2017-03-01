import $ from 'jquery';
import Card from '../card';

export default class WinningHandDisplay {
  constructor(payload) {
     this.cards = [];
     payload.cards.forEach((card) => {
       this.cards.push(new Card(card.rank, card.suit));
     });
     this.winner = payload.winner;
     this.type = payload.type;
     this.show();
  }
  
  show() {
    $("#winning-hand-row").css("display", "inherit");
    this.cards.forEach((card) => {
      let markup = card.imageMarkup("winning-hand");
      $("#winning-hand-images").append(markup);
    });
    $("#winner-span").text(this.winner);
    $("#winning-hand-type").text(this.type);
    $("#winning-hand-panel").addClass("scale-in");
    setTimeout(() => {
      $("#winning-hand-panel").removeClass("scale-in");
      $("#winning-hand-images").empty();
      $("#winning-hand-type").text('');
      $("#winner-span").text('');
    }, 5000);
  }
}