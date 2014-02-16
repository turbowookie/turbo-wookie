library TWControls;

import "dart:html";
import "package:polymer/polymer.dart";
import "../../classes/song.dart";

@CustomTag("tw-controls")
class Controls extends PolymerElement {
  Controls.created() : super.created();
  
  bool isPlaying = true;
  ButtonElement pausePlay;
  AudioElement stream;
  RangeInputElement volumeSlider;
  RangeInputElement progressSlider;
  
  void enteredView() {
    super.enteredView();
    
    // Get all our elements.
    pausePlay = $["pausePlay"];
    volumeSlider = $["volumeSlider"];
    stream = $["stream"];
    progressSlider = $["progressSlider"];
    setCurrSongTime();

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
        print(document.activeElement.tagName);
        return document.activeElement.tagName != "TW-TURBO-WOOKIE";
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
  
  void playPause() {
    if(isPlaying)
      pause();
    else
      play();
  }
  
  void play() {
    pausePlay.classes.remove("paused");
    pausePlay.classes.add("playing");
    
    isPlaying = true;    
    setVolume(getVolume());
  }
  
  void pause() {
    pausePlay.classes.add("paused");
    pausePlay.classes.remove("playing");

    setVolume(0.0);
    isPlaying = false;
  }
  
  void resetStream() {
    stream.src = "/stream";
    setCurrSongTime();
    stream.play();
  }
  
  void setCurrSongTime() {
    Song.currentSong.then((Song currSong) {
      progressSlider.max = currSong.length.toString();
    });
  }
  
  void setVolume(double vol, [bool moveSlider = false]) {
    if(vol > 1.0)
      vol = 1.0;
    else if(vol < 0.0)
      vol = 0.0;
    
    window.localStorage["volume"] = vol.toString();
    
    if(isPlaying)
      stream.volume = vol;
    
    if(moveSlider) {
      volumeSlider.value = vol.toString();
    }
  }
  
  double getVolume() {
    return double.parse(volumeSlider.value);
  }
}