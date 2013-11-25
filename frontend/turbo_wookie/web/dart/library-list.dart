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

  LibraryList.created()
      : super.created() {
  }

  void enteredView() {
    songs = new List<Song>();
    songsElement = $["songs"];
    getAllSongs();
  }

  /**
   * Get all the songs in the library and add them to the page.
   */
  void getAllSongs() {
    HttpRequest.request("/songs")
    .then((HttpRequest request) {
      JsonObject songsJson = new JsonObject.fromJsonString(request.responseText);
      songsJson.forEach((JsonObject songJson) {
        String title = songJson["Name"];
        String artist = songJson["Artist"];
        String album = songJson["Album"];
        String filePath = songJson["FilePath"];
        Song song = new Song()
        ..title = title
        ..artist = artist
        ..album = album
        ..filePath = filePath;
        songs.add(song);

        TableRowElement row = songsElement.addRow();
        createSongRow(row, song);
        //songsElement.children.add(row);
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
    button.onClick.listen((Event e) {
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
}