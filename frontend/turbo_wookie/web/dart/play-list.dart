library PlayList;
import "dart:async";
import "dart:html";
import "package:json_object/json_object.dart";
import "package:polymer/polymer.dart";
import "current-song.dart";
import "song.dart";

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
      json.forEach((JsonObject songJson) {
        Song song = new Song.fromJson(songJson);
        LIElement listElement = createListItem(song);
        songList.children.add(listElement);
      });
    } catch(exception, stacktrace) {
    }
  }

  LIElement createListItem(Song song) {
    LIElement listElement = new LIElement();

    ButtonElement up = new ButtonElement()
    ..children.add(new ImageElement(src: "../img/thumbs-up.svg")
      ..setAttribute("class", "up")
    );
    ButtonElement down = new ButtonElement()
    ..children.add(new ImageElement(src: "../img/thumbs-down.svg")
      ..setAttribute("class", "up")
    );

    up.onClick.listen((MouseEvent e) {
      thumbClick(song, up, down, true);
    });

    down.onClick.listen((MouseEvent e) {
      thumbClick(song, up, down, false);
    });

    DivElement thumbs = new DivElement()
    ..children.add(up)
    ..children.add(down)
    ..setAttribute("class", "thumbs");
    DivElement thumbsWrapper = new DivElement()
    ..children.add(thumbs)
    ..setAttribute("class", "thumbsWrapper");

    DivElement title = new DivElement()
    ..innerHtml = "${song.title}"
    ..setAttribute("class", "title");
    DivElement artist = new DivElement()
    ..innerHtml = "${song.artist}"
    ..setAttribute("class", "artist");

    DivElement songInfo = new DivElement()
    ..children.add(title)
    ..children.add(artist)
    ..setAttribute("class", "songInfo");

    listElement.children.add(songInfo);
    listElement.children.add(thumbsWrapper);

    return listElement;
  }

  void setCurrentSong(CurrentSong currentSong) {
    this.currentSong = currentSong;
  }

  void thumbClick(Song song, ButtonElement up, ButtonElement down, bool upClicked) {
    up.disabled = true;
    down.disabled = true;
    up.setAttribute("class", "thumbs disabled");
    down.setAttribute("class", "thumbs disabled");

    /*
    if(upClicked) {
      HttpRequest.request("/voteup?song=${song.filePath}")
      .then((HttpRequest request) {
        getPlaylist();
      });
    }
    else {
      HttpRequest.request("/votedown?song=${song.filePath}")
      .then((HttpRequest request) {
        getPlaylist();
      });
    }
    */
  }

}