import $ from 'jquery';

export default class ChatComponent {
  constructor(player, channel) {
    this.player = player;
    this.channel = channel;
    this.input = $("#chat-input");
    this.chatBtn = $("#chat-btn");
    this.chatCollection = $("#chat-collection");
  }
  
  init() {
    this.chatBtn.on('click', () => {
      this.submit();
    });
    this.input.on('keyup', (e) => {
      if (e.keyCode == 13) {
        this.submit();
      }
    });
  }
  
  update(message) {
    let markup = this.chatMessage(message.name, message.text);
    console.log("markup: ", markup);
    markup.prependTo(this.chatCollection);
  }
  
  submit() {
    let input = this.input.val();
    input = this.esc(input);
    this.channel.push("chat_message", {input: input});
    this.input.val('');
  }
  
  esc(str) {
    let div = document.createElement("div");
    div.appendChild(document.createTextNode(str));
    return div.innerHTML;
  }
  
  chatMessage(name, text) {
    if (name == this.player) {
      return $(`<li class="collection-item"><strong class="green-text">${name}: </strong>${text}</li>`);
    } else {
      return $(`<li class="collection-item"><strong class="indigo-text">${name}: </strong>${text}</li>`); 
    }
  }
}