library TurboWookie.Library;

import "dart:convert";
import "dart:html";
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
  @observable String searchStr;
  
  void attached() {
    super.attached();
    artists = toObservable([]);
    albums = toObservable([]);
    songs = toObservable([]);
    
    
    showArtists();
    
    $["artistsTab"].onClick.listen((e) => showArtists());
    $["albumsTab"].onClick.listen((e) => showAlbums());
    $["songsTab"].onClick.listen((e) => showSongs());
    $["search"].onInput.listen(search);
  }
  
  void showArtists({bool onlyArtists: true}) {
    Artist.getArtists(this);
    
    hideArtists(false); 
    if(onlyArtists) {
      hideAlbums();
      hideSongs();
      switchTab("artists");
    }
  }
  
  void showAlbums({Artist artist, bool onlyAlbums: true}) {
    Album.getAlbums(this, artist);
    
    hideAlbums(false);
    if(onlyAlbums) {
      hideArtists();
      hideSongs();
      switchTab("albums");
    }
  }
  
  void showSongs({Artist artist, Album album, onlySongs: true}) {    
    Song.getSongs(this, artist, album);
    
    hideSongs(false);
    if(onlySongs) {
      hideArtists();
      hideAlbums();
      switchTab("songs");
    }
  }
  
  void addSong(MouseEvent e) {    
    var elem = e.target as TableCellElement;
    var songPath = elem.dataset["file-path"];
    HttpRequest.request("/add?song=${Uri.encodeComponent(songPath)}");
  }
  
  void search(Event e) {
    if(searchStr.isEmpty) {
      var tab = getTab();
      switchTab(tab, click: true);
      return;
    }
    
    HttpRequest.request("/search?search=${Uri.encodeComponent(searchStr)}")
    .then((req) {
      var json = JSON.decode(req.responseText);
      var artistsJ = json["artist"];
      var albumsJ = json["album"];
      var songsJ = json["song"];
      
      var artists = [];
      var albums = [];
      var songs = [];
      
      for(var artist in artistsJ) {
        artists.add(new Artist(artist, this));
      }
      
      for(var album in albumsJ) {
        albums.add(new Album(album, new Artist("Uhum?", this)));
      }
      
      /* This will probably crash the page...
      for(var song in songsJ) {
        songs.add(new Song.fromMap(song));
      }*/
      
      this.artists = artists.toList();
      this.albums = albums.toList();
      this.songs = songs.toList();
      
      if(this.artists.isNotEmpty) {
        hideArtists(false);
      }
      if(this.albums.isNotEmpty) {
        hideAlbums(false);
      }
      if(this.songs.isNotEmpty) {
        hideSongs(false);
      }
    });
  }
  
  void switchTab(String tab, {bool click: false}) {
    if(click) {
      $["${tab}Tab"].click();
    }
    
    $["tabs"].selected = tab;
  }
  
  String getTab() {
    return $["tabs"].selected;
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