import "dart:html";
import "package:polymer/polymer.dart";


@CustomTag("tw-controls")
class Controls extends PolymerElement {
  Controls.created() : super.created();
  
  @observable String streamSrc;
  @observable double volume;
  
  void attached() {
    super.attached();
    
    streamSrc = "/stream";
    volume = 1.0;
  }
  
  void mute() {
    volume = 0.0;
  }
  
  void unmute() {
    volume = 1.0;
  }
}