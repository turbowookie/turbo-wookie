import "package:polymer/polymer.dart";
import "dart:async";
import "dart:html";
import "media-bar.dart";
import "play-list.dart";
import "library-list.dart";
import "header-bar.dart";
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
  HeaderBar header = querySelector("#header");

  // Connect our elements.
  new Observer(playlist, library);

  // When polymer is done loading, we can connect the mediaBar and the
  // playlist. We have to wait for polymer to be ready just for the
  // compiled down Javascript part.
  Polymer.onReady.whenComplete((){
    mediaBar.setPlaylist(playlist);
    mediaBar.setHeader(header);
    header.setLibrary(library);
  });
}