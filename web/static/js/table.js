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
	
	init() {
		
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
	
	renderNewPlayer(player, position) {
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
	
	static extractTableData(data) {
		let tableData = new Object();
		tableData.seating = this.formatSeating(data.seating);
		tableData.pot = data.pot;
		tableData.callAmount = data.to_call || 0;
		tableData.table = data.table;
		tableData.type = data.type;
		tableData.players = data.players;
		tableData.user = data.user;
		tableData.paidInRound = data.round;
		return tableData;
	}
	
	static formatSeating(seatingArray) {
    let seating = new Object();
    seatingArray.forEach((seat) => {
      seating[`${seat.name}`] = seat.position;
    });
    return seating;
  }
}