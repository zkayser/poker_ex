import $ from 'jquery';
import Player from '../player';

export default class Controls {
  
  constructor(data) {
    this.player = data.user || null; // string
    this.callDiv = $("#call-div");
    this.raiseDiv = $("#raise-div");
    this.checkDiv = $("#check-div");
    this.foldDiv = $("#fold-div");
    this.raiseBtn = $(".raise-control-btn");
    this.callBtn = $(".call-btn");
    this.checkBtn = $(".check-btn");
    this.foldBtn = $(".fold-btn");
  }
  
  show(type) {
    this[`${type}Div`].fadeIn('slow');
    this[`${type}Btn`].fadeTo('slow', 1);
  }
  
  hide(type) {
    this[`${type}Div`].fadeOut('slow');
    this[`${type}Btn`].fadeTo('slow', 0);
  }
  
  showAll(ctrls) {
    ctrls.forEach((type) => {
      this.show(type);
    });
  }
  
  hideAll() {
    let ctrls = this.ctrlTypes();
    ctrls.forEach((type) => {
      this.hide(type);
    });
  }
  
  init(state) {
    let initCtrls = this.selectCtrlTypes(state);
    (state.user) == state.active ? this.showAll(initCtrls) : this.hideAll();
  }
  
  ctrlTypes() {
    return ["call", "raise", "check", "fold"];
  }
  
  selectCtrlTypes(state) {
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
    return ctrls;
  }
}