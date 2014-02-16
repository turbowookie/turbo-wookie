library TWViews;

import "dart:html";
import "package:polymer/polymer.dart";
import "library.dart";

@CustomTag("tw-views")
class Views extends PolymerElement {
  Views.created() : super.created();
  
  Library library;

  ButtonElement artistsButton;
  ButtonElement albumsButton;
  ButtonElement songsButton;
  
  void enteredView() {
    UListElement views = $["viewsList"];
    artistsButton = views.children[0];
    albumsButton = views.children[1];
    songsButton = views.children[2];
    
    
    artistsButton.onClick.listen((_) {
      setArtists();
    });
    
    albumsButton.onClick.listen((_) {
      setAlbums();
    });
    
    songsButton.onClick.listen((_) {
      setSongs();
    });
    
  }
  
  void setArtists([bool getArtists=true]) {
    if(getArtists)
      library.getArtists();

    artistsButton.setAttribute("class", "active");
    albumsButton.setAttribute("class", "");
    songsButton.setAttribute("class", "");
  }
  
  void setAlbums([bool getAlbums=true]) {
    if(getAlbums)
      library.getAlbums();

    artistsButton.setAttribute("class", "");
    albumsButton.setAttribute("class", "active");
    songsButton.setAttribute("class", "");
  }
  
  void setSongs([bool getSongs=true]) {
    if(getSongs)
      library.getSongs();

    artistsButton.setAttribute("class", "");
    albumsButton.setAttribute("class", "");
    songsButton.setAttribute("class", "active");
  }
}