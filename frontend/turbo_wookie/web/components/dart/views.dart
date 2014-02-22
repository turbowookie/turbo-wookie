library TWViews;

import "dart:html";
import "package:polymer/polymer.dart";
import "library.dart";

/**
 * This class controls what is being shown in the library.
 */
@CustomTag("tw-views")
class Views extends PolymerElement {
  Views.created() : super.created();
  
  Library library;

  ButtonElement artistsButton;
  ButtonElement albumsButton;
  ButtonElement songsButton;
  
  void enteredView() {
    // Grab the views buttons.
    UListElement views = $["viewsList"];
    artistsButton = views.children[0];
    albumsButton = views.children[1];
    songsButton = views.children[2];
    
    
    // Setup the views events.
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
  
  /**
   * Sets the view to artists
   * 
   * If getArtists is true, it tells the library to update as well.
   */
  void setArtists([bool getArtists=true]) {
    if(getArtists)
      library.getArtists();

    artistsButton.setAttribute("class", "active");
    albumsButton.setAttribute("class", "");
    songsButton.setAttribute("class", "");
  }
  
  /**
   * Sets the view to albums
   * 
   * If getAlbums is true, it tells the library to update as well.
   */
  void setAlbums([bool getAlbums=true]) {
    if(getAlbums)
      library.getAlbums();

    artistsButton.setAttribute("class", "");
    albumsButton.setAttribute("class", "active");
    songsButton.setAttribute("class", "");
  }
  
  /**
   * Sets the view to songs
   * 
   * If getSongs is true, it tells the library to update as well.
   */
  void setSongs([bool getSongs=true]) {
    if(getSongs)
      library.getSongs();

    artistsButton.setAttribute("class", "");
    albumsButton.setAttribute("class", "");
    songsButton.setAttribute("class", "active");
  }
  
  bool isArtists() {
    return artistsButton.attributes["class"] == "active";
  }
  
  bool isAlbums() {
    return albumsButton.attributes["class"] == "active";
  }
  
  bool isSongs() {
    return songsButton.attributes["class"] == "active";
  }
}