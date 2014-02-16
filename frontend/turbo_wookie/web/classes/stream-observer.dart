import "dart:convert";
import "dart:html";

abstract class StreamObserver {
  
  void onPlaylistUpdate();
  void onPlayerUpdate();
  void onLibraryUpdate();
  
  static List<StreamObserver> observers = new List();
  
  static void addObserver(StreamObserver o) {
    observers.add(o);
  }
  
  static void removeObserver(StreamObserver o) {
    observers.remove(o);
  }
  
  static void requestUpdate() {
    HttpRequest.request("/polar")
    .then((HttpRequest request) {
      // Reask the server for updates.
      requestUpdate();

      // Figure out what was changed.
      Map obj = JSON.decode(request.responseText);
      String changed = obj["changed"];
      print(changed);

      // Update whatever was changed if we care.
      if(changed == "playlist") {
        for(StreamObserver o in observers)
          o.onPlaylistUpdate();
      }
      if(changed == "player") {
        for(StreamObserver o in observers)
          o.onPlayerUpdate();
      }
      else if(changed == "database") {
        for(StreamObserver o in observers)
          o.onLibraryUpdate();
      }
    });    
  }
}