import "package:polymer/polymer.dart";
import "dart:html";
import "package:json_object/json_object.dart";

@CustomTag("play-list")
class PlayList extends PolymerElement {

  UListElement songList;

  PlayList.created()
    :super.created() {
  }

  void enteredView() {
    super.enteredView();

    songList = $["list"];
    getPlaylist();
  }

  void getPlaylist() {
    HttpRequest.request("/upcoming")
    .then((HttpRequest request) {
      songList.children.clear();

      JsonObject json = new JsonObject.fromJsonString(request.responseText);
      List<JsonObject> jsonReverse = new List<JsonObject>();

      json.forEach((JsonObject song) {
        jsonReverse.add(song);
      });

      jsonReverse.reversed.forEach((JsonObject song) {
        LIElement listElement = createListItem(song);
        songList.children.add(listElement);
      });
      if(songList.children.isNotEmpty) {
        songList.children.last.scrollIntoView();
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

}