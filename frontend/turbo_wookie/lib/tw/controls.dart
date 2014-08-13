library TurboWookie.Controls;

import "dart:html";
import "package:polymer/polymer.dart";


@CustomTag("tw-controls")
class Controls extends PolymerElement {
  Controls.created() : super.created();
  
  static final String PLAY_ICON = "packages/turbo_wookie/tw/images/volume-mute.svg";
  static final String MUTE_ICON = "packages/turbo_wookie/tw/images/volume.svg";
  @observable String streamSrc;
  double _oldVolume;
  AudioElement audio;
  @observable double volume;
  @observable String pausePlayIcon;
  bool isPlaying;
  
  void attached() {
    super.attached();
    
    audio = $["audio"];
    streamSrc = "/stream";
    isPlaying = true;
    pausePlayIcon = MUTE_ICON;
    
    var vol = double.parse(window.localStorage["volume"], (_) => 100.0);
    setVolume(vol: vol);
    
    audio.onEmptied.listen((e) => reset());
  }
  
  void setVolume({double vol}) {
    if(!isPlaying) return;
    
    if(vol != null) {
      volume = vol;
    }
    
    audio.volume = volume / 100.0;
    window.localStorage["volume"] = volume.toString();
  }
  
  void mute() {
    isPlaying = false;
    audio.volume = 0.0;
    pausePlayIcon = PLAY_ICON;
  }
  
  void unmute() {
    isPlaying = true;
    setVolume(vol: volume);
    pausePlayIcon = MUTE_ICON;
  }
  
  void toggleSound() {
    if(isPlaying)
      mute();
    else
      unmute();
  }
  
  void reset() {
    streamSrc = "/stream";
    audio.play();
  }
}