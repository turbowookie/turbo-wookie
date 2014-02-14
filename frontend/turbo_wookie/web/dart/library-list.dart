library LibraryList;
import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "song.dart";

/**
 * Displays every song in the library.
 */
@CustomTag('library-list')
class LibraryList extends PolymerElement {
  // View buttons.
  LIElement artistsButton;
  LIElement albumsButton;
  LIElement songsButton;
  
  // Music data variables.
  Map artistUrls;  
  OListElement dataList;
  List<Song> songs;
  TableElement songsTable;
  TableSectionElement tableBody;
  
  // Title variables.
  DivElement titleDiv;
  String currentArtist;
  
  // Sort variables.
  bool titleSort;
  bool artistSort;
  bool albumSort;

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
    
    // Get all of our elements
    UListElement viewsList = $["viewsList"];
    artistsButton = viewsList.children[0];
    albumsButton = viewsList.children[1];
    songsButton = viewsList.children[2];
    dataList = $["data"];
    titleDiv = $["title"];

    // Hide the song table and title div
    songsTable.style.display = "none";
    titleDiv.style.display = "none";
    
    // Fill our artist page.
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
    
    // When we click the title div, grab/display the albums for that artist.
    titleDiv.onClick.listen((MouseEvent e) {
      getAllAlbums(currentArtist);
    });
    
    // Transition to the artist page.
    artistsButton.onClick.listen((Event e) {
      // Show the datalist and hide the songs table/title div.
      dataList.style.display = "block";
      songsTable.style.display = "none";
      titleDiv.style.display = "none";
      
      // Clear data from memory and grab all artists.
      clearAllData();
      getAllArtists();
      
      // Set the artist button as the active button.
      artistsButton.classes.add("active");
      albumsButton.classes.remove("active");
      songsButton.classes.remove("active");
    });
    
    albumsButton.onClick.listen((Event e) {
      // Show the datalist and hide the songs table/title div.
      dataList.style.display = "block";
      songsTable.style.display = "none";
      titleDiv.style.display = "none";

      // Clear data from memory and grab all albums.
      clearAllData();
      getAllAlbums();

      // Set the album button as the active button.
      albumsButton.classes.add("active");
      artistsButton.classes.remove("active");
      songsButton.classes.remove("active");
    });
    
    songsButton.onClick.listen((Event e) {
      // Show the songs table and hide the songs data list/title div.
      songsTable.style.display = "block";
      dataList.style.display = "none";
      titleDiv.style.display = "none";

      // Clear data from memory and grab all songs.
      clearAllData();
      getAllSongs();

      // Set the songs button as the active button.
      songsButton.classes.add("active");
      artistsButton.classes.remove("active");
      albumsButton.classes.remove("active");
    });
  }
  
  /**
   * Clears all song/artist/album data from memory in this library.
   */
  void clearAllData() {
    dataList.children.clear();
    tableBody.children.clear();
  }
  
  /**
   * Get all artists from the server and display them.
   */
  void getAllArtists() {
    HttpRequest.request("/artists")
      .then((HttpRequest request) {
        // Tell the dataList that we are giving it artists in order for it
        // to style correctly.
        dataList.attributes['class'] = "artists";
        
        // Convert all the artist info and sort it alphebetically, ignoring case.
        List<String> artists = JSON.decode(request.responseText);
        artists.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        
        // For each artist, add it to the page.
        artists.forEach((String artist) {
          // Create the image stuff.
          DivElement artistImgCrop = new DivElement();
          artistImgCrop.attributes['class'] = "artistCrop";
          ImageElement artistImg = new ImageElement();
          artistImgCrop.append(artistImg);
          
          // Get the artist's image.
          getArtistImg(artist)
            .then((String src) => artistImg.src = src);
          
          // Create the list element and add everything to it.
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
  
  /**
   * This get's an image url associated with an artist from Last.FM.
   * 
   * If it cannot find an image, it uses a default wookie image.
   */
  Future<String> getArtistImg(String artist) {
    Completer<String> completer = new Completer<String>();
    
    // If we already have the image, just use it instead of searching Last.FM.
    if (artistUrls.containsKey(artist)) {
      completer.complete(artistUrls[artist]);
    }
    else {
      // Search Last.FM for the image.
      HttpRequest.request("https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(artist)}&format=json")
        .then((HttpRequest request) {
          try {
            // Get the source of the image out of the json data.
            String src;
            Map obj = JSON.decode(request.responseText);
            Map artistJson = obj["artist"];
            // Get a decent sized image.
            for (Map img in artistJson['image']) {
              if (img['size'] == "extralarge") {
                src = img['#text'];
                artistUrls[artist] = img["#text"];
                break;
              }
            }
            
            // If we don't have an image, throw an exception to be handled.
            if (src == null || src.isEmpty)
              throw new Exception("");
            // Otherwise, return our src.
            else
              completer.complete(src);
            
          } catch(exception, stackTrace) {
            // Set the artist image to our wookie image.
            completer.complete("../img/wookie.jpg");
            artistUrls[artist] = "../img/wookie.jpg";
          }
        });
    }
    
    return completer.future;
  }
  
  /**
   * Get all albums from the server and display them.
   * 
   * An optional parameter is artist. If you have this, it will get all albums
   * with that artist.
   */
  void getAllAlbums([String artist]) {
    // Form the request string.
    String requestStr;
    if(artist == null) {
      requestStr = "/albums";
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
        titleDiv.text = artist;
        titleDiv.style.display = "block";
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
   * An optional parameter is album. If you have this, it will get all songs
   * belonging to the specified artist, in that album.
   */
  void getSongs(String artist, [String album]) {
    // Form the request string.
    String requestStr;
    if(album == null)
      requestStr = "/songs?artist=${Uri.encodeComponent(artist)}";
    else {
      requestStr = "/songs?artist=${Uri.encodeComponent(artist)}&album=${Uri.encodeComponent(album)}";
      titleDiv.style.display = "block";
      titleDiv.text = "$artist - $album";
      currentArtist = artist;
    }
    
    // Get all the songs.
    HttpRequest.request(requestStr)
      .then((HttpRequest request) {
        // Add them to the table and show the table.
        List songs = JSON.decode(request.responseText);
        createSongTable(songs);
        songsTable.style.display = "block";
        dataList.style.display = "none";
      });
        
  }

  /**
   * Get every song in the library and add them to the page.
   */
  void getAllSongs() {
    HttpRequest.request("/songs")
      .then((HttpRequest request) {
        List songs = JSON.decode(request.responseText);
        createSongTable(songs);
      });
  }
  
  /**
   * Fill the song table with the passed in songs.
   */
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