export default class Table {
	constructor() {
		this.pot = 0;
		this.cards = [];
	}
	
	renderTable() {
		// TODO
	}
	
	// Utility function to render a player's emblem on screen;
	// The second argument is a boolean used to distinguish if
	// the emblem being rendered is the player him/herself or
	// other players
	static place(name, me) {
		let outerDiv = document.createElement('div');
		outerDiv.setAttribute('id', 'me');
		let row = document.createElement('div');
		row.setAttribute('class', 'row');
		let col = document.createElement('div');
		col.setAttribute('class', 'col s12');
		let emblem = document.createElement('p');
		emblem.setAttribute('id', 'player-emblem');
		emblem.innerHTML = name.slice(0, 1);
		col.appendChild(emblem);
		row.appendChild(col);
		outerDiv.appendChild(row);
		return outerDiv;
	}
}
