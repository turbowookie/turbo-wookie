library MediaBar;
import "dart:async";
import "dart:html";
import "package:polymer/polymer.dart";
import "current-song.dart";
import "play-list.dart";

/**
 * This class controls the audio stream.
 */
@CustomTag('media-bar')
class MediaBar extends PolymerElement {
  ButtonElement toggleSoundButton;
  RangeInputElement volumeSlider;
  bool isPlaying;
  AudioElement stream;
  ImageElement toggleSoundImage;
  String artist;
  String album;
  bool preventOnEmptied;
  PlayList playlist;


  MediaBar.created()
    : super.created() {
    isPlaying = false;
    preventOnEmptied = false;
  }

  void enteredView() {
    super.enteredView();
    // Allows us to link external css files in index.html.
    getShadowRoot("media-bar").applyAuthorStyles = true;

    toggleSoundButton = $["toggleSound"];
    toggleSoundImage = toggleSoundButton.children.first;
    volumeSlider = $["volumeSlider"];
    stream = $["audioElement"];

    setupHotKeys();
    setupEvents();

    // Load local storage settings
    double vol = 0.5;
    if(window.localStorage["volume"] != null) {
      vol = double.parse(window.localStorage["volume"]);
    }
    setVolume(vol, true);

    // Initially play the stream
    play();
  }

  /**
   * Sets up hotkeys so we can use keyboard shortcuts.
   */
  void setupHotKeys() {
    window.onKeyPress
      // Be sure we are not on an input element before we do anything.
      .where((KeyboardEvent e) {
        return document.activeElement.tagName != "INPUT";
    })
      .listen((KeyboardEvent e) {
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

  /**
   * Sets up events for the stream/buttons/sliders/ect.
   */
  void setupEvents() {
    // When the song changes to the next song normally.
    stream.onEmptied.listen((e) {
      if(!preventOnEmptied) {
        resetStream();
      }
    });

    // When the song changes to the next song after the playlist is empty.
    // We have to prevent the normal changing then before the next song,
    // we have to allow that again.
    stream.onSuspend.listen((e) {
      new Timer(new Duration(milliseconds: 100), () {
        resetStream();
        preventOnEmptied = true;
        new Timer(new Duration(milliseconds: 100), () {
          preventOnEmptied = false;
        });

      });
    });

    // Don't allow focus on the pause/play button.
    toggleSoundButton.onFocus.listen((e) {
      toggleSoundButton.blur();
    });

    // Set the volume slider listeners.
    volumeSlider.onChange.listen((Event e) {
      setVolume(double.parse(volumeSlider.value));
    });
  }

  /**
   * Toggles the sound.
   *
   * If the sound is on, it will pause. Otherwise it will play.
   */
  void toggleSound(Event e) {
    if(isPlaying) {
      pause();
    }
    else {
      play();
    }
  }

  /**
   * Play the stream.
   */
  void play() {
    toggleSoundImage.src = "../img/rest.svg";
    isPlaying = true;

    setVolume(double.parse(volumeSlider.value));
  }

  /**
   * Pause the stream.
   */
  void pause() {
    toggleSoundImage.src = "../img/note.svg";
    isPlaying = false;
    setVolume(0.0);
  }

  /**
   * Set the volume of the stream.
   *
   * changeSlider - If this is true, it will change the volume of
   * the slider and save the volume to localstorage.
   */
  void setVolume(double vol, [bool changeSlider = false]) {
    if(vol > 1.0)
      vol = 1.0;
    else if(vol < 0.0)
      vol = 0.0;

    window.localStorage["volume"] = vol.toString();

    if(isPlaying || vol == 0.0)
      stream.volume = vol;

    if(changeSlider) {
      volumeSlider.value = vol.toString();
    }
  }

  /**
   * Return the volume of the stream.
   */
  double getVolume() {
    return double.parse(volumeSlider.value);
  }

  /**
   * Set the playlist so the media bar can interact with it.
   */
  void setPlaylist(PlayList playlist) {
    this.playlist = playlist;
    playlist.currentSong.loadMetaData();
  }

  /**
   * Reset the stream.
   */
  void resetStream() {
    stream.src = "/stream";
    stream.play();
    if(playlist != null) {
      playlist.getPlaylist();
      playlist.currentSong.loadMetaData();
    }
  }
}