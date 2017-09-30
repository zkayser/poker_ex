import OnlineView from '../online-view';
import PlayerSearchComponent from '../../components/player-search-component';
import PaginationBase from '../../components/pagination-base';
import PlayerListComponent from '../../components/player-list-component';

import $ from 'jquery';

export default class PrivateRoomNewView extends OnlineView {
  
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
      this.invited ? this.invited-- : this.invited = 0; 
    });
    $(".player-list").on("click", ".btn-floating", (event) => {
      this.invited ? this.invited : this.invited = 1;
      if (this.invited <= 6) {
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
        this.invited++;  
      } else {
        window.Materialize.toast('You can only add up to 6 invitees', 3000, 'red-toast'); 
      }
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