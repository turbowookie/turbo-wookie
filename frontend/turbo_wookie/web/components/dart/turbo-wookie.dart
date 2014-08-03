library TWTurboWookie;

import "dart:html";
import "package:polymer/polymer.dart";
import "library.dart";
import "playlist.dart";
import "views.dart";
import "../../classes/stream-observer.dart";

/**
 * Turbo Wookie!
 * 
 * This class puts all the elements of Turbo Wookie together.
 */
@CustomTag("tw-turbo-wookie")
class TurboWookie extends PolymerElement {
  
  TurboWookie.created() : super.created();
  
  void attached() {
    super.attached();
    
    // Start requesting updates from the server.
    StreamObserver.requestUpdate();
    
    // Get our objects.
    Playlist playlist = $["playlist"];
    Library library = $["library"];
    Views views = $["views"];
    InputElement search = $["search"];
    
    // Connect things.
    playlist.library = library;
    views.library = library;
    library.views = views;
    
    search.onInput.listen((e) {
      library.search(search.value);
    });
  }
}