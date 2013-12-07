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
  TableElement table;
  TableSectionElement tableBody;
  bool titleSort;
  bool artistSort;
  bool albumSort;
  
  get applyAuthorStyles => true;

  LibraryList.created()
      : super.created() {
    titleSort = false;
    artistSort = false;
    albumSort = false;
  }

  void enteredView() {
    songs = new List<Song>();
    table = $["songs"];
    tableBody = table.tBodies[0];
    getAllSongs();
    setupEvents();
  }

  void setupEvents() {
    TableSectionElement head = table.tHead;
    TableRowElement row = head.children[0];
    row.children.forEach((TableCellElement cell) {
      if(cell.innerHtml != "Add") {
        cell.onClick.listen((MouseEvent e) {
          sort(cell.innerHtml);
        });
      }
    });
  }

  /**
   * Get all the songs in the library and add them to the page.
   */
  void getAllSongs() {
    HttpRequest.request("/songs")
      .then((HttpRequest request) {

        List songsJson = JSON.decode(request.responseText);
        songsJson.forEach((Map json) {
          Song song = new Song.fromJson(json);
          songs.add(song);

          TableRowElement row = tableBody.addRow();
          createSongRow(row, song);
        });

      });
  }

  /**
   * Helper method for creating a row in the song table.
   */
  void createSongRow(TableRowElement row, Song song) {

    TableCellElement title = row.addCell();
    title.text = song.title;
    TableCellElement artist = row.addCell();
    artist.text = song.artist;
    TableCellElement album = row.addCell();
    album.text = song.album;

    ImageElement add = new ImageElement(src: "../img/add.svg")
    ..setAttribute("class", "addImg");
    ImageElement addHover = new ImageElement(src: "../img/add-hover.svg")
    ..setAttribute("class", "addHoverImg");

    ButtonElement button = new ButtonElement()
    ..append(add)
    ..append(addHover);

    TableCellElement buttonCol = row.addCell();
    buttonCol.classes.add("button");
    buttonCol.appendHtml("${button.innerHtml}"); //TODO Listeners don't work like this...
    buttonCol.onClick.listen((MouseEvent e) {
      song.addToPlaylist();
    });

    button.onClick.listen((MouseEvent e) {
      song.addToPlaylist();
      print(song);
    });
    button.onFocus.listen((e) {
      button.blur();
    });
  }

  void filter(String filter) {
    List<Element> rows = tableBody.children.toList();
    for(TableRowElement row in rows) {
      List<Element> children = row.children;
      for(Element child in children) {
        if(child.innerHtml.toLowerCase().contains(filter.toLowerCase())) {
          row.hidden = false;
          break;
        }
        else {
          row.hidden = true;
        }
      }
    }
  }

  void sort(String sortBy) {
    if(sortBy == "Title") {
      songs.sort((a, b) => a.title.compareTo(b.title));
      if(titleSort) {
        songs = songs.reversed.toList();
        titleSort = true;
      }
      titleSort = !titleSort;
      artistSort = false;
      albumSort = false;
    }
    else if(sortBy == "Artist") {
      songs.sort((a, b) => a.artist.compareTo(b.artist));
      if(artistSort) {
        songs = songs.reversed.toList();
        artistSort = true;
      }
      artistSort = !artistSort;
      titleSort = false;
      albumSort = false;
    }
    else if(sortBy == "Album") {
      songs.sort((a, b) => a.album.compareTo(b.album));
      if(albumSort) {
        songs = songs.reversed.toList();
        albumSort = true;
      }
      albumSort = !albumSort;
      titleSort = false;
      artistSort = false;
    }

    tableBody.children.clear();
    songs.forEach((Song song) {
      TableRowElement row = tableBody.addRow();
      createSongRow(row, song);
    });
  }
}