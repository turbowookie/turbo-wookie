import "package:polymer/polymer.dart";

import "dart:async";
import "dart:convert";
import "dart:html";
import "album.dart";
import "artist.dart";
import "song.dart";

@CustomTag("tw-playlist")
class Playlist extends PolymerElement {
  Playlist.created() : super.created();
  
  @observable List<Song> upcoming;
  @observable Song current;
  
  void attached() {
    super.attached();
    
    getUpcoming().then((songs) => upcoming = songs.toList());
    getCurrent().then((song) => current = song);
  }
  
  Future<List<Song>> getUpcoming() {
    var com = new Completer();
    
    HttpRequest.request("/upcoming")
    .then((req) {
      var json = JSON.decode(req.responseText);
      var songs = [];
      for(var songMap in json) {
        songs.add(new Song.fromMap(songMap));
      }
      
      com.complete(songs);
    });
    
    return com.future;
  }
  
  Future<Song> getCurrent() {
    var com = new Completer();
    
    HttpRequest.request("/current")
    .then((req) {
      var song = new Song.fromJson(req.responseText);
      com.complete(song);
    });
    
    return com.future;
  }
}