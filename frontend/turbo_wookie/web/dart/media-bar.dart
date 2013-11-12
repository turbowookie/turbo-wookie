import "package:polymer/polymer.dart";
import "dart:html";
import "dart:web_audio";
import 'package:range_slider/range_slider.dart';

@CustomTag('media-bar')
class MediaBar extends PolymerElement {


  ButtonElement toggleSoundButton;
  RangeSlider volumeSlider;
  bool isPlaying;
  AudioContext audioContext;
  GainNode gainNode;

  MediaBar.created() : super.created();

  void enteredView() {
    super.enteredView();
    getShadowRoot("media-bar").applyAuthorStyles = true;

    toggleSoundButton = $["toggleSound"];
    volumeSlider = new RangeSlider($["volumeSlider"]);
    changeVolume(volumeSlider.value);
    changeVolume(50.0);

    volumeSlider.$elmt.onChange.listen((CustomEvent e){
      changeVolume(e.detail["value"]);
    });

    isPlaying = true;
  }


  void toggleSound(Event e) {
    ImageElement image = toggleSoundButton.children.first;
    if(isPlaying) {
      image.src = "../img/note.svg";
    }
    else
      image.src = "../img/rest.svg";

    isPlaying = !isPlaying;
  }

  void changeVolume(double vol) {
    gainNode.gain.value = vol / 100;
  }

}