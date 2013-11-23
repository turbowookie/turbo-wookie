library Playlist;
import "package:polymer/polymer.dart";
import "dart:html";
import "package:json_object/json_object.dart";
import "current-song.dart";

@CustomTag("play-list")
class PlayList extends PolymerElement {

  UListElement songList;
  CurrentSong currentSong;


  PlayList.created()
    :super.created() {
  }

  void enteredView() {
    super.enteredView();

    songList = $["list"];
    currentSong = $["currentSong"];
    getPlaylist();
  }

  void getPlaylist() {
    HttpRequest.request("/upcoming")
    .then((HttpRequest request) {
      songList.children.clear();
      songList.children.add(currentSong);
      setCurrentSong(songList.children[0]);

      try {
        JsonObject json = new JsonObject.fromJsonString(request.responseText);

        json.forEach((JsonObject song) {
          LIElement listElement = createListItem(song);
          songList.children.add(listElement);
        });
      } catch(exception, stacktrace) {
      }
    });
  }

  LIElement createListItem(JsonObject song) {
    LIElement listElement = new LIElement();
    String innerHtml = """<div class="title">${song["Title"]}</div>
                          <div class="artist">${song["Artist"]}</div>""";

    listElement.innerHtml = innerHtml;

    return listElement;
  }

  void setCurrentSong(CurrentSong currentSong) {
    this.currentSong = currentSong;
  }

}