import "dart:html";
import "package:polymer/polymer.dart";
import "media-bar.dart";
import "play-list.dart";
import "library-list.dart";

/**
 * The main method that kicks everything off.
 */
void main() {
  initPolymer();

  MediaBar mediaBar = querySelector("#mediaBar");
  PlayList playlist = querySelector("#playlist");
  LibraryList library = querySelector("#library");
  mediaBar.setPlayList(playlist);
  library.playlist = playlist;
}