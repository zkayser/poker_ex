import $ from "jquery";

export default class Signup {
  constructor() {}
  
  static fadeOnSignin() {
    $(".signup").fadeOut(400, () => {
        $(".card-table").addClass("slide-onscreen-right");
      });
      $(".login-spinner").removeClass("active"); 
  } 
}