import "dart:convert";
import "dart:html";

/**
 * A class that will ask the server for updates and respond.
 */
abstract class StreamObserver {
  
  /**
   * Called when the playlist is updated.
   */
  void onPlaylistUpdate();
  
  /**
   * Called when the player is updated.
   */
  void onPlayerUpdate();
  
  /**
   * Called when the library is updated.
   */
  void onLibraryUpdate();
  
  static List<StreamObserver> observers = new List();
  
  /**
   * Add an observer to be notified when things are updated.
   */
  static void addObserver(StreamObserver o) {
    observers.add(o);
  }
  
  /**
   * Removes an observer.
   */
  static void removeObserver(StreamObserver o) {
    observers.remove(o);
  }
  
  /**
   * Send a request to the server with the path of `/polar` (because of bears).
   * The server will wait until it has an update to send to the client, then it
   * will send us a message saying something changed. If we care about this
   * change, we will do something about it, otherwise we won't.
   *
   * This function calls itself as soon as we get a change, in order to keep
   * listening to the server for changes.
   */
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