library PlayList;
import "dart:async";
import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "current-song.dart";
import "song.dart";

/**
 * Display's our playlist.
 */
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

  /**
   * Request an update to this [PlayList]
   */
  void getPlaylist() {
    HttpRequest.request("/upcoming")
    .then(updatePlaylist);
  }

  /**
   * Should be called by an HttpRequest callback to update this [PlayList].
   */
  void updatePlaylist(HttpRequest request) {
    // Clear all the songs and readd the currentSong.
    songList.children.clear();
    songList.children.add(currentSong);

    // For each song that we received from the server:
    List json = JSON.decode(request.responseText);
    json.forEach((Map songJson) {
      // Create a new song and add it to the playlist list.
      Song song = new Song.fromJson(songJson);
      LIElement listElement = createListItem(song);
      songList.children.add(listElement);
    });
  }

  /**
   * A helper function to create a [Song]'s list item.
   */
  LIElement createListItem(Song song) {
    LIElement listElement = new LIElement();

    // Voting isn't ready yet so creating the thumbs is commented out.
    /*
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
    */

    // Create new divs for title and artist.
    DivElement title = new DivElement()
    ..innerHtml = "${song.title}"
    ..setAttribute("class", "title");
    DivElement artist = new DivElement()
    ..innerHtml = "${song.artist}"
    ..setAttribute("class", "artist");

    // Create a new div for the divs created above.
    DivElement songInfo = new DivElement()
    ..children.add(title)
    ..children.add(artist)
    ..setAttribute("class", "songInfo");

    // Add our song info to the list element.
    listElement.children.add(songInfo);
    //listElement.children.add(thumbsWrapper); // Again this isn't ready yet.

    return listElement;
  }

  /**
   * This will happen when a thumb button is clicked.
   */
  void thumbClick(Song song, ButtonElement up, ButtonElement down, bool upClicked) {
    // Everything is just getting disabled for now.
    up.disabled = true;
    down.disabled = true;
    up.setAttribute("class", "thumbs disabled");
    down.setAttribute("class", "thumbs disabled");

    // If this was a thing on the server side, we could vote for a song
    // based on it's filepath.
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