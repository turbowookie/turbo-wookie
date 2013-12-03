library Observer;
import "dart:html";
import "package:json_object/json_object.dart";
import "play-list.dart";
import "library-list.dart";

class Observer {

  PlayList playlist;
  LibraryList library;

  Observer(this.playlist, this.library) {
    requestUpdate();
  }

  void requestUpdate() {
    HttpRequest.request("/polar")
    .then((HttpRequest request) {
      requestUpdate();

      JsonObject obj = new JsonObject.fromJsonString(request.responseText);
      String changed = obj["changed"];
      if(changed == "playlist")
        updatePlaylist();
      else if(changed == "library")
        updateLibrary();
    });
  }

  void updatePlaylist() {
    playlist.getPlaylist();
  }

  void updateLibrary() {
    library.getAllSongs();
  }
}