import "dart:async";
import "dart:convert";
import "dart:html";

import "song.dart";


class LastFM {
  
  /**
   * Gets the url of the album art using Last.FM.
   *
   * It will return a [Future] that will return a [String] with the
   * value of the url.
   */
  static Future<String> getAlbumArtUrl(Song song) {
    Completer<String> completer = new Completer<String>();

    if(song.artist != "" && song.album != "") {
      HttpRequest.request("http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(song.artist)}&album=${Uri.encodeComponent(song.album)}&format=json")
        .then((HttpRequest request) {
          // Last.FM gives us a a JSON object that has another JSON object
          // in it ("album"). "album" has a list of images ("image") of
          // varius sizes. It is set up to request a "large" image, because
          // the image sizes are very ununiform. Some small images are 200px,
          // some are 32px. So why not get a bigger one?
          try {
            Map obj = JSON.decode(request.responseText);
            Map albumJson = obj["album"];
            int imageSize = 3;
            List images = albumJson["image"];
            while(imageSize >= images.length && imageSize != -1)
              imageSize --;

            Map image;
            if(imageSize > -1)
              image = images[imageSize];

            String url = image["#text"];

            if(url.length == 0)
              throw new Exception("");

            completer.complete(url);

          } catch(exception, stackTrace) {
            completer.complete("../components/img/wookie.jpg");
          }
        });
    }
    else {
      // Add wookiee image
      completer.complete("../img/wookie.jpg");
    }
    return completer.future;
  }
}