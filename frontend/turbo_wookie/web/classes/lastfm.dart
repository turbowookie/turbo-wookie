library TWLastFM;

import "dart:async";
import "dart:convert";
import "dart:html";

import "song.dart";


class LastFM {

  static Map<String, String> artistUrls = new Map<String, String>();

  /**
   * Gets the url of the album art using Last.FM.
   *
   * It will return a [Future] that will return a [String] with the
   * value of the url.
   */
  static Future<String> getAlbumArtUrl(Song song) {
    Completer<String> completer = new Completer<String>();

    if (song.artist != "" && song.album != "") {
      HttpRequest.request(
          "http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(song.artist)}&album=${Uri.encodeComponent(song.album)}&format=json"
          ).then((HttpRequest request) {
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
          while (imageSize >= images.length && imageSize != -1) imageSize--;

          Map image;
          if (imageSize > -1) image = images[imageSize];

          String url = image["#text"];

          if (url.length == 0) throw new Exception("");

          completer.complete(url);

        } catch (exception, stackTrace) {
          completer.complete("../components/img/wookie.jpg");
        }
      });
    } else {
      // Add wookiee image
      completer.complete("../img/wookie.jpg");
    }
    return completer.future;
  }

  static Future<String> getArtistImgUrl(String artist) {
    Completer<String> com = new Completer<String>();

    // If we already have the image, just use it instead of searching Last.FM.
    if (artistUrls.containsKey(artist)) {
      com.complete(artistUrls[artist]);
    } else {
      // Search Last.FM for the image.
      HttpRequest.request(
          "https://ws.audioscrobbler.com/2.0/?method=artist.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(artist)}&format=json"
          ).then((HttpRequest request) {
        try {
          // Get the source of the image out of the json data.
          String src;
          Map obj = JSON.decode(request.responseText);
          Map artistJson = obj["artist"];
          // Get a decent sized image.
          for (Map img in artistJson['image']) {
            if (img['size'] == "extralarge") {
              src = img['#text'];
              artistUrls[artist] = img["#text"];
              break;
            }
          }

          // If we don't have an image, throw an exception to be handled.
          if (src == null || src.isEmpty) throw new Exception("");
              // Otherwise, return our src.
          else com.complete(src);

        } catch (exception, stackTrace) {
          // Set the artist image to our wookie image.
          com.complete("../img/wookie.jpg");
          artistUrls[artist] = "../img/wookie.jpg";
        }
      });
    }
    return com.future;
  }
}
