library LoginMenu;

import "dart:html";
import "package:polymer/polymer.dart";

@CustomTag("login-menu")
class LoginMenu extends PolymerElement {
  
  LoginMenu.created() : super.created();
  
  void enteredView() {
    this.style.display = "none";
  }
}