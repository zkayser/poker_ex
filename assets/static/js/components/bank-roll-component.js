import $ from 'jquery';

export default class BankRollComponent {
  constructor(player, channel) {
    this.player = player;
    this.channel = channel;
    this.submitBtn = $("#bank-roll-submit");
    this.input = $("#bank-input");
    this.max = $("#bank-max").text();
  }
  
  init() {
    let inputHandler = (e) => {
      let val = this.input.val();
      if (this.inputValid(val)) {
        this.submitBtn.hasClass('disabled') ? this.submitBtn.removeClass('disabled') : console.log('submitBtn active');
      } else {
        this.submitBtn.hasClass('disabled') ? console.log('submitBtn disabled') : this.submitBtn.addClass('disabled');
      }
    };
    this.input.on('keyup', inputHandler);
    this.submitBtn.on('click', () => {
      if (!this.submitBtn.hasClass('disabled')) {
        this.submitHandler();
      }
    });
    this.input.on('keydown', (e) => {
      if (e.keyCode == 13 && !(this.submitBtn.hasClass('disabled'))) {
        this.submitHandler();
      }
    });
  }
  
  update(newMax) {
    $("#bank-max").text(newMax);
    this.max = newMax;
  }
  
  inputValid(str) {
    let notStartingWithZero = /^(?!0.)\d+$/;
    return notStartingWithZero.test(str) && parseInt(str, 10) < this.max;
  }
  
  submitHandler() {
    let value = this.input.val();
    if (this.inputValid(value)) {
      this.channel.push('request_chips', {player: this.player, amount: value});
      this.input.val('');
      this.submitBtn.addClass('disabled');
      $("#bank-close").click();
    }
  }
}