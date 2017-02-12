import $ from "jquery";

export default class Player {
	
	constructor(name, chips, seatingPosition) {
		this.name = name;
		this.chips = chips;
		this.seatingPosition = seatingPosition || undefined;
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
	
	static renderPlayerControls(callAmount, paidInRound) {
		let controls = [];
		if (callAmount > paidInRound || paidInRound === undefined ) {
			controls = [$(".call-btn"), $(".fold-btn"), $(".raise"), $(".raise-btn")];
		} else if (callAmount === paidInRound || callAmount === 0) {
			controls = [$(".check-btn"), $(".raise"), $(".raise-btn")];
		}
		controls.forEach((control) => {
			control.fadeTo("slow", 1);
		});
	}
	
	renderPlayerControls(callAmount, paidInRound) {
		let controls = [];
		if (callAmount > paidInRound || paidInRound === undefined ) {
			controls = [$(".call-btn"), $(".fold-btn"), $(".raise"), $(".raise-btn"), $(".raise-control-btn")];
		} else if (callAmount === paidInRound || callAmount === 0) {
			controls = [$(".check-btn"), $(".raise"), $(".raise-btn"), $(".raise-control-btn")];
		} else if (callAmount > this.chips) {
			controls = [$(".call-btn"), $(".fold-btn")];
		}
		controls.forEach((control) => {
			control.fadeTo("slow", 1);
		});
		window.Materialize.toast("Your turn!", 1000);
	}
	
	static hidePlayerControls() {
		let controls = [$(".fold-btn"), $(".call-btn"), $(".check-btn"), $(".raise"), $(".raise-btn"), $(".raise-control-btn")];
		controls.forEach((control) => {
			control.fadeTo("slow", 0);
		});
		$("#controls-modal").css("display", "none").css("opacity", 0);
		$(".modal-overlay").css("display", "none");
		$("#controls-modal").removeClass("open");
	}
	
	static raise(player, amount, channel) {
		channel.push("player_raised", {
			player: player.name || player,
			amount: amount
		});
		$("#close-controls").click();
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
	
	static emblem(player) {
		let div = document.createElement('div');
		let span = document.createElement('span');
		span.innerHTML = player.charAt(0);
		div.appendChild(span);
		return div;
	}
}
