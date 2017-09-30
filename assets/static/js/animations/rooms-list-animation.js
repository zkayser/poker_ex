export default class RoomsListAnimation {
  
  constructor() {}
  
  static animate() {
    let Materialize = window.Materialize;
    
    let staggered = document.getElementById("staggered");
    staggered.style.opacity = 1;
    Materialize.showStaggeredList("#staggered");
  }
}