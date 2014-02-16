library Playlist;

import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "../../classes/song.dart";

@CustomTag("tw-playlist")
class Playlist extends PolymerElement {
  Playlist.created() : super.created();
  
  @observable Song currentSong;
  @observable List<Song> songs;
  @observable String albumArtURL;
  
  void enteredView() {
    Song.getCurrent().then((Song song) { 
      currentSong = song;
      song.getAlbumArtURL().then((String url) => albumArtURL = url);
    });
    
    getPlaylist();
  }
  
  void getPlaylist() {
    HttpRequest.request("/upcoming").then((HttpRequest request) {
      songs = new List<Song>();
      List jsonList = JSON.decode(request.responseText);
      
      for(Map songMap in jsonList) {
        songs.add(new Song.fromMap(songMap));
      }
    });
  }
}