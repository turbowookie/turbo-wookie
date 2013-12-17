library Observer;
import "dart:convert";
import "dart:html";
import "play-list.dart";
import "library-list.dart";

/**
 * A class that will ask the server for updates and respond.
 */
class Observer {

  PlayList playlist;
  LibraryList library;

  /**
   * Create an [Observer].
   */
  Observer(this.playlist, this.library) {
    requestUpdate();
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
  void requestUpdate() {
    HttpRequest.request("/polar")
    .then((HttpRequest request) {
      // Reask the server for updates.
      requestUpdate();

      // Figure out what was changed.
      Map obj = JSON.decode(request.responseText);
      String changed = obj["changed"];

      // Update whatever was changed if we care.
      if(changed == "playlist")
        updatePlaylist();
      else if(changed == "database")
        updateLibrary();
    });
  }

  /**
   * Tell the [PlayList] to update.
   */
  void updatePlaylist() {
    playlist.getPlaylist();
  }

  /**
   * Tell the [LibraryList] to update.
   */
  void updateLibrary() {
    library.getAllSongs();
  }
}