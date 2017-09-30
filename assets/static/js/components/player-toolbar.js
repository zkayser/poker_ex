import $ from 'jquery';

export default class PlayerToolbar {
  constructor(player, room, channel) {
    this.joinBtnOpts = {
      name: "join-btn",
      message: "add_player",
      params: {
        player: player,
        room: room,
        joinAmt: $("#join-amount-input").val()
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
    this.room = room;
    this.player = player;
    this.channel = channel;
  }
  
  init(data) {
    if (data.state == "idle" || data.state == "between_rounds") {
      if (Object.keys(data.seating).includes(this.player)) {
        // Player has already joined, but game has not started.
        window.Materialize.toast(`
          If there are two or more players at the table, you can launch a new game by pressing the 'Start' tab
          found on your player toolbar.
        `, 8000, 'cyan-toast');
        this.setupBtn(this.startBtnOpts);
        this.setupBtn(this.leaveBtnOpts);
      } else {
        this.joinInfo();
        this.setupBtn(this.joinBtnOpts);
        $("#start-info-item").html(this.accountCircle());
      }
    } else if (Object.keys(data.seating).includes(this.player)) {
      this.setupBtn(this.leaveBtnOpts);
      $("#start-info-item").html(this.accountCircle());
    } else {
      this.joinInfo();
      this.setupBtn(this.joinBtnOpts);
    }
  }
  
  update(data) {
    if (!(Object.keys(data.seating).includes(this.player))) {
      this.setupBtn(this.joinBtnOpts);
    } else if (data.state == "idle" || data.state == "between_rounds") {
        this.setupBtn(this.startBtnOpts);
        this.setupBtn(this.leaveBtnOpts);
    } else {
        $("#start-info-item").html(this.accountCircle());
        this.setupBtn(this.leaveBtnOpts);
    }
  }
  
  setupBtn(btnOpts) {
    if (btnOpts.name == 'join-btn') {
      this.renderBtn(btnOpts.name);
      $("#join-amount-input").off('keyup');
      $("#join-amount-input").on('keyup', (e) => {
        if (e.keyCode == 13) {
          this.join();
        }
      $("#join-amount-btn").off('click');
      $("#join-amount-btn").on('click', (e) => {
        this.join();
      });
      });
    }  else if (btnOpts.name == 'leave-btn') {
      this.renderBtn(btnOpts.name);
      let btn = document.getElementById(btnOpts.name);
      btn.addEventListener('click', () => {
        this.channel.push(btnOpts.message, btnOpts.params);
        this.setupBtn(this.joinBtnOpts);
        $("#start-info-item").html(this.accountCircle());
      }); 
    } 
    else {
      this.renderBtn(btnOpts.name);
      let btn = document.getElementById(btnOpts.name);
      btn.addEventListener('click', () => {
        this.channel.push(btnOpts.message, btnOpts.params);
      }); 
    }
  }
  
  renderBtn(btnName) {
    if (btnName == "join-btn") {
      $("#join-quit-item").html(
        `<a href="#join-modal" class="white-text waves-effect waves-light" id="join-btn">JOIN</a>`);
    } else if (btnName == "start-btn") {
      $("#start-info-item").html(`<a href="#!" class="white-text" id="start-btn">START</a>`);
    } else if (btnName == "leave-btn") {
      $("#join-quit-item").html(`<a href="#!" class="white-text" id="leave-btn">QUIT</a>`);
    }
  }
  
  join() {
    let val = $("#join-amount-input").val();
    let max = $("#join-amount-input").data("max");
    val = parseInt(val, 10);
    let errorMessage = `You must enter a number that is at least 100 and no more than ${max}`;
    
    if (typeof(val) == 'number' && val <= max && val >= 100) {
      // Okay to join
      this.channel.push("add_player", {player: this.player, room: this.room, amount: val});
      $("#join-amount-input").val('');
      $("#join-close").click();
    } else {
      $("#join-error").text("");
      $("#join-input-div").append(this.errorMessage(errorMessage));
    }
  }
  
  accountCircle() {
    return `<a href="#player-account-modal" class="white-text waves-effect waves-light"><i class="material-icons">account_circle</i></a>`;
  }
  
  errorMessage(message) {
    return `<p class="red-text" id="join-error">${message}</p>`;
  }
  
  joinInfo() {
    window.Materialize.toast(`
      To join the table, open your player toolbar by pressing the red button in the bottom right-hand corner.
      Click on join and enter the number of chips you want to bring to the table when prompted.
    `, 8000, 'cyan-toast');
  }
}