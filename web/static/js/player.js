export default class Player {
	
	constructor(name, chips) {
		this.name = name;
		this.chips = chips;
		this.playerInfo = document.getElementById("player-info");
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
	
	renderPlayerInfo() {
		console.log("renderPlayerInfo called");
		let oldInfo = document.getElementById("info");
		console.log(oldInfo);
		if (oldInfo) {
			this.playerInfo.removeChild(oldInfo);
		}
		let paragraph = document.createElement('p');
		paragraph.innerText = `${this.name}: ${this.chips}`;
		paragraph.setAttribute("id", "info");
		this.playerInfo.appendChild(paragraph);
	}
	
	static renderPlayerControls() {
		let playerControls = document.querySelector(".player-controls");
		playerControls.style.visibility = "visible";
	}
	
	static hidePlayerControls() {
		let playerControls = document.querySelector(".player-controls");
		if (playerControls.style.visibility == "visible") {
			playerControls.style.visibility = "hidden";
		}
	}
	
	static raise(player, amount, channel) {
		channel.push("player_raised", {
			player: player,
			amount: amount
		});
	}
	
	static fold(player, channel) {
		channel.push("player_folded", {
			player: player.name
		});
	}
	
	static call(player, channel) {
		channel.push("player_called", {
			player: player.name
		});
	}
	
	static check(player, channel) {
		channel.push("player_checked", {
			player: player.name
		});
	}
}
