library TWPlaylist;

import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "library.dart";
import "../../classes/song.dart";
import "../../classes/stream-observer.dart";

/**
 * Display's our playing playlist.
 */
@CustomTag("tw-playlist")
class Playlist extends PolymerElement implements StreamObserver {
  Playlist.created() : super.created();

  @observable Song currentSong;
  @observable ObservableList<Song> songs;
  @observable String albumArtURL;
  Library library;

  void attached() {
    super.attached();
    StreamObserver.addObserver(this);
    getCurrentSong();
    getPlaylist();
  }

  /**
   * Request an update to this [Playlist]
   */
  void getPlaylist() {
    HttpRequest.request("/upcoming").then((HttpRequest request) {
      songs = new ObservableList<Song>();
      List jsonList = JSON.decode(request.responseText);

      for(Map songMap in jsonList) {
        songs.add(new Song.fromMap(songMap));
      }
    });
  }

  /**
   * Grabs the current song and updates it's album image.
   */
  void getCurrentSong([bool update = false]) {
    Song.getCurrent(update: update).then((Song song) {
      currentSong = song;
      song.getAlbumArtURL().then((String url) => albumArtURL = url);
    });
  }

  /**
   * Grabs the playlist and updates the current song.
   */
  void onPlayerUpdate() {
    getPlaylist();
    getCurrentSong(true);
  }

  /**
   * Called by clicking on an artist.
   *
   * It changes the library's view to show albums belonging to the artist.
   */
  void onArtistClick(Event event, var detail, Element target) {
    library.getAlbums(target.text);
  }

  /**
   * Called when clicking on an album.
   *
   * It changes the library's view to show songs in an album belonging to the artist.
   */
  void onAlbumClick(Event e) {
    library.getSongs(currentSong.artist, currentSong.album);
  }

  // Don't care.
  void onPlaylistUpdate() {
    getPlaylist();
  }
  void onLibraryUpdate() {}
}
