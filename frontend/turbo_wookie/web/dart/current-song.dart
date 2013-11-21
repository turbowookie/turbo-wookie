library CurrentSong;
import "dart:html";
import "package:polymer/polymer.dart";
import "package:json_object/json_object.dart";
import "media-bar.dart";

@CustomTag('current-song')
class CurrentSong extends PolymerElement {

  ImageElement albumArt;
  MediaBar mediaBar;
  @observable String title;
  @observable String artist;
  @observable String album;

  CurrentSong.created()
      : super.created() {
  }

  void enteredView() {
    albumArt = $["albumArt"];
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
          JsonObject obj = new JsonObject.fromJsonString(request.responseText);
          JsonObject album = obj["album"];
          List images = album["image"];
          int imageSize = 4;
          JsonObject image = images[imageSize];

          // Just in case Last.FM doesn't have a large image for us.
          while(image == null && imageSize > 0) {
            imageSize--;
            image = images[imageSize];
          }

          String url = image["#text"];
          albumArt.src = url;
        })
        .catchError((e) {
          print("error: $e");
        });
    }
    else {
      // Add wookiee image
      albumArt.src = "../img/wookie.jpg";
    }
  }
}