import Card from './card';
import Player from './player';

export default class DataFormatter {
  
  constructor(type) {
    this.type = type;
  }
  
  format(data) {
    switch (this.type) {
      case "game":
        // Add a raiseable attribute and whatever else is needed; format seating array
        data.seating = this.formatSeating(data.seating);
        let raiseData = this.extractRaiseData(data);
        data.table = this.extractTableCards(data.table);
        data.players = this.extractPlayers(data.players);
        data.playerHand = this.extractPlayerHand(data);
        data.raiseable = raiseData.raiseable;
        data.min = raiseData.min;
        data.max = raiseData.max;
        return data;
      default:
        console.log("could not format data...", data, this.type);
    }
  }
  
  // Private
  formatSeating(seatingArray) {
    let seating;
    if (seatingArray instanceof Array) {
      seating = new Object();
      seatingArray.forEach((seat) => {
      seating[`${seat.name}`] = seat.position;
      });
    } else {
      seating = seatingArray;
    }
    return seating;
  }
  
  extractRaiseData(data) {
    let raiseData = new Object();
    if (!(data.active) || data.active != data.players[0].name) {
      raiseData.raiseable = false;
    } else {
      let round = data.round[data.user] || 0;
      let toCall = (data.to_call - round);
      let filtered = data.players.filter((pl) => {
      if (pl.name == data.user) {
        return true;
      }
    });
    let chips = filtered[0].chips;
    if (chips > toCall) {
      raiseData.raiseable = true;
      raiseData.min = toCall;
      raiseData.max = chips;
    }
    }
    return raiseData;
  }
  
  extractTableCards(cardsArray) {
    let cards = [];
    cardsArray.forEach((card) => {
      cards.push(new Card(card.rank, card.suit));
    });
    return cards;
  }
  
  extractPlayerHand(data) {
    let player = data.user;
    let players = data.player_hands.map((obj) => {
      return obj.player;
    });
    if (players.includes(player)) {
      let filtered = data.player_hands.filter((obj) => {
        if (obj.player == player) {
          return true;
        }
      });
      let hand = filtered[0].hand;
      let cards = [];
      hand.forEach((card) => {
        cards.push(new Card(card.rank, card.suit));
      });
      return cards;
    }
  }
  
  extractPlayers(playersArray) {
    let players = [];
    playersArray.forEach((player) => {
      players.push(new Player(player.name, player.chips));
    });
    return players;
  }
}