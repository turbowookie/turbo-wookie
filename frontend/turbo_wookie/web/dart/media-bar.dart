import "package:polymer/polymer.dart";
import "dart:html";
import 'package:range_slider/range_slider.dart';

@CustomTag('media-bar')
class MediaBar extends PolymerElement {


  ButtonElement toggleSoundButton;
  RangeSlider volumeSlider;
  bool isPlaying;

  MediaBar.created() : super.created();

  void enteredView() {
    super.enteredView();
    getShadowRoot("media-bar").applyAuthorStyles = true;

    toggleSoundButton = $["toggleSound"];
    volumeSlider = new RangeSlider($["volumeSlider"]);

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
    print(vol);
  }

}