library MediaBar;
import "package:polymer/polymer.dart";
import "dart:html";
import "package:range_slider/range_slider.dart";
import "package:json_object/json_object.dart";
import "play-list.dart";
import "current-song.dart";

@CustomTag('media-bar')
class MediaBar extends PolymerElement {


  ButtonElement toggleSoundButton;
  RangeSlider volumeSlider;
  bool isPlaying;
  AudioElement stream;
  ImageElement toggleSoundImage;
  PlayList playlist;
  String artist;
  String album;
  CurrentSong currentSong;

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

  void setupListeners() {
    stream.onEmptied.listen((e) {
      stream.src = "/stream";
      stream.play();
      playlist.getPlaylist();
      getCurrentSong().loadMetaData();
    });

    toggleSoundButton.onFocus.listen((e) {
      toggleSoundButton.blur();
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

  void setPlayList(PlayList playList) {
    this.playlist = playList;
    getCurrentSong().loadMetaData();
  }

  CurrentSong getCurrentSong() {
    return playlist.currentSong;
  }
}