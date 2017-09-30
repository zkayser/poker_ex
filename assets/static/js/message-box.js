import $ from "jquery";

export default class MessageBox {
  constructor() {}
  
  static appendAndScroll(element) {
    $("#messages").append(element);
    $("#messages").scrollTop(0);
  }
}