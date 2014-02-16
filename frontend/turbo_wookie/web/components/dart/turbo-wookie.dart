library TWTurboWookie;

import "package:polymer/polymer.dart";
import "library.dart";
import "playlist.dart";
import "../../classes/stream-observer.dart";

@CustomTag("tw-turbo-wookie")
class TurboWookie extends PolymerElement {
  
  TurboWookie.created() : super.created();
  
  void enteredView() {
    super.enteredView();
    
    StreamObserver.requestUpdate();
    Playlist p = $["playlist"];
    Library l = $["library"];
    p.library = l;
  }
}