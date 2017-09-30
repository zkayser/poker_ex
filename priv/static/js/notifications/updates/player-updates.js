import $ from "jquery";

export default class PlayerUpdates {
  constructor() {}

  static init(socket) {
    let profile = document.getElementById("player-profile");
    let playerId = profile.getAttribute("data-player-id");
    let forms = ["#name-form", "#first-name-form", "#last-name-form", "#email-form", "#blurb-form"];
    let inputIdToBtn = {
      "name": "#name-edit",
      "first-name": "#first-name-edit",
      "last-name": "#last-name-edit",
      "email": "#email-edit",
      "blurb": "#blurb-edit"
    };
    let inputIdToServAttr = {
      "#name": "name",
      "#first-name": "first_name",
      "#last-name": "last_name",
      "#email": "email",
      "#blurb": "blurb"
    };
    let dirtyFields = [];

    let channel = socket.channel(`player_updates:${playerId}`);
    channel.join()
    .receive("ok", resp => {
      console.log("Successfully connected to player_updates channel for player with ID: ", playerId);
    })
    .receive("error", reason => {
      console.log("Could not join player_updates channel for reason:\n ", reason);
    });

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

        // Return if the input field has not been touched
        if (!(dirtyFields.includes(form.replace("-form", "").replace("#", "")))) {
          return;
        }

        let btn = form.replace("-form", "-edit");
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
    const USERNAME = $("#player-name-info");
    const FIRST_NAME = $("#player-first-name-info");
    const LAST_NAME = $("#player-last-name-info");
    const EMAIL = $("#player-email-info");
    const CHIPS = $("#player-chips-info");
    const BLURB = $("#player-blurb-info");

    switch (player.update_type) {
      case "name":
        PlayerUpdates.updateEl(USERNAME, player.name, "#name");
        break;
      case "first_name":
        PlayerUpdates.updateEl(FIRST_NAME, player.first_name, "#first-name");
        break;
      case "last_name":
        PlayerUpdates.updateEl(LAST_NAME, player.last_name, "#last-name");
        break;
      case "email":
        PlayerUpdates.updateEl(EMAIL, player.email, "#email");
        break;
      case "blurb":
        PlayerUpdates.updateEl(BLURB, player.blurb, "#blurb");
        break;
      case "chips":
        PlayerUpdates.updateEl(CHIPS, player.chips, "#chips");
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
