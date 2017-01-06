export default class Table {
	constructor() {
		this.pot = 0;
		this.callAmount = 0;
		this.cards = [];
	}
	
	renderTable() {
		// TODO
	}
	
	renderCards() {
		let tableCards = document.querySelector(".table-cards");
		this.cards.forEach((card) => {
			let markup = card.render();
			tableCards.appendChild(markup);
		});
	}
	
	removeCards() {
		let tableCards = document.querySelector(".table-cards");
		tableCards.innerHTML = "";
	}
	
}
