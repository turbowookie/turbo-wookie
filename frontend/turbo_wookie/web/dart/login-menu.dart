library LoginMenu;

import "dart:html";
import "package:polymer/polymer.dart";

@CustomTag("login-menu")
class LoginMenu extends PolymerElement {
  FormElement loginForm;
  InputElement user;
  InputElement pass;
  DivElement loginFailed;
  
  LoginMenu.created() : super.created();
  
  void enteredView() {
    this.style.display = "none";
    loginForm = $["loginForm"];
    user = loginForm.querySelector("#user");
    pass = loginForm.querySelector("#pass");
    loginFailed = $["loginFailed"];
    loginFailed.style.display = "none";
  }
  
  void login(Event e) {
    e.preventDefault();
    
    //TODO Make secure, because everyone wants Turbo Wookie passwords!!
    HttpRequest.request("/login?user=${user.value}&pass=${pass.value}")
    .then((HttpRequest request) {
      loginFailed.style.display = "none";
      this.style.display = "none";
    },
    onError: (HttpRequest request) {
      loginFailed.style.display = "block";
    });
  }
  
  /**
   * If the user is in an input element.
   */
  bool isInput() {
    try {
    return shadowRoot.activeElement.tagName == "INPUT";
    } catch(exception) {
      // This happens when the shadow root has no active element.
      return false;
    }
  }
}