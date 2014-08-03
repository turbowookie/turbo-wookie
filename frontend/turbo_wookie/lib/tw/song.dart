library TurboWookie.Song;

import "dart:async";
import "dart:convert";
import "dart:html";
import "album.dart";
import "artist.dart";
import "library.dart";

class Song {
  
  Artist artist;
  Album album;
  String name;
  
  
  Song(this.artist, this.album, this.name);
  
  static Future<List<Song>> getSongs(Library library, [Artist artist]) {
    var com = new Completer();
    HttpRequest.request("/songs?artist=${Uri.encodeComponent(artist.name)}")
      .then((req) {
        var songsJson = JSON.decode(req.responseText);
        var songs = [];
        for(var songJ in songsJson) {
          var artist = new Artist(songJ["Artist"], library);
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