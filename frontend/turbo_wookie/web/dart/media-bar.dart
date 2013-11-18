import "package:polymer/polymer.dart";
import "dart:html";
import 'package:range_slider/range_slider.dart';

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

    // Load local storage settings
    double vol = double.parse(window.localStorage["volume"]);
    volumeSlider.value = vol;

    // Initially play the stream
    play();

    // Set the volume slider listeners.
    volumeSlider.$elmt.onChange.listen((CustomEvent e) {
      setVolume(e.detail["value"]);
    });
    volumeSlider.$elmt.onDragEnd.listen((MouseEvent e) {
      setVolume(volumeSlider.value);
      window.localStorage["volume"] = volumeSlider.value.toString();
    });

    // Tell the stream to keep playing when a song ends
    stream.onEmptied.listen((e) {
      stream.play();
    });

    testThings();
  }

  void testThings() {
    /*
    stream.onTimeUpdate.listen((e) {
      // Prints the current time of the stream:
      //print("Time: ${stream.currentTime}");
    });
    */

    stream.onLoadedMetadata.listen((e) {
      // Should print the title of the stream, but it is always blank.
      print("Title: ${stream.title}");
      // Duration is infinate
      print("Duration: ${stream.duration}");
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

  void setVolume(double vol) {
    if(isPlaying || vol == 0.0)
      stream.volume = vol;
  }
}