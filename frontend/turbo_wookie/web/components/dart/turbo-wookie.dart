library TWTurboWookie;

import "package:polymer/polymer.dart";
import "library.dart";
import "playlist.dart";
import "views.dart";
import "../../classes/stream-observer.dart";

@CustomTag("tw-turbo-wookie")
class TurboWookie extends PolymerElement {
  
  TurboWookie.created() : super.created();
  
  void enteredView() {
    super.enteredView();
    
    // Start requesting updates from the server.
    StreamObserver.requestUpdate();
    
    // Get our objects.
    Playlist playlist = $["playlist"];
    Library library = $["library"];
    Views views = $["views"];
    
    // Connect things.
    playlist.library = library;
    views.library = library;
    library.views = views;
  }
}