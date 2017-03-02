import $ from 'jquery';
import PaginationUtils from './pagination-utils';

export default class PlayerListComponent {
  
  constructor(totalPages, player) {
    this.paginationUtils = new PaginationUtils({totalPages: totalPages});
    this.player = player;
  }
  
  init() {
    this.setEventListeners();
  }
  
  update(players) {
    this.players = players;
    this.clearList();
    this.render(players);
  }
  
  render(players) {
    const colors = this.colors();
    for (let i = 0; i < players.length; i++) {
      let colorIndex;
      i < colors.length ? colorIndex = i : colorIndex = players.length % colors.length;
      let element = this.buildListMarkup(players[i], colors[colorIndex]);
      this.appendToList(element);
    }
    this.setButtonEvents();
  }
  
  getPage({pageNum, player}) {
    $.ajax({
      type: 'GET',
      url: `../../api/list/${player}/${pageNum}`,
      dataType: 'json',
      success: (data, textStatus, req) => {
        this.update(data);
      },
      error: (req, textStatus, errorThrown) => {
        console.log('ERROR: req, textStatus, errorThrown: ', req, textStatus, errorThrown);
      }
    });
  }
  
  setEventListeners() {
    let current = this.paginationUtils.currentPage;
    let total = this.paginationUtils.totalPages;
    let pageUp = current + 1;
    let pageBack = current - 1;
    let elems = this.paginationUtils.getPageElements();
    $("#page-ahead").on('click', (e) => {
      if (current < total) {
        this.getCallBack(pageUp);
      }
    });
    $("#page-back").on('click', (e) => {
      if (current > 1) {
        this.getCallBack(pageBack); 
      }
    });
    elems.forEach((elem) => {
      elem.on('click', () => {
        let id = elem.attr("id").split("-")[1];
        this.getCallBack(id);
      });
    });
  }
  
  detachEventListeners() {
    $("#page-ahead").off('click');
    $("#page-back").off('click');
  }
  
  getCallBack(pageNum) {
    this.getPage({pageNum: pageNum, player: this.player});
    this.detachEventListeners();
    this.paginationUtils.update(pageNum, this);
  }
  
  colors() {
    return ["purple", "teal", "red", "blue", "yellow", "green"];
  }
  
  buildListMarkup(player, color) {
    return $(`
    <li class="collection-item avatar player-list-item" id="player-list-item-${player.id}" data-player-id="${player.id}">
    <div class="row">
      <div class="col s12 m2 center-align player-icon">
        <i class="material-icons medium ${color}-text">person</i>
      </div>
      <div class="col s12 m6 offset-m1 center-align player-icon">
        <p class="left user-info">User: ${player.name.charAt(0).toLowerCase() + player.name.slice(1) }</p><br>
        <p class="left user-info blurb">${player.blurb.charAt(0).toUpperCase() + player.blurb.slice(1) }</p>
      </div>
      <div class="col s12 m2 offset-m1 center-align player-icon">
        <span class="secondary-content center-align">
          <button class="btn-floating green lighten-2 waves-effect waves-light player-btn" type="button" id="player-${player.id}"
                data-player-id="${player.id}">
            <i class="material-icons">plus_one</i>
          </button>
        </span>
      </div>
    </div>
    `);
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
  
  clearList() {
    $("#browse-players-list").empty();
  }
  
  appendToList(element) {
    $("#browse-players-list").append(element);
  }
}