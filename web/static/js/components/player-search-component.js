import $ from 'jquery';
import {Socket} from 'phoenix';

export default class PlayerSearchComponent {
  constructor() {
    this.list = $("#search-players-list");
    this.input = $("#players-search");
    this.searchResults = $("#search-results");
    this.submitBtn = $("#search-btn");
    this.removeEventAdded = false;
  }
  
  init() {
    let socket = new Socket('/socket', {params: {token: window.playerToken}});
    socket.connect();
    
    this.channel = socket.channel('online:search');
    this.channel.join()
    .receive('ok', () => {console.log('joined online:search')})
    .receive('error', () => {console.log('could not join online:search')});
    this.setEventListeners();
  }
  
  setEventListeners() {
    this.submitBtn.on('click', (e) => {
      this.submitHandler();
    });
    this.input.on('keypress', (e) => {
      if (e.keyCode == 13) {
        this.submitHandler();
      }
    });
  }
  
  submitHandler() {
    let val = this.input.val();
    this.channel.push('player_search', {value: val})
    .receive('ok', ({results}) => {
      if (Object.keys(results).length == 0) {
        window.Materialize.toast(`No results found for ${val}`, 3000, 'red-toast');
      } else {
        this.appendItems(results);
      }
    });
    this.input.val('');
  }
  
  appendItems(players) {
    $("#search-results").empty();
    let colors = ['purple', 'teal', 'red', 'blue', 'yellow', 'green'];
    for (let i = 0; i < players.length; i++) {
      let cIndex;
      if (i > 5) {
        cIndex = i % 5;
      } else {
        cIndex = i;
      }
      let player = players[i];
      let color = colors[cIndex];
      let markupOpts = {
        id: player.id,
        name: player.name,
        blurb: player.blurb,
        color: color,
        btnColor: 'green',
        icon: 'plus_one'
      };
      let markup = this.listElMarkup(markupOpts);
      this.searchResults.append(markup);
      $(".search-list-btn").on('click', (e) => {
        let id = e.currentTarget.dataset.playerId;
        this.maybeAppendToInvitees(id);
        this.addRemoveEvent({name: player.name, id: player.id, blurb: player.blurb, color: color});
      });
    }
  }
  
  maybeAppendToInvitees(id) {
    if ($(`#invitees`).find(`#player-list-item-${id}`).length > 0) {
      window.Materialize.toast('Player has already been added to invitee list', 3000, 'red-toast');
      return;
    } else {
      let clone = $(`#player-list-item-${id}`).clone();
      if (`#player-list-item-${id}`) {
          $(`#player-list-item-${id}`).remove();
        }
      clone.appendTo("#invitees");
      clone.children('.secondary-content').remove();
      clone.append(this.removeButtonMarkup());
      this.buildInput(id).appendTo('form'); 
    }
  }
  
  addRemoveEvent(playerData) {
    $("#invitees").on("click", ".btn-floating", (event) => {
      let markup = this.listElMarkup(Object.assign(playerData, {btnColor: 'green', icon: 'plus_one'}));
      if ( $(`#player-list-item-${playerData.id}`)) {
        $(`#player-list-item-${playerData.id}`).remove(); 
      }
      markup.appendTo('.player-list');
      $(`input[name='invitees[${playerData.id}]']`).remove();
    });
  }
  
  listElMarkup(opts) {
    return $(
      `
       <li class="collection-item avatar player-list-item" id="player-list-item-${opts.id}" data-player-id="${opts.id}">
        <div class="row">
          <div class="col s12 m2 center-align player-icon">
          <i class="material-icons medium ${opts.color}-text">person</i>
        </div>
        <div class="col s12 m6 offset-m1 center-align player-icon">
          <p class="left user-info">User: ${opts.name}</p><br>
          <p class="left user-info blurb">${opts.blurb}</p>
        </div>
        <div class="col s12 m2 offset-m1 center-align player-icon">
          <span class="secondary-content center-align">
            <button class="btn-floating ${opts.btnColor} lighten-2 waves-effect waves-light search-list-btn player-btn" type="button" id="player-${opts.id}"
                data-player-id="${opts.id}">
              <i class="material-icons">${opts.icon}</i>
            </button>
          </span>
        </div>
      </div>
    </li>
      `  
    );
  }
  
  removeButtonMarkup(id) {
    return $(`
      <span class="secondary-content">
        <button class="btn-floating red waves-effect waves-light player-btn" type="button" id="player-list-${id}"
            data-player-id="${id}">
          <i class="material-icons">clear</i>
        </button>
      </span>
    `);
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