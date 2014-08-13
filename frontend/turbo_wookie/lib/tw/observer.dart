library TurboWookie.Observer;

import "dart:convert";
import "dart:html";

class Observer {

  static List<Observer> listeners = [];
  static bool isRequesting = false;
  
  Function onPlaylist;
  Function onPlayer;
  Function onLibrary;
  
  Observer({this.onPlaylist, this.onPlayer, this.onLibrary}) {
    if(onPlaylist == null) onPlaylist = () {};
    if(onPlayer == null) onPlayer = () {};
    if(onLibrary == null) onLibrary = () {};
    listeners.add(this);
    startRequest();
  }

  static void requestUpdate() {
    HttpRequest.request("/polar").then((req) {
      requestUpdate();
      var obj = JSON.decode(req.responseText);
      var what = obj["changed"];
      listeners.forEach((l) => l.update(what));
    });
  }
  
  static void startRequest({bool forced: false}) {
    if(!isRequesting || forced) {
      requestUpdate();
      isRequesting = true;
    }
  }

  void update(String what) {
    if (what == "playlist")
      onPlaylist();
    else if (what == "player")
      onPlayer();
    else if (what == "database")
      onLibrary();
  }
}