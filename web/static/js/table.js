import $ from 'jquery';

import {SEAT_MAPPING} from "./seat-mapping";
import Player from './player';

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
		this.chipRoll = data.chip_roll || {};
		this.seating = data.seating || new Object();
		this.user = data.user || undefined;
		this.markedToFold = data.markedToFold || [];
		this.round = data.round || undefined;
		this.initialRender();
	}
	
	init(state) {
		this.removePlayerEmblems(state.seating);
		this.selectiveRender(state.seating);
		this.addActiveClass(state.active);
		this.renderCards();
		this.updatePot(state.pot);
	}
	
	update(state) {
		this.removeActiveClass();
		this.updateCards(state.table);
		if (["pre_flop", "idle", "between_rounds"].includes(state.state)) {
			this.removeCards();
		}
		this.players = state.players;
		this.removeExcessEmblems(Object.keys(this.seating).length);
		if (!(this.isEqual(this.seating, state.seating)) || Object.keys(this.seating).length !== Object.keys(state.seating).length) {
			let newLength = Object.keys(this.seating).length;
			this.removeExcessEmblems(newLength);
			this.removePlayerEmblems(state.seating);
			this.selectiveRender(state.seating);
			this.seating = state.seating;
			this.initialRender();
		}
		this.seating = state.seating;
		this.to_call = state.to_call;
		this.cards = state.table;
		this.updatePot(state.pot);
		this.updatePlayerChipsDisplay(state.chip_roll);
		this.addActiveClass(state.active);
	}
	
	clear(data) {
		console.log('Clearing with data: ', data);
		//this.removePlayerEmblems(data.seating);
		this.removeExcessEmblems(Object.keys(this.seating).length);
		this.removeCards();
		this.cards = [];
		this.pot = 0;
	}
	
	clearWithData(data) {
		this.removeExcessEmblems(Object.keys(this.seating).length);
		this.removeCards();
		this.cards = [];
		this.updatePot(data.pot);
		this.seating = data.seating;
	}
	
	clearPlayers() {
		console.log('Calling clearPlayers...');
		let seatClasses = Object.values(SEAT_MAPPING);
		seatClasses.forEach((klass) => {
			$(`.${klass}`).remove();
		});
	}
	
	renderCards() {
		let tableCards = $(".table-cards");
		for (let i = 0; i < this.cards.length; i++) {
			console.log('i: ', i);
			let card = this.cards[i];
			let markup = card.renderWithAnimation(i);
			tableCards.append($(markup));
		}
		/*
		this.cards.forEach((card) => {
			if (!card.rendered) {
				let markup = card.render();
				tableCards.append($(markup));
			}
		});*/
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
					let markup = card.renderWithAnimation(i);
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
	
	initialRender() {
		Object.keys(this.seating).forEach((player) => {
			let position = this.seating[player];
			let klass = SEAT_MAPPING[position];
			$(".card-table").append(this.playerEmblemMarkup(klass, player));
			if ($(`.${klass}`).length > 1) {
				$(`.${klass}`).first().remove();
			}
		});
	}
	
	selectiveRender(newSeating) {
		let renderTargets = [];
		Object.keys(this.seating).forEach((player) => {
			if (Object.keys(newSeating).includes(player) && this.seating[player] !== newSeating[player]) {
				let obj = {name: player, position: newSeating[player]};
				renderTargets.push(obj);
			}
		});
		renderTargets.forEach((target) => {
			let targetClass = SEAT_MAPPING[target.position];
			let markup = this.playerEmblemMarkup(targetClass, target.name);
			if ($(`.${targetClass}`).length > 0) {
				$(`.${targetClass}`).replaceWith(markup);
			} else {
				$('.card-table').append(markup);	
			}
		});
	}
	
	removePlayerEmblem(player) {
		let cardTable = document.querySelector(".card-table");
		let position = this.seating[player];
		let seatClass = SEAT_MAPPING[position];
		$(`.${seatClass}`).remove();
		let node = document.getElementsByClassName(seatClass)[0];
		cardTable.removeChild(node);
	}
	
	removePlayerEmblems(newSeating) {
		let removeTargets = [];
		Object.keys(this.seating).forEach((player) => {
			if (!(Object.keys(newSeating).includes(player))) {
				removeTargets.push(player);
			} else if (this.seating[player] !== newSeating[player]) {
				removeTargets.push(player);
			}
		});
		removeTargets.forEach((target) => {
			let position = this.seating[target];
			let seatClass = SEAT_MAPPING[position];
			$(`.${seatClass}`).remove();
		});
	}
	
	addActiveClass(player) {
		let position = this.seating[player];
		let element = $(`.${SEAT_MAPPING[position]}`);
		element.addClass("active-player");
	}
	
	removeActiveClass() {
		$(".active-player").removeClass("active-player");
	}
	
	removeExcessEmblems(length) {
		console.log('removeExcessEmblems from length: ', length);
		let position = length;
		while (position <= Object.keys(SEAT_MAPPING).length) {
			let el = $(`.${SEAT_MAPPING[position]}`);
			if (el.length > 0 ) {
				console.log('removing excess emblems');
				el.remove();
			}
			position++;
		}
	}
	
	isEqual(obj1, obj2) {
		let result;
		result = Object.keys(obj1).every((key) => {
			return obj1[key] == obj2[key];
		});
		return result;
	}
	
	markupFor(position) {
		return SEAT_MAPPING[position];
	}
	
	playerEmblemMarkup(klass, name) {
		return $(`<a class="${klass}">
								<div class="center-align">
									<span>${name.charAt(0)}</span><br/>
									<span id="${name}-chip-display">${this.chipRoll[name] || '_'}</span>
								</div>
							</a>`);
	}
	
	updatePlayerChipsDisplay(chip_roll) {
		this.players.forEach((player) => {
			let element = $(`#${player.name}-chip-display`);
			if (element.text() != chip_roll[player.name]) {
				element.text(chip_roll[player.name]);
			}
		});
	}
}