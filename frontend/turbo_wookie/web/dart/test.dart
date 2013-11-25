library test;
import "dart:html";

/**
 * This is a class for testing things!
 *
 * This isn't really unit testing, but more of a testing what
 * Dart can do type of thing.
 *
 * Things that could possibly need to test and could take a while
 * to code should go here so we don't have to type it over and over.
 */
class Test {

  /**
   * This will print all stream events of an AudioElement.
   *
   * annoyingEvents - These are the events that will basically spam
   * your console with prints (onTimeUpdate and onProgress).
   * You probably don't want this to be true, but it's here if you want to.
   */
  static void printAllStreamEvents(AudioElement a, [bool annoyingEvents = false]) {
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

    if(annoyingEvents) {
      a.onTimeUpdate.listen((e) {
        print("onTimeUpdate");
      });
      a.onProgress.listen((e) {
        print("onProgress");
      });
    }
  }
}