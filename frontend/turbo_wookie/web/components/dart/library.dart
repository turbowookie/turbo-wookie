library TWLibrary;

import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "views.dart";
import "../../classes/song.dart";
import "../../classes/lastfm.dart";

/**
 * Displays the songs/artists/albums in the library.
 */
@CustomTag("tw-library")
class Library extends PolymerElement {
  Library.created() : super.created();

  @observable String locationArtist;
  @observable String locationAlbum;
  
  String currentArtist;
  UListElement dataList;
  List<String> artists;
  List<String> albums;
  
  List<Song> songs;
  TableElement songsTable;
  TableSectionElement songsTableBody;
  
  Views views;
  
  void enteredView() {
    super.enteredView();
    
    dataList = $["data"];
    artists = new List<String>();
    albums = new List<String>();
    songs = new List<Song>();
    songsTable = $["songs"];
    songsTableBody = songsTable.tBodies[0];
    
    getArtists();
  }
  
  /**
   * Clears all song/artist/album data. 
   */
  void clearAllData() {
    songs.clear();
    songsTableBody.children.clear();
    dataList.children.clear();
  }
  
  /**
   * Called when the location text is clicked.
   * This will switch the view to an artist's albums page. 
   */
  void locationClick(Event e, var detail, Element target) {
    getAlbums(target.text);
  }
  
  /**
   * Get's all the artists and displays them.
   */
  void getArtists() {
    songsTable.style.display = "none";
    dataList.style.display = "block";
    
    HttpRequest.request("/artists").then((HttpRequest request) {
      // Clear the data and tell views to switch to artists.
      clearAllData();
      views.setArtists(false);

      // Tell the dataList that we are giving it artists in order for it
      // to style correctly.
      dataList.attributes["class"] = "artists";
      
      // Don't show anything for the location text.
      locationArtist = "";
      locationAlbum = "";
      
      // Get all the artists and sort them.
      artists = JSON.decode(request.responseText);
      artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
      // Add each artist to the page.
      for(String artist in artists) {
        // Create the image element.
        ImageElement artistImg = new ImageElement();
        LastFM.getArtistImgUrl(artist)
          .then((String url) => artistImg.src = url);

        // Create the outter image element.
        DivElement artistImgCrop = new DivElement()
        ..classes.add("artistCrop")
        ..append(artistImg);
        
        // Create the artist name element.
        DivElement artistName = new DivElement()
        ..text = artist
        ..classes.add("artistName");
        
        // Create the list element and add everything to it.
        LIElement artistElement = new LIElement()
        ..append(artistImgCrop)
        ..append(artistName)
        ..onClick.listen((_) => getAlbums(artist));
        
        // Finally, add the list element to the list.
        dataList.children.add(artistElement);
      }
      
    });
  }
  
  /**
   * Get all albums from the server and display them.
   * 
   * An optional parameter is artist. If you have this, it will get all albums
   * with that artist.
   */
  void getAlbums([String artist]) {
    songsTable.style.display = "none";
    dataList.style.display = "block";
    
    // Form the request string.
    String requestStr;
    if(artist == null) {
      requestStr = "/albums";
      locationArtist = "";
    }
    else
      requestStr = "/albums?artist=${Uri.encodeComponent(artist)}";
    
    HttpRequest.request(requestStr)
    .then((HttpRequest request) {
      // Clear our data and show our album info.
      clearAllData();
      views.setAlbums(false);
      
      dataList.attributes['class'] = "albums";
      dataList.style.display = "block";
      songsTable.style.display = "none";
      
      // If we had an artist, add an all songs and set the titleDiv.
      if(artist != null) {
        LIElement allSongsElement = new LIElement()
          ..text = "All Songs"
          ..onClick.listen((_) => getSongs(artist));
        dataList.children.add(allSongsElement);

        currentArtist = artist;
        locationArtist = artist;
        locationAlbum = "";
      }
      
      // Decode our albums from json data and create a DOM element out of them.
      Map<String, List<String>> albums = JSON.decode(request.responseText);
      List<LIElement> albumElements = new List<LIElement>();
      albums.forEach((String artist, List<String> albums) {
        for(String album in albums) {
          LIElement albumElement = new LIElement()
          ..text = album
          ..onClick.listen((_) => getSongs(artist, album));
          // Add it to a list so we can sort it later.
          albumElements.add(albumElement);
        }
      });
      
      // Sort the albums and add them to the DOM.
      albumElements.sort((a, b) => a.text.toLowerCase().compareTo(b.text.toLowerCase()));
      for(LIElement albumElement in albumElements) {
        dataList.children.add(albumElement);
      }
    });    
  }
  
  /**
   * Get songs belonging to an artist.
   * 
   * With artist, it will grab all songs belonging to that artist.
   * With artist and album, it will grab all songs in the album belonging to the artist.
   * Otherwise, it will grab all songs.
   */
  void getSongs([String artist, String album]) {
    // Show the songs table/Hide the datalist.
    songsTable.style.display = "block";
    dataList.style.display = "none";
    
    // Form the request string and setup the location text.
    String requestStr;
    if(album == null && artist != null) {
      requestStr = "/songs?artist=${Uri.encodeComponent(artist)}";
      locationArtist = artist;
      locationAlbum = " - All Songs";
    }
    else if(album != null && artist != null) {
      requestStr = "/songs?artist=${Uri.encodeComponent(artist)}&album=${Uri.encodeComponent(album)}";
      locationArtist = artist;
      locationAlbum = " - $album";
    }
    else {
      requestStr = "/songs";
      locationArtist = "";
      locationAlbum = "";
    }
    
    // Get the songs.
    HttpRequest.request(requestStr).then((HttpRequest request) {
      // Clear the data and tell views we're on the songs tab.
      clearAllData();
      views.setSongs(false);
      
      // Grab all the songs from the response.
      List<Map> songsJson = JSON.decode(request.responseText);
      
      // Create the songs and add it to songs list. 
      for(Map songMap in songsJson)
        songs.add(new Song.fromMap(songMap));
      
      // Sort it and create the table.
      songs.sort((Song a, Song b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      createSongTable();
    });
  }
  
  /**
   * A helper function to fill the song table with songs list.
   */
  void createSongTable() {
    for(Song song in songs) {
      
      TableRowElement tr = songsTableBody.addRow();
      
      // Create first 3 cells.
      TableCellElement titleC = tr.addCell()
      ..text = song.title;
      TableCellElement artistC = tr.addCell()
      ..text = song.artist;
      TableCellElement albumC = tr.addCell()
      ..text = song.album;
      
      // Create add cell
      ImageElement add = new ImageElement(src: "../components/img/add.svg")
      ..classes.add("addImg");
      ImageElement addHover = new ImageElement(src: "../components/img/add-hover.svg")
      ..classes.add("addHoverImg");
      DivElement addDiv = new DivElement()
      ..append(add)
      ..append(addHover);
      
      // Create the actual cell element and add it to the table.
      TableCellElement addC = tr.addCell()
      ..classes.add("button")
      ..appendHtml(addDiv.innerHtml)
      ..onClick.listen((_) {
        song.addToPlaylist();
      });
    }
  }
  
}