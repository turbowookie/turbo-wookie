library TurboWookie.Library;

import "package:polymer/polymer.dart";
import "artist.dart";

@CustomTag("tw-library")
class Library extends PolymerElement {
  Library.created() : super.created();
  
  @observable List<Artist> artists;
  
  void attached() {
    super.attached();
    artists = new List();
  }
}