library TWControls;

import "dart:html";
import "package:polymer/polymer.dart";
import "../../classes/song.dart";
import "../../classes/stream-observer.dart";

/**
 * This class controls the audio stream.
 */
@CustomTag("tw-player")
class Controls extends PolymerElement implements StreamObserver {
  Controls.created() : super.created();
  
  bool isPlaying = true;
  ButtonElement pausePlay;
  AudioElement stream;
  RangeInputElement volumeSlider;
  RangeInputElement progressSlider;
  
  void attached() {
    super.attached();
    StreamObserver.addObserver(this);
    
    // Get all our elements.
    pausePlay = $["pausePlay"];
    volumeSlider = $["volumeSlider"];
    stream = $["stream"];
    progressSlider = $["progressSlider"];
    resetStream();

    // Set the volume.
    if(window.localStorage["volume"] != null) {
      setVolume(double.parse(window.localStorage["volume"]), true);
    }
    else {
      setVolume(double.parse(volumeSlider.value));
    }

    // Setup all events.
    volumeSlider.onChange.listen((e) {
      setVolume(double.parse(volumeSlider.value));
    });
    pausePlay.onClick.listen((_) => playPause());

    stream.onEmptied.listen((_) => resetStream());
    stream.onTimeUpdate.listen((_) =>
        progressSlider.value = stream.currentTime.toString());
    
    // Setup keyboard controls.
    window.onKeyPress
      // Be sure we are not on an input element before we do anything.
      .where((KeyboardEvent e) {
        return 
            document.activeElement.tagName != "TW-TURBO-WOOKIE" &&
            document.activeElement.tagName != "INPUT";
    })
      .listen((KeyboardEvent e) {
        e.preventDefault();

        // Pause/Play
        if(e.keyCode == KeyCode.SPACE) {
          playPause();
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
   * Toggles between play and paused mode.
   */
  void playPause() {
    if(isPlaying)
      pause();
    else
      play();
  }
  
  /**
   * Plays the stream.
   */
  void play() {
    pausePlay.classes.remove("paused");
    pausePlay.classes.add("playing");
    
    isPlaying = true;    
    setVolume(getVolume());
  }
  
  /**
   * Pauses the stream.
   */
  void pause() {
    pausePlay.classes.add("paused");
    pausePlay.classes.remove("playing");

    setVolume(0.0);
    isPlaying = false;
  }
  
  /**
   * Resets the stream.
   */
  void resetStream() {
    stream.src = "/stream";
    setCurrSongTime();
    stream.play();
  }
  
  /**
   * Set the progress slider's max value.
   */
  void setCurrSongTime([bool update = false]) {
    Song.getCurrent(update: update).then((Song currSong) {
      progressSlider.max = currSong.length.toString();
    });
  }
  
  /**
   * Set the volume of the stream. Values allowed are between 0.0 - 1.0.
   *
   * changeSlider - If this is true, it will change the volume of
   * the slider and save the volume to localstorage.
   */
  void setVolume(double vol, [bool moveSlider = false]) {
    // Be sure the value is within the correct range.
    if(vol > 1.0)
      vol = 1.0;
    else if(vol < 0.0)
      vol = 0.0;
    
    // Store the value in localstorage.
    window.localStorage["volume"] = vol.toString();
    
    // Only set the volume of the stream if we are playing.
    if(isPlaying)
      stream.volume = vol;
    
    // Move the slider if we were told to.
    if(moveSlider) {
      volumeSlider.value = vol.toString();
    }
  }
  
  /**
   * Get the volume of the stream.
   */
  double getVolume() {
    return double.parse(volumeSlider.value);
  }

  /**
   * When the player updates, reset the stream.
   */
  void onPlayerUpdate() {
    resetStream();
  }
  
  // Don't care...
  void onPlaylistUpdate() {}
  void onLibraryUpdate() {}
}