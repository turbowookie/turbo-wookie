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
    
    artists.add(new Artist("Front Porch Step", "http://userserve-ak.last.fm/serve/500/97508231/Front+Porch+Step++2014.jpg"));
    artists.add(new Artist("A Day to Remember", "http://userserve-ak.last.fm/serve/500/97508231/Front+Porch+Step++2014.jpg"));
  }
}