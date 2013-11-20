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
      JsonObject json = new JsonObject.fromJsonString(request.responseText);
      json.forEach((JsonObject song) {
        LIElement listElement = createListItem(song);
        songList.children.add(listElement);
      });
    });
  }

  LIElement createListItem(JsonObject song) {
    print(song);
    LIElement listElement = new LIElement();
    String innerHtml = """<div class="title">${song["Title"]}</div>
                          <div class="artist">${song["Artist"]}</div>""";

    listElement.innerHtml = innerHtml;

    return listElement;
  }

}