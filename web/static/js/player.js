export default class Player {
	constructor(name, chips, hand) {
		this.name = name;
		this.chips = chips;
		this.hand = hand;
	}
	
	bet(amount, table) {
		this.chips - amount;
		table.pot + amount;
	}
}
