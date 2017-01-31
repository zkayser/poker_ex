import $ from 'jquery';

export default class MainView {
  mount() {
    console.log("MainView mounted");
    
    // Dismisses any flash alerts
      if ($(".alert-info").text().trim().length || $(".alert-danger").text().trim().length) {
	      setTimeout(() => {
		      $(".alert").fadeOut(500, () => {
			    $(".alert").css({"visibility": "hidden", display: "block"}).slideUp();
		    });
	    }, 5000);
    }
  }
  
  unmount() {
    console.log("MainView unmounted");
  }
}