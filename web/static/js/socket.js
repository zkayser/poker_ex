// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix";
import Player from "./player";
import Table from "./table";
import Card from "./card";

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token on connect as below. Or remove it
// from connect if you don't care about authentication.



// Now that you are connected, you can join channels with a topic:
let Connection = {
  me: null,
  players: [],
  messages: document.querySelector("#messages"),
  cardTable: document.querySelector(".card-table"),
  cardHolder: document.querySelector(".card-holder"),
  playerCards: document.getElementById("player-cards"),
  playerInfo: document.getElementById("player-info"),
  
  init(name, document){
    let socket = new Socket('/socket', {params: {name: name}});
    socket.connect();
    let channel = socket.channel("players:lobby", {});
    this.me = name;
    
    channel.join()
    .receive("ok", initialPlayers => {
      console.log(initialPlayers);
      console.log("Joined channel");
      if(!(initialPlayers.players === null)) {
        this.players = initialPlayers.players;
        this.players.forEach(player => {
          let pl = new Player(player.name, player.chips);
          let msg = Player.addToList(pl);
          this.appendAndScroll(msg);
        });
      }
      let emblem = Table.place(this.me, true);
      this.cardTable.append(emblem);
      channel.push("new_msg", {body: this.me});
    });
    
    channel.on("player_joined", payload => {
      console.log(this.players);
      let player = new Player(payload.player.name, payload.player.chips);
      if (player.name == this.me) {
        let info = Player.renderPlayerInfo(player);
        this.playerInfo.appendChild(info);
      }
      let msg = Player.addToList(player);
      this.appendAndScroll(msg);
      this.players.push(player);
    });
    
    channel.on("new_msg", payload => {
      Materialize.toast(`${payload.body} joined the lobby`, 3000, 'rounded')
    });
    
    channel.on("chip_update", payload => {
      console.log(payload);
    });
    
    channel.on("game_began", payload => {
      // payload.hands is an array of objects
      // with a hand, which is an array of card
      // objects, and a player string
      this.cardHolder.style.visibility = "visible";
      payload.hands.forEach((obj) => {
        if (obj.player == this.me) {
          let cards = Card.renderPlayerCards(obj.hand);
          cards.forEach((card) => {
            this.playerCards.appendChild(card);
          });
        }
      });
    });
    
    channel.on("player_left", payload => {
      let names = this.players.map(player => {
        player.name;
      });
      let index = names.indexOf(payload.body.name);
      this.players.splice(index, 1);
      Materialize.toast(`${payload.body.name} left`, 3000, 'rounded')
      for (var i = 0; i < this.messages.children.length; i++) {
        if(this.messages.children[i].innerText == payload.body.name) {
          this.messages.removeChild(this.messages.children[i]);
        }
      }
    });
  },
  
  appendAndScroll(element) {
    this.messages.append(element);
    this.messages.scrollTop = 0;
  }
};

export default Connection;
