import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";

@CustomTag("tw-artist")
class Artist extends PolymerElement {
  Artist.created() : super.created();
  
  @published String name;
  @published String img;
  
  factory Artist.create(String name) {
    var elem = new Element.tag("tw-artist");
    elem.name = name;
    elem.setArtistArtUrl();
    return elem;
  }
  
  void attached() {
    super.attached();
  }
  
  Future<String> setArtistArtUrl() {
    var com = new Completer();
    
    HttpRequest.request("https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(name)}&format=json")
      .then((req) {
        String src;
        var obj = JSON.decode(req.responseText);
        for(var img in obj["artist"]["image"]) {
          if(img["size"] == "extralarge") {
            src = img["#text"];
            break;
          }
        }
        
        img = src;
        com.complete(src);
      });
    
    return com.future;
  }
  
  static Future<List<Artist>> getArtists() {
    var com = new Completer();
    
    HttpRequest.request("/artists")
      .then((req) {
        var artistsStr = JSON.decode(req.responseText);
        var artists = artistsStr.map((str) => new Artist.create(str));
        com.complete(artists);
      });
    
    return com.future;
  }
}