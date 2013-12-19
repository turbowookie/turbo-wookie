library LibraryList;
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "song.dart";

/**
 * Displays every song in the library.
 */
@CustomTag('library-list')
class LibraryList extends PolymerElement {

  List<Song> songs;
  TableElement songsTable;
  TableSectionElement tableBody;
  bool titleSort;
  bool artistSort;
  bool albumSort;
  
  DivElement titleDiv;
  String currentArtist;

  LIElement artistsButton;
  LIElement albumsButton;
  LIElement songsButton;
  
  Map artistUrls;
  
  OListElement dataList;

  LibraryList.created()
      : super.created() {
    titleSort = false;
    artistSort = false;
    albumSort = false;
    artistUrls = new Map();
  }

  void enteredView() {
    songs = new List<Song>();
    songsTable = $["songs"];
    tableBody = songsTable.tBodies[0];
    
    titleDiv = $["title"];
    
    UListElement viewsList = $["viewsList"];
    artistsButton = viewsList.children[0];
    albumsButton = viewsList.children[1];
    songsButton = viewsList.children[2];

    dataList = $["data"];

    songsTable.style.display = "none";
    titleDiv.style.display = "none";
    
    getAllArtists();
    setupEvents();
  }

  /**
   * Setup all event listeners.
   */
  void setupEvents() {
    // Get the table rows.
    TableSectionElement head = songsTable.tHead;
    TableRowElement row = head.children[0];
    // For each row:
    row.children.forEach((TableCellElement cell) {
      // If the row is not the add row, add a click event to sort the table.
      if(cell.innerHtml != "Add") {
        cell.onClick.listen((MouseEvent e) {
          sort(cell.innerHtml);
        });
      }
    });
    
    titleDiv.onClick.listen((MouseEvent e) {
      getAllAlbums(currentArtist);
    });
    
    artistsButton.onClick.listen((Event e) {
      dataList.style.display = "block";
      songsTable.style.display = "none";
      titleDiv.style.display = "none";
      
      clearAllData();
      getAllArtists();
      
      artistsButton.classes.add("active");
      albumsButton.classes.remove("active");
      songsButton.classes.remove("active");
    });
    
    albumsButton.onClick.listen((Event e) {
      dataList.style.display = "block";
      songsTable.style.display = "none";
      titleDiv.style.display = "none";

      clearAllData();
      getAllAlbums();
      
      albumsButton.classes.add("active");
      artistsButton.classes.remove("active");
      songsButton.classes.remove("active");
    });
    
    songsButton.onClick.listen((Event e) {
      songsTable.style.display = "block";
      dataList.style.display = "none";
      titleDiv.style.display = "none";
      
      clearAllData();
      getAllSongs();
      
      songsButton.classes.add("active");
      artistsButton.classes.remove("active");
      albumsButton.classes.remove("active");
    });
  }
  
  void clearAllData() {
    dataList.children.clear();
    tableBody.children.clear();
  }
  
  void getAllArtists() {
    HttpRequest.request("/artists")
      .then((HttpRequest request) {
        dataList.attributes['class'] = "artists";
        List<String> artists = JSON.decode(request.responseText);
        artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        
        artists.forEach((String artist) {
          DivElement artistImgCrop = new DivElement();
          artistImgCrop.attributes['class'] = "artistCrop";
          ImageElement artistImg = new ImageElement();
          artistImgCrop.append(artistImg);
          
          if (artistUrls.containsKey(artist)) {
            artistImg.src = artistUrls[artist];
          }
          else {
            HttpRequest.request("https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(artist)}&format=json")
              .then((HttpRequest request) {
                try {
                  Map obj = JSON.decode(request.responseText);
                  Map artistJson = obj["artist"];
                  for (Map img in artistJson['image']) {
                    if (img['size'] == "extralarge") {
                      artistImg.src = img['#text'];
                      artistUrls[artist] = img["#text"];
                      break;
                    }
                  }
                  
                  if (artistImg.src.length == 0)
                    throw new Exception("");
                } catch(exception, stackTrace) {
                  artistImg.src = "../img/wookie.jpg";
                  artistUrls[artist] = "../img/wookie.jpg";
                }
              });
          }
          
          
          LIElement artistElement = new LIElement()
            ..append(artistImgCrop)
            ..append(new DivElement()
              ..attributes['class'] = "artistName"
              ..text = artist)
            ..onClick.listen((_) => getAllAlbums(artist));
          dataList.children.add(artistElement);
        });
      });
  }
  
  void getAllAlbums([String artist]) {
    String requestStr;
    if(artist == null) {
      requestStr = "/albums";
    }
    else
      requestStr = "/albums?artist=${Uri.encodeComponent(artist)}";
    
    HttpRequest.request(requestStr)
    .then((HttpRequest request) {
      clearAllData();
      dataList.attributes['class'] = "albums";
      dataList.style.display = "block";
      songsTable.style.display = "none";
      
      if(artist != null) {
        LIElement allSongsElement = new LIElement()
          ..text = "All Songs"
          ..onClick.listen((_) => getSongs(artist));
        dataList.children.add(allSongsElement);

        currentArtist = artist;
        titleDiv.text = artist;
        titleDiv.style.display = "block";
      }
      
      List<String> albums = JSON.decode(request.responseText);
      albums.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      
      albums.forEach((String album) {
        LIElement albumElement = new LIElement()
          ..text = album
          ..onClick.listen((_) => getSongs(artist, album));
        dataList.children.add(albumElement);
      });
    });
  }
  
  void getSongs(String artist, [String album]) {
    String requestStr;
    if(album == null)
      requestStr = "/songs?artist=${Uri.encodeComponent(artist)}";
    else {
      requestStr = "/songs?artist=${Uri.encodeComponent(artist)}&album=${Uri.encodeComponent(album)}";
      titleDiv.text = "$artist - $album";
    }
    
    HttpRequest.request(requestStr)
      .then((HttpRequest request) {
        List songs = JSON.decode(request.responseText);
        createSongTable(songs);
        songsTable.style.display = "block";
        dataList.style.display = "none";
      });
        
  }

  /**
   * Get all the [Song]s in the library and add them to the page.
   */
  void getAllSongs() {
    HttpRequest.request("/songs")
      .then((HttpRequest request) {
        List songs = JSON.decode(request.responseText);
        createSongTable(songs);
      });
  }
  
  void createSongTable(List songsList) {
    // The songs come in a list of json data.
    // For every song:
    songsList.forEach((Map json) {
      // Create the new song from json and add it to our list.
      Song song = new Song.fromJson(json);
      songs.add(song);

      // Now add our song to the table.
      TableRowElement row = tableBody.addRow();
      createSongRow(row, song);
    });
  }

  /**
   * Helper method for creating a row in the song table.
   */
  void createSongRow(TableRowElement row, Song song) {
    // Create the text cells and set the values.
    TableCellElement title = row.addCell();
    title.text = song.title;
    TableCellElement artist = row.addCell();
    artist.text = song.artist;
    TableCellElement album = row.addCell();
    album.text = song.album;

    // Create the add image element for the button cell.
    ImageElement add = new ImageElement(src: "../img/add.svg")
    ..setAttribute("class", "addImg");
    ImageElement addHover = new ImageElement(src: "../img/add-hover.svg")
    ..setAttribute("class", "addHoverImg");

    // Create the add button and add it's images.
    DivElement addDiv = new DivElement()
    ..append(add)
    ..append(addHover);

    // Create the cell for the button and set it up.
    TableCellElement addCol = row.addCell()
      ..classes.add("button")
      ..appendHtml(addDiv.innerHtml)
      ..onClick.listen((MouseEvent e) {
        song.addToPlaylist();
      });
  }

  /**
   * Filter or search the table by a [String].
   */
  void filter(String filter) {
    // Get all the rows in the able and iterate over them.
    List<Element> rows = tableBody.children.toList();
    for(TableRowElement row in rows) {
      // Get all the children in the row and iterate over them.
      List<Element> children = row.children;
      for(Element child in children) {
        // If the child contains our filter, we show it.
        if(child.innerHtml.toLowerCase().contains(filter.toLowerCase())) {
          row.hidden = false;
          break;
        }
        // If the child does not contain our filter, we hide it.
        else {
          row.hidden = true;
        }
      }
    }
  }

  /**
   * Sort the table by Title, Artist, or Album
   */
  void sort(String sortBy) {
    // Sort by title.
    if(sortBy == "Title") {
      // If we already sorted by title, reverse it.
      if(titleSort) {
        songs = songs.reversed.toList();
        titleSort = true;
      }
      else {
        // Use the sort function to sort our list by the title variable in songs.
        songs.sort((a, b) => a.title.compareTo(b.title));
      }
      // Make sure we know what the table is sorted by now.
      titleSort = !titleSort;
      artistSort = false;
      albumSort = false;
    }

    // Sort by artist.
    else if(sortBy == "Artist") {
      if(artistSort) {
        songs = songs.reversed.toList();
        artistSort = true;
      }
      else {
        songs.sort((a, b) => a.artist.compareTo(b.artist));
      }
      artistSort = !artistSort;
      titleSort = false;
      albumSort = false;
    }

    // Sort by album.
    else if(sortBy == "Album") {
      if(albumSort) {
        songs = songs.reversed.toList();
        albumSort = true;
      }
      else {
        songs.sort((a, b) => a.album.compareTo(b.album));
      }
      albumSort = !albumSort;
      titleSort = false;
      artistSort = false;
    }

    // Recreate our table using our songs list.
    tableBody.children.clear();
    songs.forEach((Song song) {
      TableRowElement row = tableBody.addRow();
      createSongRow(row, song);
    });
  }
}