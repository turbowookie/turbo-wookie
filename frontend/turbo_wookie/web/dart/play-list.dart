part of TurboWookie;

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
    setupListeners();
  }

  void setupListeners() {
    /*
    HttpRequest.request("/upcoming").asStream()
    .asBroadcastStream(onListen: (StreamSubscription<HttpRequest> request) {
      request.onData(updatePlaylist);
    });*/

    new Timer.periodic(new Duration(seconds: 10), (Timer timer) => getPlaylist());
  }

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