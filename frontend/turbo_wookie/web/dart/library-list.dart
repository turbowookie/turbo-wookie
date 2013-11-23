library LibraryList;
import "dart:html";
import "package:polymer/polymer.dart";
import "package:json_object/json_object.dart";
import "play-list.dart";
import "song.dart";

@CustomTag('library-list')
class LibraryList extends PolymerElement {

  List<Song> songs;
  UListElement songsElement;
  PlayList playlist;

  LibraryList.created()
      : super.created() {
  }

  void enteredView() {
    songs = new List<Song>();
    songsElement = $["songs"];
    getAllSongs();
  }

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

        LIElement listElement = createListElement(song);
        songsElement.children.add(listElement);
      });

    });
  }

  LIElement createListElement(Song song) {
    LIElement listElement = new LIElement();

    ButtonElement button = new ButtonElement();
    button.text = "Add Song";
    button.onClick.listen((Event e) {
      song.addToPlaylist();
      playlist.getPlaylist();
    });

    listElement.innerHtml = """
        ${song.title} ${song.artist} ${song.album}
        """;
    listElement.children.add(button);
    return listElement;
  }

  void addSongToPlaylist(String filePath) {
    HttpRequest.request("add?song=$filePath");
    print("adding song: $filePath");
  }
}