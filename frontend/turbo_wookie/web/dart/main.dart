import "package:polymer/polymer.dart";
import "package:json_object/json_object.dart";
import "dart:html";
import "media-bar.dart";
import "play-list.dart";

void main() {
  initPolymer();

  MediaBar mediaBar = querySelector("#mediaBar");
  PlayList playlist = querySelector("#playlist");
  mediaBar.playlist = playlist;
}