library CurrentSong;
import "dart:html";
import "package:polymer/polymer.dart";
import "package:json_object/json_object.dart";
import "media-bar.dart";

@CustomTag('current-song')
class CurrentSong extends PolymerElement {

  ImageElement albumArt;
  MediaBar mediaBar;
  DivElement titleDiv;
  DivElement artistDiv;
  DivElement albumDiv;
  String title;
  String artist;
  String album;
  JsonObject image = null;

  CurrentSong.created()
      : super.created() {
  }

  void enteredView() {
    albumArt = $["albumArt"];
    titleDiv = $["title"];
    artistDiv = $["artist"];
    albumDiv = $["album"];
  }

  void getAlbumArt() {
    if(artist != null && album != null) {
      HttpRequest.request("http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${artist}&album=${album}&format=json")
        .then((HttpRequest request) {
          // Last.FM gives us a a JSON object that has another JSON object
          // in it ("album"). "album" has a list of images ("image") of
          // varius sizes. It is set up to request a "large" image, because
          // the image sizes are very ununiform. Some small images are 200px,
          // some are 32px. So why not get a bigger one?
          try {
          JsonObject obj = new JsonObject.fromJsonString(request.responseText);
          JsonObject albumJson = obj["album"];
          int imageSize = 4;

          List images = albumJson["image"];
          while(imageSize >= images.length && imageSize != -1)
            imageSize --;

          if(imageSize > -1)
            image = images[imageSize];

          String url = image["#text"];
          albumArt.src = url;
          } catch(exception, stackTrace) {
            print(exception);
            albumArt.src = "../img/wookie.jpg";
          }
        });
    }
    else {
      // Add wookiee image
      albumArt.src = "../img/wookie.jpg";
    }
  }

  void loadMetaData() {
    HttpRequest.request("/current").then((HttpRequest request) {
      JsonObject json = new JsonObject.fromJsonString(request.responseText);

      if(json.containsKey("Title"))
        title = json["Title"];

      if(json.containsKey("Artist"))
        artist = json["Artist"];

      if(json.containsKey("Album"))
        album = json["Album"];

      if(title == null)
        titleDiv.setInnerHtml("Unknown Title");
      else
        titleDiv.setInnerHtml(title);

      if(artist == null)
        artistDiv.setInnerHtml("Unknown Artist");
      else
        artistDiv.setInnerHtml(artist);

      if(album == null)
        albumDiv.setInnerHtml("Unknown Album");
      else
        albumDiv.setInnerHtml(album);

      getAlbumArt();
    });
  }
}