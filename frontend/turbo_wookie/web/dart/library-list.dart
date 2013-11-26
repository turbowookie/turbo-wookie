library LibraryList;
import "dart:html";
import "package:polymer/polymer.dart";
import "package:json_object/json_object.dart";
import "play-list.dart";
import "song.dart";

/**
 * Displays every some in the library.
 */
@CustomTag('library-list')
class LibraryList extends PolymerElement {

  List<Song> songs;
  TableElement songsElement;
  PlayList playlist;
  InputElement search;

  LibraryList.created()
      : super.created() {
  }

  void enteredView() {
    songs = new List<Song>();
    songsElement = $["songsBody"];
    search = $["search"];
    getAllSongs();
    setupEvents();
  }

  void setupEvents() {
    search.onInput.listen((Event e) {
      filter(search.value);
    });
  }

  /**
   * Get all the songs in the library and add them to the page.
   */
  void getAllSongs() {
    HttpRequest.request("/songs")
    .then((HttpRequest request) {
      JsonObject songsJson = new JsonObject.fromJsonString(request.responseText);
      songsJson.forEach((JsonObject songJson) {
        Song song = new Song.fromJson(songJson);
        songs.add(song);

        TableRowElement row = songsElement.addRow();
        createSongRow(row, song);
      });
    });
  }

  /**
   * Helper method for creating a row in the song table.
   */
  void createSongRow(TableRowElement row, Song song) {

    TableCellElement title = new TableCellElement();
    title.text = song.title;
    TableCellElement artist = new TableCellElement();
    artist.text = song.artist;
    TableCellElement album = new TableCellElement();
    album.text = song.album;

    ButtonElement button = new ButtonElement();
    button.innerHtml = "<img src='../img/add.svg'>";
    button.onClick.listen((MouseEvent e) {
      song.addToPlaylist();
      playlist.getPlaylist();
    });
    button.onFocus.listen((e) {
      button.blur();
    });

    row.children.add(title);
    row.children.add(artist);
    row.children.add(album);
    row.children.add(button);
  }

  void filter(String filter) {
    List<TableRowElement> rows = songsElement.children;
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
}