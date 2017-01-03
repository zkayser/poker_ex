export default class Player {
	constructor(name, chips) {
		this.name = name;
		this.chips = chips;
	}
	
	bet(amount, table) {
		this.chips - amount;
		table.pot + amount;
	}
	
	static addToList(player) {
		let joinMsg = document.createElement('li');
		joinMsg.innerText = player.name;
		joinMsg.setAttribute('id', 'player-element');
		return joinMsg;
	}
	
	static renderPlayerInfo(player) {
		let paragraph = document.createElement('p');
		paragraph.innerText = `${player.name}: ${player.chips}`;
		return paragraph;
	}
	
	
}
