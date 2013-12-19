library Song;
import "dart:async";
import "dart:convert";
import "dart:html";

/**
 * A song is a class that groups together data about a song.
 */
class Song {
  String title;
  String artist;
  String album;
  int length;
  String filePath;
  Future<String> get albumArtUrl => getAlbumArtUrl();

  /**
   * Create a [Song] using [String]s.
   */
  Song(this.title, this.artist, this.album, this.filePath);

  /**
   * Create a [Song] using a [Map].
   *
   * The map should have these fields:
   * * Title
   * * Artist
   * * Album
   * * Time
   * * File
   */
  Song.fromJson(Map map) {
    if (!(map.containsKey("Title") && map.containsKey("Artist") && map.containsKey("Album"))) {
      print(map["file"]);
    }

    if(map.containsKey("Title"))
      title = map["Title"];
    else
      title = "";

    if(map.containsKey("Artist"))
      artist = map["Artist"];
    else
      artist = "";

    if(map.containsKey("Album"))
      album = map["Album"];
    else
      album = "";

    if(map.containsKey("Time"))
      length = map["Time"];
    else
      length = 0;

    if(map.containsKey("file"))
      filePath = map["file"];
  }

  /**
   * Gets the url of the album art using Last.FM.
   *
   * It will return a [Future] that will return a [String] with the
   * value of the url.
   */
  Future<String> getAlbumArtUrl() {
    Completer<String> completer = new Completer<String>();

    if(artist != "" && album != "") {
      HttpRequest.request("http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=9327f98028a6c8bc780c8a4896404274&artist=${Uri.encodeComponent(artist)}&album=${Uri.encodeComponent(album)}&format=json")
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

  /**
   * Requests the server to add this song to it's playlist.
   */
  void addToPlaylist() {
    HttpRequest.request("add?song=$filePath");
  }

  @override
  String toString() {
    return "$artist - $album - $title";
  }
}