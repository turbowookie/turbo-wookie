library MediaBar;
import "package:polymer/polymer.dart";
import "dart:html";
import "package:range_slider/range_slider.dart";
import "package:json_object/json_object.dart";
import "play-list.dart";

@CustomTag('media-bar')
class MediaBar extends PolymerElement {


  ButtonElement toggleSoundButton;
  RangeSlider volumeSlider;
  bool isPlaying;
  AudioElement stream;
  ImageElement toggleSoundImage;
  PlayList playlist;
  ImageElement albumArt;

  MediaBar.created()
    : super.created() {
    isPlaying = false;
  }

  void enteredView() {
    super.enteredView();
    // Allows us to link external css files in index.html.
    getShadowRoot("media-bar").applyAuthorStyles = true;

    toggleSoundButton = $["toggleSound"];
    toggleSoundImage = toggleSoundButton.children.first;
    volumeSlider = new RangeSlider($["volumeSlider"]);
    stream = $["audioElement"];
    albumArt = $["albumArt"];


    setupHotKeys();
    setupListeners();
    loadMetaData();

    // Load local storage settings
    double vol = 0.5;
    if(window.localStorage["volume"] != null) {
      vol = double.parse(window.localStorage["volume"]);
    }
    setVolume(vol, true);

    // Initially play the stream
    play();
  }

  void setupHotKeys() {
    window.onKeyPress.listen((KeyboardEvent e) {
      e.preventDefault();

      // Pause/Play
      if(e.keyCode == KeyCode.SPACE) {
        toggleSound(e);
      }

      // Change volume
      else if(e.keyCode == 44) {
        setVolume(getVolume() - 0.05, true);
      }
      else if(e.keyCode == 46) {
        setVolume(getVolume() + 0.05, true);
      }

    });
  }

  void loadMetaData() {
    DivElement title = $["songTitle"];
    DivElement artist = $["songArtist"];
    DivElement album = $["songAlbum"];

    HttpRequest.request("/current").then((HttpRequest request) {
      JsonObject json = new JsonObject.fromJsonString(request.responseText);
      //print(request.responseText);

      if(json.containsKey("Title"))
        title.setInnerHtml(json["Title"]);
      else
        title.setInnerHtml("");

      if(json.containsKey("Artist"))
        artist.setInnerHtml(json["Artist"]);
      else
        artist.setInnerHtml("");

      if(json.containsKey("Album"))
        album.setInnerHtml(json["Album"]);
      else
        album.setInnerHtml("");

      getAlbumArt(json["Artist"], json["Album"]);
    });
  }

  void setupListeners() {
    stream.onEmptied.listen((e) {
      stream.src = "/stream";
      stream.play();
      playlist.getPlaylist();
      loadMetaData();
    });

    // Set the volume slider listeners.
    volumeSlider.$elmt.onChange.listen((CustomEvent e) {
      setVolume(e.detail["value"]);
    });
    volumeSlider.$elmt.onDragEnd.listen((MouseEvent e) {
      setVolume(volumeSlider.value);
      window.localStorage["volume"] = volumeSlider.value.toString();
    });
  }

  void toggleSound(Event e) {
    if(isPlaying) {
      pause();
    }
    else {
      play();
    }
  }

  void play() {
    toggleSoundImage.src = "img/rest.svg";
    isPlaying = true;
    setVolume(volumeSlider.value);
  }

  void pause() {
    toggleSoundImage.src = "img/note.svg";
    isPlaying = false;
    setVolume(0.0);
  }

  void setVolume(double vol, [bool changeSlider = false]) {
    if(vol > 1.0)
      vol = 1.0;
    else if(vol < 0.0)
      vol = 0.0;

    if(isPlaying || vol == 0.0)
      stream.volume = vol;

    if(changeSlider) {
      volumeSlider.value = vol;
      window.localStorage["volume"] = volumeSlider.value.toString();
    }
  }

  double getVolume() {
    return volumeSlider.value;
  }

  void getAlbumArt(String artist, String album) {
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
          int imageSize = 2;
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
      albumArt.src = "";
    }
  }
}