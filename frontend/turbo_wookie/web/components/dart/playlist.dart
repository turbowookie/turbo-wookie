library TWPlaylist;

import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "library.dart";
import "../../classes/song.dart";
import "../../classes/stream-observer.dart";

@CustomTag("tw-playlist")
class Playlist extends PolymerElement implements StreamObserver {
  Playlist.created() : super.created();
  
  @observable Song currentSong;
  @observable ObservableList<Song> songs;
  @observable String albumArtURL;
  Library library;
  
  void enteredView() {
    super.enteredView();
    StreamObserver.addObserver(this);
    getCurrentSong();
    getPlaylist();
  }
  
  void getPlaylist() {
    HttpRequest.request("/upcoming").then((HttpRequest request) {
      songs = new ObservableList<Song>();
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
  
  void onArtistClick(Event event, var detail, Element target) {
    library.getAlbums(target.text);
  }
  
  void onAlbumClick(Event e) {
    library.getSongs(currentSong.artist, currentSong.album);
  }
  
  void onPlaylistUpdate() {}
  void onLibraryUpdate() {}
}