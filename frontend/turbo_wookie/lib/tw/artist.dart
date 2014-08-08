library TurboWookie.Artist;

import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "library.dart";

@CustomTag("tw-artist")
class Artist extends PolymerElement {
  Artist.created() : super.created();
  
  @published String name;
  @published String img;
  @published Library library;
  
  factory Artist(String name, Library library) {
    var elem = new Element.tag("tw-artist");
    elem.name = name;
    elem.library = library;
    elem.setArtistArtUrl();
    
    return elem;
  }
  
  void attached() {
    super.attached();
    onClick.listen((e) {
      library.showAlbums(artist: this);
    });
  }
  
  Future<String> setArtistArtUrl() {
    var com = new Completer();
    
    HttpRequest.request("https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(name)}&format=json")
    .then((req) {
      var src = "packages/tw/images/wookie.jpg";
      var obj = JSON.decode(req.responseText);
      
      if(obj["artist"] != null && obj["artist"]["image"] != null) {
        for(var img in obj["artist"]["image"]) {
          if(img["size"] == "extralarge") {
            src = img["#text"];
            break;
          }
        }
      }

      img = src;
      com.complete(src);
    });
    
    return com.future;
  }
  
  static Future<List<Artist>> getArtists(Library library) {
    return HttpRequest.request("/artists")
      .then((req) {
        library.artists.clear();
        var artistsJson = JSON.decode(req.responseText);
        for(var a in artistsJson) {
          var artist = new Artist(a, library);
          library.artists.add(artist);
        }
      });
  }
}