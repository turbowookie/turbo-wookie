library CurrentSong;
import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "library-list.dart";
import "media-bar.dart";
import "song.dart";

/**
 * This class displays the currently playing song.
 */
@CustomTag('current-song')
class CurrentSong extends PolymerElement {

  ImageElement albumArt;
  MediaBar mediaBar;
  LibraryList library;
  DivElement titleDiv;
  DivElement artistDiv;
  DivElement albumDiv;
  Song song;

  CurrentSong.created()
      : super.created() {
  }

  void enteredView() {
    albumArt = $["albumArt"];
    titleDiv = $["title"];
    artistDiv = $["artist"];
    albumDiv = $["album"];
    
    artistDiv.onClick.listen((_) => library.getAllAlbums(artistDiv.text));
    albumDiv.onClick.listen((_) => library.getSongs(artistDiv.text, albumDiv.text));
  }

  /**
   * Grabs the meta data of this song from the server using the
   * http GET request "/current".
   */
  Future loadMetaData() {
    Completer completer = new Completer();
    HttpRequest.request("/current").then((HttpRequest request) {
      Map json = JSON.decode(request.responseText);

      if(json.isEmpty) {
        song = new Song("No Song Playing", "No Artist", "No Album", "");
        albumArt.src = "../img/wookie.jpg";
      }
      else {
        song = new Song.fromJson(json);
        song.albumArtUrl.then((String url) => albumArt.src = url);
      }

      if(song.title == null)
        titleDiv.setInnerHtml("Unknown Title");
      else
        titleDiv.setInnerHtml(song.title);

      if(song.artist == null)
        artistDiv.setInnerHtml("Unknown Artist");
      else {
        artistDiv.setInnerHtml(song.artist);
      }

      if(song.album == null)
        albumDiv.setInnerHtml("Unknown Album");
      else {
        albumDiv.setInnerHtml(song.album);
      }

      completer.complete();
    });

    return completer.future;
  }
  
  void setLibrary(LibraryList library) {
    this.library = library;
  }
}