library test;
import "dart:html";

class Test {

  static void printAllStreamListeners(AudioElement a, [bool annoyingPrints = false]) {
    a.onAbort.listen((e) {
      print("onAbort");
    });
    a.onCanPlayThrough.listen((e) {
      print("onCanPlayThrough");
    });
    a.onDurationChange.listen((e) {
      print("onDurationChange");
    });
    a.onEmptied.listen((e) {
      print("onEmptied");
    });
    a.onEnded.listen((e) {
      print("onEnded");
    });
    a.onError.listen((e) {
      print("onError");
    });
    a.onLoadedData.listen((e) {
      print("onLoadedData");
    });
    a.onLoadedMetadata.listen((e) {
      print("onLoadedMetadata");
    });
    a.onLoadStart.listen((e) {
      print("onLoadStart");
    });
    a.onPause.listen((e) {
      print("onPause");
    });
    a.onPlay.listen((e) {
      print("onPlay");
    });
    a.onPlaying.listen((e) {
      print("onPlaying");
    });
    a.onRateChange.listen((e) {
      print("onRateChange");
    });
    a.onSeeked.listen((e) {
      print("onSeeked");
    });
    a.onSeeking.listen((e) {
      print("onSeeking");
    });
    a.onStalled.listen((e) {
      print("onStalled");
    });
    a.onSuspend.listen((e) {
      print("onSuspend");
    });
    a.onVolumeChange.listen((e) {
      print("onVolumeChange");
    });
    a.onWaiting.listen((e) {
      print("onWaiting");
    });

    if(annoyingPrints) {
      a.onTimeUpdate.listen((e) {
        print("onTimeUpdate");
      });
      a.onProgress.listen((e) {
        print("onProgress");
      });
    }
  }
}