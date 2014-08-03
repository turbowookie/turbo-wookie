import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "album.dart";
import "artist.dart";

@CustomTag("tw-song")
class Song extends PolymerElement {
  Song.created() : super.created();
  
  @published Artist artist;
  @published Album album;
  @published String name;
  
  
  factory Song(Artist artist, Album album, String name) {
    var elem = new Element.tag("tw-song");
    elem.artist = artist;
    elem.album = album;
    elem.name = name;
    
    return elem;
  }
  
  static Future<List<Song>> getSongs(Artist artist) {
    var com = new Completer();
    HttpRequest.request("/songs?artist=${Uri.encodeComponent(artist.name)}")
      .then((req) {
        var songsJson = JSON.decode(req.responseText);
        var songs = [];
        for(var songJ in songsJson) {
          var artist = new Artist(songJ["Artist"]);
          var album = new Album(songJ["Album"], artist);
          var name = songJ["Title"];
          var song = new Song(artist, album, name);
          
          songs.add(song);
        }
        
        com.complete(songs);
      });
    
    return com.future;
  }
  
}