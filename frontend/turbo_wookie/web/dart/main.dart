import "dart:convert";
import "dart:html";
import "package:polymer/polymer.dart";
import "media-bar.dart";
import "play-list.dart";
import "library-list.dart";

/**
 * The main method that kicks everything off.
 */
void main() {
  initPolymer();

  MediaBar mediaBar = querySelector("#mediaBar");
  PlayList playlist = querySelector("#playlist");
  LibraryList library = querySelector("#library");
  TextInputElement search = querySelector("#search");
  mediaBar.setPlayList(playlist);
  library.playlist = playlist;
  search.onInput.listen((Event e) => library.filter(search.value));

  // Terrible hack because for some reason I couldn't get keyboard input
  // on the input element.
  search.onKeyDown
    .where(isGoodKey)
      .listen((KeyboardEvent e) {
        String str = ASCII.decode(new List<int>()
            ..add(e.keyCode));
        if(!e.shiftKey)
          str = str.toLowerCase();

        search.value += str;

        library.filter(search.value);
      });
}

bool isGoodKey(KeyboardEvent e) {
  return e.keyCode != KeyCode.BACKSPACE
      && e.keyCode != KeyCode.LEFT && e.keyCode != KeyCode.RIGHT
      && e.keyCode != KeyCode.UP && e.keyCode != KeyCode.DOWN
      && e.keyCode != KeyCode.DELETE;
}