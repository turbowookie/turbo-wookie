import "package:polymer/polymer.dart";

import "dart:async";
import "dart:convert";
import "dart:html";
import "observer.dart";
import "song.dart";

@CustomTag("tw-playlist")
class Playlist extends PolymerElement {
  Playlist.created() : super.created();
  
  @observable List<Song> upcoming;
  @observable Song current;
  Observer observer;
  
  void attached() {
    super.attached();
    upcoming = toObservable([]);
    observer = new Observer(onPlaylist: getUpcoming, onPlayer: onPlayer);
    
    getUpcoming();
    getCurrent();
  }
  
  Future onPlayer() {
    return Future.wait([getUpcoming(), getCurrent()]);
  }
  
  Future getUpcoming() {
    return HttpRequest.request("/upcoming")
    .then((req) {
      var json = JSON.decode(req.responseText);
      upcoming.clear();
      for(var songMap in json) {
        upcoming.add(new Song.fromMap(songMap));
      }
    });
  }
  
  Future getCurrent() {
    return HttpRequest.request("/current")
    .then((req) {
      current = new Song.fromJson(req.responseText);
    });
  }
}