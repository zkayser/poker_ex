import $ from 'jquery';

export default class PlayerChipComponent {
  
  constructor(data) {
    this.playerInfo = data.chip_roll;
    this.appendTarget = $("#participant-info");
  }
  
  init() {
    this.addInfoToList();
  }
  
  update(data) {
    this.playerInfo = data.chip_roll;
    this.addInfoToList();
  }
  
  addInfoToList() {
    this.appendTarget.empty();
    Object.keys(this.playerInfo).forEach((player) => {
      this.appendTarget.append(this.listItemMarkup({
        name: player,
        chips: this.playerInfo[player]
      }));
    });
  }
  
  listItemMarkup(playerInfo) {
    return $(`
      <li class="collection-item" id="${playerInfo.name}-participant-item">
        ${playerInfo.name} <span class="secondary-content" id="${playerInfo.name}-active-chips">${playerInfo.chips}</span>
      </li>
    `);
  }
  
  
}