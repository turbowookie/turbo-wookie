import "dart:async";
import "dart:html";
import "package:json_object/json_object.dart";

class Song {
  String title;
  String artist;
  String album;
  String filePath;
  Future<String> get albumArtUrl => getAlbumArtUrl();

  Song(this.title, this.artist, this.album, this.filePath);

  Song.fromJson(JsonObject json) {

    if(json.containsKey("Title"))
      title = json["Title"];
    else
      print(json);

    if(json.containsKey("Artist"))
      artist = json["Artist"];
    if(json.containsKey("Album"))
      album = json["Album"];
    if(json.containsKey("file"))
      filePath = json["file"];
  }

  Future<String> getAlbumArtUrl() {
    Completer<String> completer = new Completer<String>();

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
          int imageSize = 3;

          List images = albumJson["image"];
          while(imageSize >= images.length && imageSize != -1)
            imageSize --;

          JsonObject image;
          if(imageSize > -1)
            image = images[imageSize];

          completer.complete(image["#text"].toString());

          } catch(exception, stackTrace) {
            completer.complete("../img/wookie.jpg");
          }
        });
    }
    else {
      // Add wookiee image
      completer.complete("../img/wookie.jpg");
    }
    return completer.future;
  }

  void addToPlaylist() {
    HttpRequest.request("add?song=$filePath");
  }

  @override
  String toString() {
    return "$artist - $album - $title";
  }
}