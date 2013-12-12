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
  // Begin by initializing polymer.
  initPolymer();

  // Get all of our elements.
  MediaBar mediaBar = querySelector("#mediaBar");
  PlayList playlist = querySelector("#playlist");
  LibraryList library = querySelector("#library");
  TextInputElement search = querySelector("#search");

  // Connect our elements.
  new Observer(playlist, library);
  search.onInput.listen((Event e) => library.filter(search.value));

  // When polymer is done loading, we can connect the mediaBar and the
  // playlist. We have to wait for polymer to be ready just for the
  // compiled down Javascript part.
  Polymer.onReady.whenComplete((){
    mediaBar.setPlaylist(playlist);
  });
}