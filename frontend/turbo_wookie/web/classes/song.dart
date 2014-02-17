library TWSong;

import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "../classes/lastfm.dart";

/**
 * A song is a class that groups together data about a song.
 */
class Song {
  static Future<Song> get currentSong => Song.getCurrent();
  static Song _currSong;
  
  @observable String title;
  @observable String artist;
  @observable String album;
  String filePath;
  double length;
  
  /**
   * Create a [Song] using [String]s.
   */
  Song(this.title, this.artist, this.album);
  
  /**
   * Create a [Song] using a [Map].
   *
   * The map should have these fields:
   * * Title
   * * Artist
   * * Album
   * * Time
   * * File
   */
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
  
  /**
   * Create a song from a string of json.
   */
  factory Song.fromJson(String json) {
    Map map = JSON.decode(json);
    return new Song.fromMap(map);
  }
  
  /**
   * This returns the currently playing song in a Future.
   * 
   * If update is true, it will update the current song.
   */
  static Future<Song> getCurrent({bool update: false}) {
    Completer com = new Completer();
    
    // If we don't have the current song, request it and return it.
    if(_currSong == null || update) {
      HttpRequest.request("/current")
        .then((HttpRequest request) {
          _currSong = new Song.fromJson(request.responseText);
          com.complete(currentSong);
        });
    }
    
    // If we already have the current song, just return it.
    else {
      com.complete(_currSong);
    }
    
    return com.future;
  }
  
  /**
   * Grabs the album art for this song.
   */
  Future<String> getAlbumArtURL() {
    return LastFM.getAlbumArtUrl(this);
  }
  
  /**
   * Adds this song to the playlist.
   */
  void addToPlaylist() {
    HttpRequest.request("add?song=${Uri.encodeComponent(filePath)}");
  }

  String toString() {
    return "Title : $title\n"
        "Artist: $artist\n"
        "Album : $album\n";
  }
}