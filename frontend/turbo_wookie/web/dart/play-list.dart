library PlayList;
import "dart:async";
import "dart:html";
import "package:polymer/polymer.dart";
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
    setupEvents();
  }

  /**
   * Setup events for http/timers/etc.
   */
  void setupEvents() {
    /*
    HttpRequest.request("/upcoming").asStream()
    .asBroadcastStream(onListen: (StreamSubscription<HttpRequest> request) {
      request.onData(updatePlaylist);
    });*/

    new Timer.periodic(new Duration(seconds: 10), (Timer timer) => getPlaylist());
  }

  /**
   * Request an update to the playlist
   */
  void getPlaylist() {
    HttpRequest.request("/upcoming")
    .then(updatePlaylist);
  }

  /**
   * Should be called by an HttpRequest callback to update the playlist.
   */
  void updatePlaylist(HttpRequest request) {
    try {
      songList.children.clear();
      songList.children.add(currentSong);
      setCurrentSong(songList.children[0]);

      JsonObject json = new JsonObject.fromJsonString(request.responseText);
      json.forEach((JsonObject song) {
        LIElement listElement = createListItem(song);
        songList.children.add(listElement);
      });
    } catch(exception, stacktrace) {
    }
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