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
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

import Connection from "./socket";

let joinButton = document.querySelector(".join-btn");
let chatInput = document.querySelector("#chat-input");


joinButton.addEventListener('click', handleJoin);
chatInput.addEventListener('keypress', (e) => {
	if (e.charCode === 13) {
		handleJoin();
	}
});

function handleJoin() {
	let name = chatInput.value;
	chatInput.value = "";
	if (name.length > 0) {
		Connection.init(name.trim());
	}	else {
			alert("You must enter a name to join");
	}
}




