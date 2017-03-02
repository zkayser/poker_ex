import MainView from '../main-view';
import Online from '../online';
import PlayerSearchComponent from '../../components/player-search-component';
import PaginationUtils from '../../components/pagination-utils';
import PlayerListComponent from '../../components/player-list-component';

import $ from 'jquery';

export default class PrivateRoomNewView extends MainView {
  
  constructor() {
    super();
    this.playerList = document.getElementsByClassName('player-list')[0];
    this.invitees = document.getElementById("invitees");
    this.totalPages = $(".pagination").data("totalPages");
    this.player = $("#browse-players-list").data("currentPlayer");
  }
  
  mount() {
    super.mount();
    console.log("PrivateRoomNewView mounted");
    
    this.setButtonEvents();
    let playerSearch = new PlayerSearchComponent();
    playerSearch.init();
    
    
    let playerListComponent = new PlayerListComponent(this.totalPages, this.player);
    playerListComponent.init();
    
    Online.init();
  }
  
  unmount() {
    super.unmount();
    console.log("PrivateRoomNewView unmounting...");
  }
  
  
  setButtonEvents() {
    $("#invitees").off("click", ".btn-floating");
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