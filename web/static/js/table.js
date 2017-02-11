import $ from 'jquery';

import {SEAT_MAPPING} from "./seat-mapping";
import Player from './player';
import Card from './card';

export default class Table {
	constructor(data) {
		this.pot = data.pot || 0;
		this.callAmount = data.callAmount || 0;
		if (data.table.length > 0) {
			this.cards = [];
			data.table.forEach((card) => {
				this.cards.push(new Card(card.rank, card.suit));
			});
		} else {
			this.cards = [];
		}
		this.type = data.type || "public";
		if (data.players.length > 0) {
			console.log("data.players.length > 0; if statement called in constructor");
			this.players = [];
			data.players.forEach((player) => {
				this.players.push(new Player(player.name, player.chips));
			});
		} else {
			this.players = [];
		}
		this.seating = data.seating || new Object();
		this.user = data.user || undefined;
		this.markedToFold = data.markedToFold || [];
		this.paidInRound = data.round || undefined;
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
	
	static renderCards(cards) {
		let tableCards = $(".table-cards");
		cards.forEach((card) => {
			let markup = card.render();
			tableCards.append($(markup));
		});
	}
	
	removeCards() {
		let tableCards = document.querySelector(".table-cards");
		tableCards.innerHTML = "";
	}
	
	addPlayer(player) {
		this.players.push(player);
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
	
	static renderNewPlayer(player, position) {
		let cardTable = document.querySelector(".card-table");
		let fragment = document.createDocumentFragment();
		let seatClass = SEAT_MAPPING[position];
		let emblem = Player.emblem(player);
		let container = document.createElement('a');
		container.setAttribute('class', seatClass);
		container.appendChild(emblem);
		fragment.appendChild(container);
		cardTable.appendChild(fragment);
	}
	
	removePlayerEmblem(player) {
		let cardTable = document.querySelector(".card-table");
		let position = this.seating[player];
		let seatClass = SEAT_MAPPING[position];
		let node = document.getElementsByClassName(seatClass)[0];
		cardTable.removeChild(node);
	}
	
	static addActiveClass(player, seating) {
		if (!(player == null)) {
			let position = seating[player];
			let element = $(`.${SEAT_MAPPING[position]}`);
			element.addClass("active-player");	
		}
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