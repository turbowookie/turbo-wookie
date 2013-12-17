package turbowookie

import (
  "github.com/dkuntz2/gompd/mpd"
  "log"
  "strconv"
  "time"
)

type mpdWatcher struct {
  w    *mpd.Watcher
  host string
  h    *TWHandler
}

// WatchMPD starts up an MPD watcher, and does performs tasks when certain
// things happen. The biggest task is in telling the client things have changed
// using a long-poll system.
func WatchMPD(host string, handler *TWHandler) {
  w, err := mpd.NewWatcher("tcp", host, "")
  if err != nil {
    log.Fatal("Couldn't start watching MPD")
  }

  mw := new(mpdWatcher)
  mw.w = w
  mw.host = host
  mw.h = handler

  log.Println("Staring mpdWatcher for", host)

  go mw.logWatcherEvents()
  go mw.logWatcherErrors()
}

func (mw *mpdWatcher) logWatcherEvents() {
  for subsystem := range mw.w.Event {
    if subsystem == "player" {
      mw.queueSong()
    }

    // alert the TWHandler that something in MPD has changed, so it can tell
    // the client.
    mw.h.PolarChanged(subsystem)
  }
}

func (mw *mpdWatcher) logWatcherErrors() {
  for err := range mw.w.Error {
    log.Println("MPD Watcher Error!\n", err)
    time.Sleep(time.Second * 15)
  }
}

func (mw *mpdWatcher) queueSong() {
  client, err := mpd.Dial("tcp", mw.host)
  if err != nil {
    log.Fatal("Couldn't connect to MPD...", err)
  }

  attrs, err := client.Status()
  if err != nil {
    log.Fatal("Couldn't get status from client.", err)
  }

  if attrs["state"] != "play" {
    songs, err := client.GetFiles()
    if err != nil {
      log.Fatal("Couldn't get all files...", err)
    }

    song := songs[random(0, len(songs))]
    if client.Add(song) != nil {
      log.Fatal("Couldn't add song:", song)
    }

    plen, err := strconv.Atoi(attrs["playlistlength"])
    if err != nil {
      log.Fatal("Couldn't get playlistlength...", err)
    }

    if client.Play(plen) != nil {
      log.Fatal("Couldn't play song")
    }
  }

  client.Close()
}
