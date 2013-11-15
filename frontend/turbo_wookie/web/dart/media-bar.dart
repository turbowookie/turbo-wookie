import "package:polymer/polymer.dart";
import "dart:html";
import 'package:range_slider/range_slider.dart';

@CustomTag('media-bar')
class MediaBar extends PolymerElement {


  ButtonElement toggleSoundButton;
  RangeSlider volumeSlider;
  bool isPlaying;
  AudioElement stream;

  MediaBar.created()
    : super.created() {
    isPlaying = false;
  }

  void enteredView() {
    super.enteredView();
    getShadowRoot("media-bar").applyAuthorStyles = true;

    toggleSoundButton = $["toggleSound"];
    volumeSlider = new RangeSlider($["volumeSlider"]);
    stream = $["audioElement"];

    volumeSlider.$elmt.onChange.listen((CustomEvent e) {
      setVolume(e.detail["value"]);
    });
    //Was having issues with letting go of slider and music stopping
    //This listener fires after the user stops scrolling and sets value to slider value
    volumeSlider.$elmt.onDragEnd.listen((MouseEvent e) {
      setVolume(volumeSlider.value);
    });
    toggleSound(null);

    stream.onChange.listen((e) {
      toggleSound(e);
      toggleSound(e);
      stream.currentTime = 0;
    });
    stream.onEnded.listen((e) {
      toggleSound(e);
      toggleSound(e);
      stream.currentTime = 0;
    });
  }


  void toggleSound(Event e) {
    ImageElement image = toggleSoundButton.children.first;
    if(isPlaying) {
      image.src = "img/note.svg";
      isPlaying = false;
      setVolume(0.0);
      stream.pause();
    }
    else {
      image.src = "img/rest.svg";
      isPlaying = true;
      setVolume(volumeSlider.value);
      stream.play();
    }
  }

  void setVolume(double vol) {
    if(isPlaying || vol == 0.0)
      stream.volume = vol;
  }
}