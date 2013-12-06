library Observer;
import "dart:convert";
import "dart:html";
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

      Map obj = JSON.decode(request.responseText);
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