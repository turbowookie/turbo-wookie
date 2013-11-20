import "package:polymer/polymer.dart";
import "dart:html";
import "package:range_slider/range_slider.dart";
import "package:json_object/json_object.dart";

@CustomTag('media-bar')
class MediaBar extends PolymerElement {


  ButtonElement toggleSoundButton;
  RangeSlider volumeSlider;
  bool isPlaying;
  AudioElement stream;
  ImageElement toggleSoundImage;

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
    });
  }

  void setupListeners() {
    stream.onEmptied.listen((e) {
      stream.src = "/stream";
      stream.play();
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
}