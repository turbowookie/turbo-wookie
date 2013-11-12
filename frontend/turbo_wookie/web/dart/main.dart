import "package:polymer/polymer.dart";
import "dart:html";
import "dart:async";
import "dart:web_audio";
import "media-bar.dart";

void main() {
  initPolymer();
  print("\t\t\t__TURBO WOOKIE__");

  String url = "http://shtuff.kuntz.co/notdeepnote.ogg";
  //String url = "10.212.119.247:8000";
  //String url = "http://radiomilwaukee.streamguys.net/live.m3u";

  playSound(url);
}

void playSound(String url) {
  AudioContext audioContext = new AudioContext();
  GainNode gainNode = audioContext.createGainNode();

  MediaBar mediaBar = querySelector("#mediaBar");
  mediaBar.setGainNode(gainNode);


  HttpRequest request = new HttpRequest();
  request.open("GET", url, async: true);
  request.responseType = "arraybuffer";
  request.onLoad.listen((data) {
    audioContext.decodeAudioData(request.response)
    .then((buffer) {
      playSound() {
        AudioBufferSourceNode source = audioContext.createBufferSource();
        source.connectNode(gainNode, 0, 0);
        gainNode.connectNode(audioContext.destination, 0, 0);
        source.buffer = buffer;
        source.noteOn(0);
      }

      playSound();

    });
  });

  request.send();
}

void onData(var event) {
  print(event);
}

void requestComplete(HttpRequest request) {
  if(request.status == 200) {
    print(request.response);
  }
  else
    print("Status Not 200: ${request.status}");
}

void onDataLoaded(String responseText) {
  print(responseText);
}