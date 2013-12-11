import "package:polymer/polymer.dart";
import "dart:async";
import "dart:html";
import "media-bar.dart";
import "play-list.dart";
import "library-list.dart";
import "observer.dart";

/**
 * The main method that kicks everything off.
 */
void main() {
  initPolymer();
  MediaBar mediaBar = querySelector("#mediaBar");
  PlayList playlist = querySelector("#playlist");
  LibraryList library = querySelector("#library");
  TextInputElement search = querySelector("#search");
  new Observer(playlist, library);

  search.onInput.listen((Event e) => library.filter(search.value));

  Polymer.onReady.whenComplete((){
    mediaBar.setPlaylist(playlist);
    library.style.setProperty("background", library.style.backgroundColor);
  });
}