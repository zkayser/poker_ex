import $ from 'jquery';

export default class SpinnerAnimation {
  
  constructor() {}
  
  static fadeOnSignin() {
    let Materialize = window.Materialize;
    $(".signup").fadeOut(400, () => {
        let staggered = document.getElementById("staggered");
        staggered.style.opacity = 1;
        Materialize.showStaggeredList("#staggered");
      });
      $(".login-spinner").removeClass("active"); 
  } 
  
  static onJoinRoom() {
    console.log("onJoinRoom function called");
    $(".collection").fadeOut(400, () => {
        $(".card-table").addClass("slide-onscreen-right");
        $(".player-controls").addClass("slide-onscreen-right");
        $(".table-container").css("display", "inline-block");
      });
    $(".join-spinner").removeClass("active");
  }
  
  static onJoinPrivateRoom() {
    console.log("onJoinPrivateRoom function called");
    $(".card-table").addClass("slide-onscreen-right");
    $(".player-controls").addClass("slide-onscreen-right");
    $(".table-container").css("display", "inline-block");
  }
  
  static initiateSpinnerOnElement(spinner, element) {
    spinner.addClass("active");
    element.addClass("light-transparent");
  }
  
  static terminateSpinnerOnElement(spinner, element) {
    spinner.removeClass("active");
    element.removeClass("light-transparent");
  }
  
}