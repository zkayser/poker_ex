import {Socket} from 'phoenix';
import MainView from '../main-view';
import $ from 'jquery';
import SpinnerAnimation from '../../animations/spinner-animations';
import Table from '../../table';
import Card from '../../card';
import Player from '../../player';
import Controls from '../../components/controls';
import TableConcerns from '../../table-concerns';
import PlayerMessages from '../../messages/player-messages';
import RoomMessages from '../../messages/room-messages';
import RaiseControl from '../../components/raise-control';
import GAMEMESSAGES from '../../messages/game-messages';
import Dispatcher from '../../messages/dispatcher';
import Game from '../../game';

export default class PrivateRoomShowView extends MainView {
  
  mount() {
    super.mount();
    console.log("PrivateRoomShowView mounted...");
    
    let div = document.getElementById("room-row");
    let roomTitle = div.dataset.roomTitle;
    let player = div.dataset.userName;
    
    let game = new Game(player, roomTitle);
    game.init();
    
    /*
    
    let joinBtn = $("#join-btn");
    let leaveBtn = $("#leave-btn");
    let startBtn = $("#start-btn");
    
    let tableMsgsInitiated = false;
    let lastTableCardsSeen = [];
    
    let socket = new Socket('/socket', {params: {token: window.playerToken}});
    
    socket.connect();
    let channel = socket.channel(`players:${roomTitle}`, {type: "private"});
    
    channel.join()
    .receive("ok", params => {
      console.log("Channel joined; callback params received: ", params);
      joinBtn.click(() => {
        channel.push("add_player", {player: player, room: roomTitle});
        joinBtn.slideUp();
      });
      leaveBtn.click(() => {
        channel.push("remove_player", {player: player, room: roomTitle});
        leaveBtn.slideUp();
      });
      startBtn.click(() => {
        channel.push("start_game", {room: roomTitle});
        startBtn.slideUp();
      });
    })
    .receive("error", params => {
      console.log("Something went wrong when joining channel: ", params);
    });
    
    
    GAMEMESSAGES.forEach((message) => {
      // Haven't added all messages, such as private_room_join to the GAMEMESSAGES constant yet.
      channel.on(message, (payload) => {
        Dispatcher.dispatch(message, payload, this);
      });
    });
    
    // Initialize the table UI and player info section in this callback, then init TableConcerns
    channel.on("private_room_join", state => {
      SpinnerAnimation.onJoinPrivateRoom();
      if (state.state == "idle" || state.state == "between_rounds") {
        console.log("state is currently: ", state.state);
      } else {
        console.log("data is: ", state);
        let raiseData = RaiseControl.extractRaiseControlData(state, player);
        if (state.active == player) {
          console.log("initiating raiseControl Component...");
          this.raiseControl = new RaiseControl(raiseData, player);
          this.raiseControl.initComponent(channel, player);
        }
        // Add player to state as the user for the table
        state.user = player;
        let tableData = Table.extractTableData(state);
        this.table = new Table(tableData);
        //this.tableConcerns = new TableConcerns(this.table);
        //this.tableConcerns.init(channel);
        this.table.addActiveClass(state.active);
        this.handlePlayerHands(player, state.player_hands);
        this.table.updatePot(state.pot);
        this.controls = new Controls(state);
        this.controls.init(state);
        PlayerMessages.init(channel, player);
        RoomMessages.init(channel);

      /*
      let seating = this.formatSeating(state.seating);
      state.seating = seating;
      Table.renderPlayers(seating);
      Table.addActiveClass(state.active, seating);
      this.handlePlayerHands(player, state.player_hands);
      this.handleActivePlayerRender(player, state);
      this.setPot(state.pot);
      
      if (tableMsgsInitiated) {
        this.handleTableCardUpdate(state.table, lastTableCardsSeen);
        lastTableCardsSeen = state.table.map((obj) => {return new Card(obj.rank, obj.suit)});
      } else {
        TableConcerns.init(channel, player, {}, state);
        PlayerMessages.init(channel, player);
        RoomMessages.init(channel);
        tableMsgsInitiated = true;
      }
    });
    
    channel.on("join_room_success", () => {
      console.log("Room joined successfully!");
    });
    
    channel.on("flop_dealt", ({cards}) => {
      cards.forEach((card) => {
        lastTableCardsSeen.push(new Card(card.rank, card.suit));
      });
    });
    channel.on("card_dealt", (card) => {
      lastTableCardsSeen.push(new Card(card.rank, card.suit));
    });
    
    channel.on("game_finished", (payload) => {
      lastTableCardsSeen = [];
    });
    
    channel.on("add_player_success", (payload) => {
      $("#join-quit-item").html('<a href="#!" class="white-text" id="leave-btn">QUIT</a>');
    });
    
    channel.on("started_game", (state) => {
      startBtn.slideUp();
      $("#start-info-item").html('<a href="#player-account-modal" class="white-text waves-effect waves-light"><i class="material-icons">account_circle</i></a>');
      // Init the table state, player controls, and raise control panel
      let seating = this.formatSeating(state.seating);
      state.seating = seating;
      Table.renderPlayers(seating);
      Table.addActiveClass(state.active, seating);
    });
    
    channel.on("error_on_room_join", (payload) => {
      console.log("An error occured when joining the room: ", payload);
    });
    */
  }
  
  handlePlayerHands(player, player_hands) {
    let players = player_hands.map((obj) => {
      return obj.player;
    });
    if (players.includes(player)) {
      let filtered = player_hands.filter((obj) => {
        if (obj.player == player) {
          return true;
        }
      });
      let hand = filtered[0].hand;
      Card.renderPlayerCards(hand);
    }
  }
  
  setPot(pot) {
    $("#pot").text(pot);
  }
  
  formatSeating(seatingArray) {
    let seating = new Object();
    seatingArray.forEach((seat) => {
      seating[`${seat.name}`] = seat.position;
    });
    return seating;
  }
  
  handleActivePlayerRender(player, state) {
    if (player == state.active) {
      Player.renderPlayerControls(state.to_call, state.round[player]);
    }
  }
  
  handleTableCardUpdate(currentTable, lastSeen) {
    let tableCards = document.querySelector(".table-cards");
    let cards = [];
    if (currentTable.length > 0) {
      currentTable.forEach((obj) => {
        cards.push(new Card(obj.rank, obj.suit));
      });
    }
    tableCards.innerHTML = '';
    Table.renderCards(cards);
  }
  
  unmount() {
    super.unmount();
  }
}