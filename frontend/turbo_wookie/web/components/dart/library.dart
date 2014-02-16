library TWLibrary;

import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "../../classes/song.dart";
import "../../classes/lastfm.dart";


@CustomTag("tw-library")
class Library extends PolymerElement {
  Library.created() : super.created();

  @observable String location;
  String currentArtist;
  UListElement dataList;
  @observable List<String> artists;
  @observable List<String> albums;
  
  @observable List<Song> songs;
  TableElement songsTable;
  TableSectionElement songsTableBody;
  

  ButtonElement artistButton;
  ButtonElement albumsButton;
  ButtonElement songsButton;
  
  void enteredView() {
    super.enteredView();
    
    dataList = $["data"];
    artists = new List<String>();
    albums = new List<String>();
    songs = new List<Song>();
    songsTable = $["songs"];
    songsTableBody = songsTable.tBodies[0];
    
    UListElement views = $["viewsList"];
    artistButton = views.children[0];
    albumsButton = views.children[1];
    songsButton = views.children[2];
    
    artistButton.onClick.listen((_) {
      clearAllData();
      getArtists();
    });
    
    albumsButton.onClick.listen((_) {
      clearAllData();
      getAlbums();
    });
    
    songsButton.onClick.listen((_) {
      clearAllData();
      getSongs();
    });
    
    getArtists();
  }
  
  void clearAllData() {
    songs.clear();
    songsTableBody.children.clear();
    dataList.children.clear();
  }
  
  void getArtists() {
    artistButton.classes.add("active");
    albumsButton.classes.remove("active");
    songsButton.classes.remove("active");
    songsTable.style.display = "none";
    dataList.style.display = "block";
    
    HttpRequest.request("/artists").then((HttpRequest request) {
      dataList.attributes["class"] = "artists";
      location = "";
      
      artists = JSON.decode(request.responseText);
      artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
      for(String artist in artists) {
        ImageElement artistImg = new ImageElement();
        LastFM.getArtistImgUrl(artist)
          .then((String url) => artistImg.src = url);

        DivElement artistImgCrop = new DivElement()
        ..classes.add("artistCrop")
        ..append(artistImg);
        
        DivElement artistName = new DivElement()
        ..text = artist
        ..classes.add("artistName");
        
        LIElement artistElement = new LIElement()
        ..append(artistImgCrop)
        ..append(artistName)
        ..onClick.listen((_) => getAlbums(artist));
        
        dataList.children.add(artistElement);
      }
      
    });
  }
  
  void getAlbums([String artist]) {
    artistButton.classes.remove("active");
    albumsButton.classes.add("active");
    songsButton.classes.remove("active");
    songsTable.style.display = "none";
    dataList.style.display = "block";
    
    // Form the request string.
    String requestStr;
    if(artist == null) {
      requestStr = "/albums";
      location = "";
    }
    else
      requestStr = "/albums?artist=${Uri.encodeComponent(artist)}";
    
    HttpRequest.request(requestStr)
    .then((HttpRequest request) {
      // Clear our data and show our album info.
      clearAllData();
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
        location = artist;
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
  
  void getSongs([String artist, String album]) {
    artistButton.classes.remove("active");
    albumsButton.classes.remove("active");
    songsButton.classes.add("active");
    songsTable.style.display = "block";
    dataList.style.display = "none";
    
    String requestStr;

    if(album == null && artist != null)
      requestStr = "/songs?artist=${Uri.encodeComponent(artist)}";
    else if(album != null && artist != null)
      requestStr = "/songs?artist=${Uri.encodeComponent(artist)}&album=${Uri.encodeComponent(album)}";
    else
      requestStr = "/songs";
    
    HttpRequest.request(requestStr).then((HttpRequest request) {
      List<Map> songsJson = JSON.decode(request.responseText);
      
      for(Map songMap in songsJson) {
        songs.add(new Song.fromMap(songMap));
      }
      songs.sort((Song a, Song b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      createSongTable();
    });
  }
  
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
      
      TableCellElement addC = tr.addCell()
      ..classes.add("button")
      ..appendHtml(addDiv.innerHtml)
      ..onClick.listen((_) {
        song.addToPlaylist();
      });
    }
  }
  
}