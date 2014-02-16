library TWPlaylist;

import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "../../classes/song.dart";
import "../../classes/stream-observer.dart";

@CustomTag("tw-playlist")
class Playlist extends PolymerElement implements StreamObserver {
  Playlist.created() : super.created();
  
  @observable Song currentSong;
  @observable List<Song> songs;
  @observable String albumArtURL;
  
  void enteredView() {
    super.enteredView();
    StreamObserver.addObserver(this);
    getCurrentSong();
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
  
  void getCurrentSong([bool update = false]) {
    Song.getCurrent(update: update).then((Song song) { 
      currentSong = song;
      song.getAlbumArtURL().then((String url) => albumArtURL = url);
    });    
  }

  void onPlayerUpdate() {
    getPlaylist();
    getCurrentSong(true);
  }
  
  void onPlaylistUpdate() {}
  void onLibraryUpdate() {}
}