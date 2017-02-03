import $ from "jquery";

export default class PlayerUpdates {
  constructor() {
    
  }
  
  static init(channel) {
    let forms = ["#name-form", "#first-name-form", "#last-name-form", "#email-form"];
    
    let inputIdToBtn = {
      "name": "#name-edit",
      "first-name": "#first-name-edit",
      "last-name": "#last-name-edit",
      "email": "#email-edit"
    };
    
    let inputIdToServAttr = {
      "#name": "name",
      "#first-name": "first_name",
      "#last-name": "last_name",
      "#email": "email"
    };
    
    let dirtyFields = [];
    
    document.addEventListener("input", (e) => {
      if (!(Object.keys(inputIdToBtn).includes(e.target.id))) {return}
      else {
        $(inputIdToBtn[e.target.id]).removeClass("disabled");
        dirtyFields.push(e.target.id);
      }
    });
    
    forms.forEach((form) => {
      $(form).submit((e) => {
        e.preventDefault();
        
        console.log("form submit: ", e);
        
        // Return if the input field has not been touched
        if (!(dirtyFields.includes(form.replace("-form", "").replace("#", "")))) {
          return;
        }
        
        let btn = form.replace("form", "-edit");
        let inputId = form.replace("-form", "");
        let value = $(inputId)[0].value;
        let pushParams = new Object();
        
        pushParams[inputIdToServAttr[inputId]] = value;
        channel.push("player_update", pushParams)
        .receive("ok", (player) => {
          PlayerUpdates.updatePlayerInfo(player);
          $(btn).addClass("disabled");
          dirtyFields.indexOf(inputId.replace("#", ""));
          dirtyFields.splice(inputId.replace("#", ""));
        })
        .receive("error", (errors) => {
          console.log("errors: ", errors);
        });
      });
    });
    
    $("#chip-edit").click(() => {
      console.log("#chip-edit button pressed");
      channel.push("player_update", {chips: 1000})
      .receive("ok", (player) => {
        PlayerUpdates.updatePlayerInfo(player);
        $("#chip-edit").remove();
      })
      .receive("error", (resp) => {
        window.Materialize.toast(resp.message, 2000);
        $("#chips-header").click();
      });
    });
  }
  
  static updatePlayerInfo(player) {
    const userName = $("#player-name-info");
    const firstName = $("#player-first-name-info");
    const lastName = $("#player-last-name-info");
    const email = $("#player-email-info");
    const chips = $("#player-chips-info");
    
    switch (player.update_type) {
      case "name": 
        PlayerUpdates.updateEl(userName, player.name, "#name");
        break;
      case "first_name":
        PlayerUpdates.updateEl(firstName, player.first_name, "#first-name");
        break;
      case "last_name": 
        PlayerUpdates.updateEl(lastName, player.last_name, "#last-name");
        break;
      case "email":
        PlayerUpdates.updateEl(email, player.email, "#email");
        break;
      case "chips":
        PlayerUpdates.updateEl(chips, player.chips, "#chips");
        break;
      default:
        break;
    }
  }
  
  static updateEl(el, text, prefix) {
    el.empty().text(text);
    $(`${prefix}-header`).click();
    window.Materialize.toast("Successfully updated", 2000);
  }
}