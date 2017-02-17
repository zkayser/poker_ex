import $ from 'jquery';

export default class PlayerToolbar {
  constructor(player, room, channel) {
    this.joinBtnOpts = {
      name: "join-btn",
      message: "add_player",
      params: {
        player: player,
        room: room
      }
    };
    this.startBtnOpts = {
      name: "start-btn",
      message: "start_game",
      params: {room: room}
    };
    this.leaveBtnOpts = {
      name: "leave-btn",
      message: "remove_player",
      params: {
        player: player,
        room: room
      }
    };
    this.player = player;
    this.channel = channel;
  }
  
  init(data) {
    if (data.state == "idle") {
      if (Object.keys(data.seating).includes(this.player)) {
        // Player has already joined, but game has not started.
        this.setupBtn(this.startBtnOpts);
        this.setupBtn(this.leaveBtnOpts);
      } else {
        this.setupBtn(this.joinBtnOpts);
        $("#start-info-item").html(this.accountCircle());
      }
    } else if (Object.keys(data.seating).includes(this.player)) {
      this.setupBtn(this.leaveBtnOpts);
      $("#start-info-item").html(this.accountCircle());
    } else {
      this.setupBtn(this.joinBtnOpts);
    }
  }
  
  update(data) {
    if (!(Object.keys(data.seating).includes(this.player))) {
      this.setupBtn(this.joinBtnOpts);
    } else if (data.state == "idle") {
        this.setupBtn(this.startBtnOpts);
        this.setupBtn(this.leaveBtnOpts);
    } else {
        $("#start-info-item").html(this.accountCircle());
        this.setupBtn(this.leaveBtnOpts);
    }
  }
  
  setupBtn(btnOpts) {
    this.renderBtn(btnOpts.name);
    let btn = document.getElementById(btnOpts.name);
    console.log("btn");
    btn.addEventListener('click', () => {
      console.log(`${btnOpts.name} clicked`);
      this.channel.push(btnOpts.message, btnOpts.params);
    });
  }
  
  renderBtn(btnName) {
    if (btnName == "join-btn") {
      $("#join-quit-item").html(`<a href="#!" class="white-text" id="join-btn">JOIN</a>`);
    } else if (btnName == "start-btn") {
      $("#start-info-item").html(`<a href="#!" class="white-text" id="start-btn">START</a>`);
    } else if (btnName == "leave-btn") {
      $("#join-quit-item").html(`<a href="#!" class="white-text" id="leave-btn">QUIT</a>`);
    }
  }
  
  accountCircle() {
    return `<a href="#player-account-modal" class="white-text waves-effect waves-light"><i class="material-icons">account_circle</i></a>`;
  }
}