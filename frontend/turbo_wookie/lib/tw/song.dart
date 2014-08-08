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
  String filePath;
  
  
  Song(this.artist, this.album, this.name, this.filePath);

  factory Song.fromMap(Map json) {
    var artistName = json["Artist"];
    var albumName = json["Album"];
    var name = json["Title"];
    
    var artist = new Artist(artistName, null);
    var album = new Album(albumName, artist);
    return new Song(artist, album, name, null);    
  }
  
  factory Song.fromJson(String jsonStr) {
    var json = JSON.decode(jsonStr);
    return new Song.fromMap(json);
  }

  
  static Future<List<Song>> getSongs(Library library, [Artist artist, Album album]) {    
    var artistUrl = artist != null ? "?artist=${Uri.encodeComponent(artist.name)}" : "";
    var albumUrl = album != null ? "&album=${Uri.encodeComponent(album.name)}" : "";
    var url = "/songs$artistUrl$albumUrl";
    
    return HttpRequest.request(url)
      .then((req) {
        library.songs.clear();
        var songsJson = JSON.decode(req.responseText);
        var artist = new Artist(songsJson[0]["Artist"], library);

        for(var songJ in songsJson) {
          var artist = new Artist(songJ["Artist"], library);
          var album = new Album(songJ["Album"], artist);
          var name = songJ["Title"];
          var filePath = songJ["file"];
          
          var song = new Song(artist, album, name, filePath);
          
          library.songs.add(song);
        }
      });
  }
  
}