import $ from 'jquery';

export default class Table {
	constructor() {
		this.pot = 0;
		this.callAmount = 0;
		this.cards = [];
		this.players = [];
		this.seating = new Object();
		this.user = undefined;
		this.markedToFold = [];
	}
	
	renderTable() {
		// TODO
	}
	
	renderCards() {
		let tableCards = $(".table-cards");
		this.cards.forEach((card) => {
			if (!card.rendered) {
				let markup = card.render();
				tableCards.append($(markup));
				card.rendered = true;
			}
		});
	}
	
	removeCards() {
		let tableCards = document.querySelector(".table-cards");
		tableCards.innerHTML = "";
	}
	
	addPlayer(player) {
		this.players.push(player);
	}
	
}
