library TWSong;

import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "../classes/lastfm.dart";

class Song {
  static Future<Song> get currentSong => Song.getCurrent();
  static Song _currSong;
  
  @observable String title;
  @observable String artist;
  @observable String album;
  String filePath;
  double length;
  
  Song(this.title, this.artist, this.album);
  
  Song.fromMap(Map map) {
    if(map.containsKey("Title"))
      title = map["Title"];
    else
      title = "";

    if(map.containsKey("Artist"))
      artist = map["Artist"];
    else
      artist = "";

    if(map.containsKey("Album"))
      album = map["Album"];
    else
      album = "";

    if(map.containsKey("Time"))
      length = map["Time"];
    else
      length = 0.0;

    if(map.containsKey("file")) {
      filePath = map["file"];
    }
  }
  
  factory Song.fromJson(String json) {
    Map map = JSON.decode(json);
    return new Song.fromMap(map);
  }
  
  static Future<Song> getCurrent({bool update}) {
    Completer com = new Completer();
    
    if(_currSong == null || update) {
      HttpRequest.request("/current")
        .then((HttpRequest request) {
          _currSong = new Song.fromJson(request.responseText);
          com.complete(currentSong);
        });
    }
    
    else {
      com.complete(_currSong);
    }
    
    return com.future;
  }
  
  Future<String> getAlbumArtURL() {
    return LastFM.getAlbumArtUrl(this);
  }
  
  void addToPlaylist() {
    HttpRequest.request("add?song=${Uri.encodeComponent(filePath)}");
  }
  
  String toString() {
    return "Title : $title\n"
        "Artist: $artist\n"
        "Album : $album\n";
  }
}