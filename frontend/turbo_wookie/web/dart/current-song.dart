part of TurboWookie;

@CustomTag('current-song')
class CurrentSong extends PolymerElement {

  ImageElement albumArt;
  MediaBar mediaBar;
  DivElement titleDiv;
  DivElement artistDiv;
  DivElement albumDiv;
  Song song;

  CurrentSong.created()
      : super.created() {
  }

  void enteredView() {
    albumArt = $["albumArt"];
    titleDiv = $["title"];
    artistDiv = $["artist"];
    albumDiv = $["album"];
    song = new Song();
  }

  void loadMetaData() {
    HttpRequest.request("/current").then((HttpRequest request) {
      JsonObject json = new JsonObject.fromJsonString(request.responseText);

      if(json.isEmpty) {
        song.title = "No Song Playing";
        song.artist = "No Artist";
        song.album = "No Album";
        albumArt.src = "../img/wookie.jpg";
      }
      else {
        if(json.containsKey("Title"))
          song.title = json["Title"];

        if(json.containsKey("Artist"))
          song.artist = json["Artist"];

        if(json.containsKey("Album"))
          song.album = json["Album"];

        song.albumArtUrl.then((String url) => albumArt.src = url);
      }

      if(title == null)
        titleDiv.setInnerHtml("Unknown Title");
      else
        titleDiv.setInnerHtml(song.title);

      if(song.artist == null)
        artistDiv.setInnerHtml("Unknown Artist");
      else
        artistDiv.setInnerHtml(song.artist);

      if(song.album == null)
        albumDiv.setInnerHtml("Unknown Album");
      else
        albumDiv.setInnerHtml(song.album);
    });
  }
}