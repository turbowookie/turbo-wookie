library TurboWookie;
import "dart:html";
import "dart:async";
import "package:polymer/polymer.dart";
import "package:range_slider/range_slider.dart";
import "package:json_object/json_object.dart";

part "song.dart";
part "current-song.dart";
part "media-bar.dart";
part "play-list.dart";
part "library-list.dart";

void main() {
  initPolymer();

  MediaBar mediaBar = querySelector("#mediaBar");
  PlayList playlist = querySelector("#playlist");
  LibraryList library = querySelector("#library");
  mediaBar.setPlayList(playlist);
  library.playlist = playlist;
}