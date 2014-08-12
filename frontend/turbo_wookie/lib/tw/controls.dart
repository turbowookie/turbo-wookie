import "dart:html";
import "package:polymer/polymer.dart";


@CustomTag("tw-controls")
class Controls extends PolymerElement {
  Controls.created() : super.created();
  
  @observable String streamSrc;
  double _oldVolume;
  AudioElement audio;
  @observable double volume;
  
  void attached() {
    super.attached();
    
    audio = $["audio"];
    streamSrc = "/stream";
    setVolume(vol: 100.0);
    
    audio.onEmptied.listen((e) => reset());
  }
  
  void setVolume({double vol}) {
    if(vol != null) {
      volume = vol;
    }
    
    audio.volume = volume / 100.0;
  }
  
  void mute() {
    audio.volume = 0.0;
  }
  
  void unmute() {
    audio.volume = volume;
  }
  
  void reset() {
    streamSrc = "/stream";
    audio.play();
  }
}