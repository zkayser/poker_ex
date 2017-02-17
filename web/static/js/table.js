import $ from 'jquery';

import {SEAT_MAPPING} from "./seat-mapping";
import Player from './player';
import Card from './card';

export default class Table {
	constructor(data) {
		this.pot = data.pot || 0;
		this.to_call = data.to_call || 0;
		if (data.table.length > 0) {
			this.cards = data.table;
		} else {
			this.cards = [];
		}
		this.type = data.type || "public";
		if (data.players.length > 0) {
			this.players = data.players;
		} else {
			this.players = [];
		}
		this.seating = data.seating || new Object();
		this.user = data.user || undefined;
		this.markedToFold = data.markedToFold || [];
		this.round = data.round || undefined;
	}
	
	init(state) {
		this.renderPlayers();
		this.addActiveClass(state.active);
		this.renderCards();
		this.updatePot(state.pot);
	}
	
	update(state) {
		this.removeActiveClass();
		this.updateCards(state.table);
		this.players = state.players;
		this.seating = state.seating;
		this.to_call = state.to_call;
		this.cards = state.table;
		this.updatePot(state.pot);
		this.addActiveClass(state.active);
	}
	
	clear() {
		this.removeCards();
		this.cards = [];
		this.pot = 0;
	}
	
	renderCards() {
		let tableCards = $(".table-cards");
		this.cards.forEach((card) => {
			if (!card.rendered) {
				let markup = card.render();
				tableCards.append($(markup));
			}
		});
	}
	
	updateCards(newCards) {
		if (this.cards.length == 0) {
			this.cards = newCards;
			this.renderCards();	
		} else {
				for (let i = 0; i < newCards.length; i++) {
				if (this.cards[i] && this.cards[i].rank == newCards[i].rank && this.cards[i].suit == newCards[i].suit) {
					this.cards[i];
				} else {
					this.cards.push(newCards[i]);
					let card = newCards[i];
					let markup = card.render();
					$(".table-cards").append($(markup));
				}
			}		
		}
	}

	removeCards() {
		let tableCards = document.querySelector(".table-cards");
		tableCards.innerHTML = "";
	}
	
	updatePot(pot) {
		$("#pot").text(pot);
	}
	
	renderPlayers() {
		console.log("Rendering players...");
		let keys = Object.keys(this.seating);
		keys.forEach((key) => {
			let cardTable = document.querySelector(".card-table");
			let fragment = document.createDocumentFragment();
			let position = SEAT_MAPPING[this.seating[key]];
			let player = Player.emblem(key);
			let container = document.createElement('a');
			container.setAttribute('class', position);
			container.appendChild(player);
			fragment.appendChild(container);
			cardTable.appendChild(fragment);
		});
	}
	
	static renderPlayers(seating) {
		let keys = Object.keys(seating);
		keys.forEach((key) => {
			let cardTable = document.querySelector(".card-table");
			let fragment = document.createDocumentFragment();
			let position = SEAT_MAPPING[seating[key]];
			let player = Player.emblem(key);
			let container = document.createElement('a');
			container.setAttribute('class', position);
			container.appendChild(player);
			fragment.appendChild(container);
			cardTable.appendChild(fragment);
		});
	}
	
	clearPlayers() {
		let seatClasses = Object.values(SEAT_MAPPING);
		seatClasses.forEach((klass) => {
			$(`.${klass}`).remove();
		});
	}
	
	removePlayerEmblem(player) {
		let cardTable = document.querySelector(".card-table");
		let position = this.seating[player];
		let seatClass = SEAT_MAPPING[position];
		let node = document.getElementsByClassName(seatClass)[0];
		cardTable.removeChild(node);
	}
	
	addActiveClass(player) {
		let position = this.seating[player];
		let element = $(`.${SEAT_MAPPING[position]}`);
		element.addClass("active-player");
	}
	
	removeActiveClass() {
		$(".active-player").removeClass("active-player");
	}
	
	markupFor(position) {
		return SEAT_MAPPING[position];
	}
}