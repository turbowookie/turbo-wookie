library TWTurboWookie;

import "package:polymer/polymer.dart";
import "../../classes/stream-observer.dart";

@CustomTag("tw-turbo-wookie")
class TurboWookie extends PolymerElement {
  
  TurboWookie.created() : super.created();
  
  void enteredView() {
    super.enteredView();
    
    StreamObserver.requestUpdate();
  }
}