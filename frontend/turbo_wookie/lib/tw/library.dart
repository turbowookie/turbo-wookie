library TurboWookie.Library;

import "package:polymer/polymer.dart";
import "album.dart";
import "artist.dart";
import "song.dart";

@CustomTag("tw-library")
class Library extends PolymerElement {
  Library.created() : super.created();
  
  @observable List<Artist> artists;
  @observable List<Album> albums;
  @observable List<Song> songs;
  
  void attached() {
    super.attached();
    
    showArtists();
    
    
    
    $["artistsTab"].onClick.listen((e) => showArtists());
    $["albumsTab"].onClick.listen((e) => showAlbums());
    $["songsTab"].onClick.listen((e) => showSongs());
  }
  
  void showArtists({bool onlyArtists: true}) {
    Artist.getArtists(this).then((arts) => artists = arts.toList());
    
    hideArtists(false); 
    if(onlyArtists) {
      hideAlbums();
      hideSongs();
      switchTab("artists");
    }
  }
  
  void showAlbums({Artist artist, bool onlyAlbums: true}) {
    Album.getAlbums(this, artist).then((alb) => albums = alb.toList());
    
    hideAlbums(false);
    if(onlyAlbums) {
      hideArtists();
      hideSongs();
      switchTab("albums");
    }
  }
  
  void showSongs({Artist artist, Album album, onlySongs: true}) {    
    Song.getSongs(this, artist, album).then((son) => songs = son);
    
    hideSongs(false);
    if(onlySongs) {
      hideArtists();
      hideAlbums();
      switchTab("songs");
    }
  }
  
  void switchTab(String tab) {
    $["tabs"].selected = tab;
  }
  
  void hideArtists([bool hide=true]) {
    $["artists"].hidden = hide;
  }
  
  void hideAlbums([bool hide=true]) {
    $["albums"].hidden = hide;
  }
  
  void hideSongs([bool hide=true]) {
    $["songs"].hidden = hide;
  }
}