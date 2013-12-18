library HeaderBar;

import "dart:html";
import "package:polymer/polymer.dart";
import "library-list.dart";
import "login-menu.dart";

@CustomTag("header-bar")
class HeaderBar extends PolymerElement {
  TextInputElement search;
  ButtonElement login;
  LoginMenu loginMenu;
  
  HeaderBar.created() : super.created();
  
  void enteredView() {
    search = $["search"];
    login = $["login"];
    
    setupEvents();
  }
  
  void setupEvents() {
    login.onClick.listen((Event e) {
      if(loginMenu.style.display == "none")
        loginMenu.style.display = "block";
      else
        loginMenu.style.display = "none";
    });
  }
  
  void setLibrary(LibraryList library) {
    search.onInput.listen((Event e) => library.filter(search.value));    
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