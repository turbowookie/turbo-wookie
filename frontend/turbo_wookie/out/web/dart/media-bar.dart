import "package:polymer/polymer.dart";
import "dart:html";
import "dart:web_audio";
import 'package:range_slider/range_slider.dart';

@CustomTag('media-bar')
class MediaBar extends PolymerElement {


  ButtonElement toggleSoundButton;
  RangeSlider volumeSlider;
  bool isPlaying;
  GainNode gainNode;

  MediaBar.created()
    : super.created() {
    isPlaying = true;
  }

  void enteredView() {
    super.enteredView();
    getShadowRoot("media-bar").applyAuthorStyles = true;

    toggleSoundButton = $["toggleSound"];
    volumeSlider = new RangeSlider($["volumeSlider"]);

    volumeSlider.$elmt.onChange.listen((CustomEvent e) {
      setVolume(e.detail["value"]);
    });
    //Was having issues with letting go of slider and music stopping
    //This listener fires after the user stops scrolling and sets value to slider value
    volumeSlider.$elmt.onDragEnd.listen((MouseEvent e) {
      setVolume(volumeSlider.value);
    });

  }


  void toggleSound(Event e) {
    ImageElement image = toggleSoundButton.children.first;
    if(isPlaying) {
      image.src = "img/note.svg";
      isPlaying = false;
      setVolume(0.0);
    }
    else {
      image.src = "img/rest.svg";
      isPlaying = true;
      setVolume(volumeSlider.value);
    }
  }

  void setGainNode(GainNode gainNode) {
    this.gainNode = gainNode;
    setVolume(volumeSlider.value);
  }

  void setVolume(double vol) {
    if(isPlaying || vol == 0.0)
      gainNode.gain.value = vol;
  }

  double getVolume() {
    return gainNode.gain.value;
  }

}