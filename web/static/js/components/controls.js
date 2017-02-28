import $ from 'jquery';
import Player from '../player';

export default class Controls {
  
  constructor(data) {
    this.player = data.user || null; // string
    this.channel = data.channel || null;
    this.to_call = data.to_call || 0;
    this.round = data.round[data.user] || 0;
    this.callDiv = $("#call-div");
    this.raiseDiv = $("#raise-div");
    this.checkDiv = $("#check-div");
    this.foldDiv = $("#fold-div");
    this.raiseBtn = $(".raise-control-btn");
    this.callBtn = $(".call-btn");
    this.checkBtn = $(".check-btn");
    this.foldBtn = $(".fold-btn");
    this.shortControls = $(".short-controls");
  }
  
  update(state) {
    this.hideAllAndDetachEvents();
    this.to_call = state.to_call;
    this.round = state.round[this.player] || 0;
    this.selectCtrlTypes(state);
    console.log("this.currentCtrls in update: ", this.currentCtrls);
    (state.user) == state.active ? this.showAllAndAttachEvents(this.currentCtrls) : this.hideAllAndDetachEvents(); 
  }
  
  clear() {
    this.hideAllAndDetachEvents();
  }
  
  // Private
  
  show(type) {
    if (type == 'call') {
      $("#call-amount-info").remove();
      this[`${type}Btn`].append($(`<span id="call-amount-info" class="white-text">${this.amountToCall()}</span>`));
    }
    if (type == 'raise') {
      $(".raise-control-btn").css("visibility", "visible");
    }
    this[`${type}Div`].fadeIn('slow');
    this[`${type}Btn`].fadeTo('slow', 1);
    $(`.${type}-btn`).css("visibility", "visible");
  }
  
  hide(type) {
    this.btnOpacityToZero(type);
    this[`${type}Div`].fadeOut('slow');
    this[`${type}Btn`].fadeTo('slow', 0);
  }
  
  showAll(ctrls) {
    ctrls.forEach((type) => {
      this.show(type);
    });
  }
  
  hideAll() {
    this.shortControls.fadeTo('fast', 0);
    let ctrls = this.ctrlTypes();
    ctrls.forEach((type) => {
      this.hide(type);
    });
  }
  
  showAllAndAttachEvents(ctrls) {
    this.showAll(ctrls);
    this.shortControls.fadeTo('fast', 1);
    this.attachClickEvents(ctrls);
    this.shortControls.click();
  }
  
  hideAllAndDetachEvents() {
    this.hideAll();
    this.detachClickEvents();
  }
  
  ctrlTypes() {
    return ["call", "raise", "check", "fold"];
  }
  
  selectCtrlTypes(state) {
    if (Player.filterPlayersArrayByName(state, this.player)) {
      let paid = state.round[this.player] || 0;
      let chips = Player.filterPlayersArrayByName(state, this.player).chips;
      let ctrls;
      if (paid < state.to_call && chips > state.to_call) {
        ctrls = ["raise", "call", "fold"];
      } else if (paid < state.to_call && chips <= state.to_call) {
        ctrls = ["call", "fold"];
      } else if (paid >= state.to_call && chips > state.to_call) {
        ctrls = ["raise", "check"];
      } else {
        ctrls = ["check"];
      }
      this.currentCtrls = ctrls;
      return ctrls;
    } 
  }
  
  amountToCall() {
    return this.to_call - this.round;
  }
  
  attachClickEvents(ctrls) {
    // Remove any lingering click handlers;
    let btns = [$(".call-btn"), $(".check-btn"), $(".fold-btn"), this.shortControls];
    btns.forEach((btn) => {
      btn.off("click");
    });
    
    $(".call-btn").click((e) => {
      Player.call(this.player, this.channel);
      $("#controls-close").click();
      $(".call-btn").off("click");
    });
    $(".check-btn").click((e) => {
      Player.check(this.player, this.channel);
      $("#controls-close").click();
      $(".check-btn").off("click");
    });
    $(".fold-btn").click((e) => {
      Player.fold(this.player, this.channel);
      $("#controls-close").click();
      $(".fold-btn").off("click");
    });
    this.shortControls.click((e) => {
      console.log('Got click on shortControls...');
      this.displayOnlyCurrent(ctrls);
    });
  }
  
  detachClickEvents() {
    let btns = [".call-btn", ".check-btn", ".fold-btn"];
    btns.forEach((btn) => {
      removeEventListener('click', btn);
    });
  }
  
  displayOnlyCurrent(ctrls) {
    console.log("DISPLAY ONLY CURRENT WITH CURRENTCTRLS: ", ctrls);
    let btns = ["call", "raise", "check", "fold"];
    btns.forEach((btn) => {
      if (!ctrls.includes(btn)) {
        this.btnOpacityToZero(btn);
      } else {
        console.log("SHOWING BTN: ", btn);
        this.btnVisible(btn);
      }
    });
  }
  
  btnOpacityToZero(str) {
    if (str == "raise") {
      $(".raise-control-btn").css("visibility", "hidden");
    } else if (["call", "fold", "check"].includes(str)) {
      $(`.${str}-btn`).css("visibility", "hidden");
    }
  }
  
  btnVisible(str) {
    if (str == "raise") {
      $(".raise-control-btn").css("visibility", "visible");
    } else if (["call", "fold", "check"].includes(str)) {
      $(`.${str}-btn`).css("visibility", "visible");
    }
  }
}