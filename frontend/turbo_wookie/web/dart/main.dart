import "package:polymer/polymer.dart";
import "dart:html";
import "media-bar.dart";
import "play-list.dart";
import "library-list.dart";

void main() {
  initPolymer();

  MediaBar mediaBar = querySelector("#mediaBar");
  PlayList playlist = querySelector("#playlist");
  LibraryList library = querySelector("#library");
  mediaBar.setPlayList(playlist);
  library.playlist = playlist;
}