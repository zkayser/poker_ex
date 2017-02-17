import $ from 'jquery';
import Player from '../player';

export default class RaiseControl {
  
  constructor(data) {
    this.channel = data.channel;
    this.user = data.user;
    this.slider = $("#raise-amount-slider");
    this.raiseValDisplay = $("#raise-value");
    this.raiseValMobile = $("#raise-value-mobile");
    this.increaseButton = $(".increase-btn");
    this.decreaseButton = $(".decrease-btn");
    this.submitBtn = $("#raise-submit");
    this.submitBtn.removeClass("disabled");
    this.raiseInput = $("#raise-amount");
    this.raiseControlBtn = $(".raise-control-btn");
    this.raiseControlBtn.removeClass("disabled");
    if (data.raiseable) {
      this.min = data.min + 5;
      this.max = data.max;
    } else {
      this.raiseControlBtn.addClass("disabled");
      this.submitBtn.addClass("disabled");
    }
    if (this.max) {
      let val = Math.round(this.max / 2);
      while (val % 5 != 0) {
        val++;
      }
      this.slider.val(val);
      this.raiseValDisplay.text(val);
      this.raiseValMobile.text(val);
    }
  }
  
  init() {
    this.submitBtn.fadeTo('slow', 1);
    this.attachRaiseValDisplayUpdate();
    this.attachSliderEvent();
    this.setSliderMinMax();
    this.attachRaiseInputEvent();
    this.attachIncreaseButtonEvent();
    this.attachDecreaseButtonEvent();
    this.attachSubmitEvent();
    this.setCursorOnIncDecBtns();
  }
  
  update(state) {
    this.detachEvents();
    if (state.raiseable) {
      this.min = state.min + 5;
      this.max = state.max;
      this.submitBtn.fadeTo('slow', 1);
    } else {
      this.raiseControlBtn.addClass("disabled");
      this.submitBtn.addClass("disabled");
    }
    if (this.max) {
      let val = Math.round(this.max / 2);
      while (val % 5 != 0) {
        val++;
      }
      this.slider.val(val);
      this.raiseValDisplay.text(val);
      this.raiseValMobile.text(val);
    }
    this.setSliderMinMax();
    this.attachSubmitEvent();
    this.attachSliderEvent();
    this.attachRaiseInputEvent();
    this.attachIncreaseButtonEvent();
    this.attachDecreaseButtonEvent();
  }
  
  setSliderMinMax() {
    if (this.min && this.max) {
      this.slider.attr('min', this.min);
      this.slider.attr('max', this.max);
    }
  }
  
  attachSliderEvent() {
    this.slider.on('change', (event) => {
      this.updateDisplayValue(this.keepInRange(event.target.value));
    });
  }
  
  attachRaiseInputEvent() {
    this.raiseInput.on('input', (event) => {
      if (!isNaN(parseInt(event.target.value, 10))) {
        this.updateDisplayValue(this.keepInRange(event.target.value));
      } else {
        this.updateDisplayValue("0"); 
      }
    });
  }
  
  attachRaiseValDisplayUpdate() {
    this.raiseValDisplay.bind('DOMSubtreeModified', (e) => {
      this.slider.val(e.currentTarget.innerText);
    });
  }
  
  attachIncreaseButtonEvent() {
    this.setIncDecBtnEvents('inc');
  }
  
  attachDecreaseButtonEvent() {
    this.setIncDecBtnEvents('dec');
  }
  
  attachSubmitEvent() {
    this.submitBtn.on('click', (e) => {
      $("#raise-control-close").click();
      $("#controls-close").click();
      Player.raise(this.user, this.slider.val(), this.channel);
    });
  }
  
  setIncDecBtnEvents(btnType, value = 5) {
    let changeInterval;
    let btn = btnType == 'inc' ? this.increaseButton : this.decreaseButton;
    btn.on('click', (e) => {
      this.updateRaiseValDisplay(btnType, value);
    });
    btn.on('mousedown touchdown', (e) => {
      changeInterval = setInterval(() => {
        this.updateRaiseValDisplay(btnType, value);
      }, 100);
    });
    btn.on('mouseup touchup', (e) => {
      clearInterval(changeInterval);
    });
  }
  
  updateRaiseValDisplay(btnType, value) {
    let currentVal = parseInt(this.raiseValDisplay.text(), 10);
    if (btnType == 'inc') {
      this.raiseValDisplay.text(`${this.keepInRange(currentVal + value)}`);
      this.raiseValMobile.text(`${this.keepInRange(currentVal + value)}`);
    } else {
      this.raiseValDisplay.text(`${this.keepInRange(currentVal - value)}`);
      this.raiseValMobile.text(`${this.keepInRange(currentVal - value)}`);
    }
  }
  
  setCursorOnIncDecBtns() {
    this.increaseButton.css('cursor', 'pointer');
    this.decreaseButton.css('cursor', 'pointer');
  }
  
  updateDisplayValue(number) {
    this.raiseValDisplay.text(number);
    this.raiseValMobile.text(number);
  }
  
  detachEvents() {
    this.submitBtn.off('click');
    this.slider.off('change');
    this.raiseInput.off('input');
    let incDec = [this.increaseButton, this.decreaseButton];
    incDec.forEach((btn) => {
      btn.off('click');
      btn.off('mousedown');
      btn.off('mouseup');
      btn.off('touchdown');
      btn.off('touchup');
    });
  }
  
  keepInRange(number) {
    if (number > this.max) {
      return this.max || 0;
    } else if (number < this.min) {
      return this.min || 0;
    } else {
      return number;
    }
  }
}