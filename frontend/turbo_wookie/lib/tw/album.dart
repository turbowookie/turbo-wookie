library TurboWookie.Album;

import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "artist.dart";
import "library.dart";

@CustomTag("tw-album")
class Album extends PolymerElement {
  Album.created() : super.created();
  
  static Library library;
  @published String name;
  @published Artist artist;
  @published String img;
  
  void attached() {
    super.attached();
  }
  
  factory Album(String name, Artist artist) {
    var elem = new Element.tag("tw-album");
    elem.name = name;
    elem.artist = artist;
    elem.setAlbumArt();
    
    return elem;
  }
  
  void setAlbumArt() {
    var com = new Completer();
    
    HttpRequest.request("http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(artist.name)}&album=${Uri.encodeComponent(name)}&format=json")
      .then((req) {
        String src;
        var obj = JSON.decode(req.responseText);
        
        for(var img in obj["album"]["image"]) {
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
  
  static Future<List<Album>> getAlbums([Artist artist]) {
    var com = new Completer();
    var url = "/albums" + (artist != null ? "?artist=${Uri.encodeComponent(artist.name)}" : "");
    print(url);
    HttpRequest.request(url)
      .then((req) {
        var albumsJson = JSON.decode(req.responseText);
        var albums = [];
        
        // If an artists was specified
        if(artist != null) {
          for(var album in albumsJson[artist.name]) {
            albums.add(new Album(album, artist));
          }
        }
        // All artists
        else {
          for(var artistName in albumsJson.keys) {
            for(var album in albumsJson[artistName]) {
              albums.add(new Album(album, new Artist(artistName)));
            }
          }
        }
        
        com.complete(albums);
      });
    
    return com.future;
  }
}