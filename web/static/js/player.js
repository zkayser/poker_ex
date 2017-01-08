import $ from "jquery";

export default class Player {
	
	constructor(name, chips, seatingPosition) {
		this.name = name;
		this.chips = chips;
		this.seatingPosition = seatingPosition || undefined;
		this.playerInfo = document.getElementById("player-info");
	}
	
	bet(amount, table) {
		this.chips - amount;
		table.pot + amount;
	}
	
	static addToList(player) {
		let joinMsg = document.createElement('li');
		joinMsg.innerText = player.name || player;
		joinMsg.setAttribute('id', 'player-element');
		return joinMsg;
	}
	
	renderPlayerInfo() {
		console.log("renderPlayerInfo called");
		let oldInfo = document.getElementById("info");
		if (oldInfo) {
			this.playerInfo.removeChild(oldInfo);
		}
		let paragraph = document.createElement('p');
		paragraph.innerText = `${this.name}: ${this.chips}`;
		paragraph.setAttribute("id", "info");
		this.playerInfo.appendChild(paragraph);
	}
	
	static renderPlayerControls() {
		console.log("renderPlayerControls");
		let controls = [$(".player-controls"), $(".fold-btn"), $(".call-btn")];
		controls.forEach((control) => {
			control.fadeTo("slow", 1);
		});
	}
	
	static hidePlayerControls() {
		console.log("hidePlayerControls");
		let controls = [$(".player-controls"), $(".fold-btn"), $(".call-btn")];
		controls.forEach((control) => {
			control.fadeTo("slow", 0);
		});
	}
	
	static raise(player, amount, channel) {
		channel.push("player_raised", {
			player: player.name || player,
			amount: amount
		});
	}
	
	static fold(player, channel) {
		channel.push("player_folded", {
			player: player.name || player
		});
	}
	
	static call(player, channel) {
		channel.push("player_called", {
			player: player.name || player
		});
	}
	
	static check(player, channel) {
		channel.push("player_checked", {
			player: player.name || player
		});
	}
}
