import $ from 'jquery';

import {SEAT_MAPPING} from "./seat-mapping";
import Player from './player';

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
		console.log(cardTable);
	}
	
	addActiveClass(player) {
		console.log("addActiveClass", player);
		let position = this.seating[player];
		console.log("addActiveClass", position);
		let element = $(`.${SEAT_MAPPING[position]}`);
		element.addClass("active-player");
		console.log("element", element);
	}
	
	removeActiveClass() {
		$(".active-player").removeClass("active-player");
	}
	
	markupFor(position) {
		return SEAT_MAPPING[position];
	}
}