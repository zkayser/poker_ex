// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import Connection from "./socket";
import $ from "jquery";
import SpinnerAnimation from "./animations/spinner-animations";

let joinButton = document.querySelector(".join-btn");
let joinInput = document.querySelector("#join-input");

if (joinButton && joinInput) {

	joinButton.addEventListener('click', handleJoin);
	joinInput.addEventListener('keypress', (e) => {
		if (e.charCode === 13) {
			SpinnerAnimation.initiateSpinnerOnElement($(".login-spinner"), $(".signup"));
			handleJoin();
		}
	});
}
	
	function handleJoin() {
		let name = joinInput.value;
		joinInput.value = "";
		if (name.length > 0) {
			Connection.init(name.trim());
		}	else {
				SpinnerAnimation.terminateSpinnerOnElement($(".login-spinner"), $(".signup"));
				alert("You must enter a name to join");
		}
	}



