import MainView from '../main-view';
import Online from '../online';
import $ from 'jquery';

export default class PrivateRoomNewView extends MainView {
  
  constructor() {
    super();
    this.playerList = document.getElementsByClassName('player-list')[0];
    this.invitees = document.getElementById("invitees");
  }
  
  mount() {
    super.mount();
    console.log("PrivateRoomNewView mounted");
    
    this.SetButtonEvents();
    
    Online.init();
  }
  
  unmount() {
    super.unmount();
    console.log("PrivateRoomNewView unmounting...");
  }
  
  
  SetButtonEvents() {
    $("#invitees").on("click", ".btn-floating", (event) => {
      let id = event.currentTarget.dataset.playerId;
      let clone = $(`#player-list-item-${id}`).clone();
      $(`#player-list-item-${id}`).remove();
      clone.appendTo(".player-list");
      clone.children('secondary-content').remove();
      clone.append(`<span class="secondary-content">
              <button class="btn-floating green lighten-2 waves-effect waves-light player-btn" type="button" id="player-list-${id}"
                      data-player-id="${id}">
                <i class="material-icons">plus_one</i>
              </button>
            </span>`);
      $(`input[name='invitees[${id}]']`).remove();
    });
    $(".player-list").on("click", ".btn-floating", (event) => {
      let id = event.currentTarget.dataset.playerId;
      let clone = $(`#player-list-item-${id}`).clone();
      $(`#player-list-item-${id}`).remove();
      clone.appendTo("#invitees");
      clone.children('.secondary-content').remove();
      clone.append(`<span class="secondary-content">
              <button class="btn-floating red waves-effect waves-light player-btn" type="button" id="player-list-${id}"
                      data-player-id="${id}">
                <i class="material-icons">clear</i>
              </button>
            </span>`);
      this.buildInput(id).appendTo('form');
    });
  }
  
  buildInput(id) {
    return $('<input>', {
    type: 'hidden',
    name: `invitees[${id}]`,
    id: id,
    value: `${id}`
    });
  }
  
  
}