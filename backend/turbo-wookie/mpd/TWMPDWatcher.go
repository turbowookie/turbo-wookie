package mpd

import (
  gompd "github.com/turbowookie/gompd/mpd"
  "log"
)

type mpdWatcher struct {
  w    *gompd.Watcher
  host string
  
  handlerChan    chan string
  resetChan    chan bool
}

// WatchMPD starts up an MPD watcher, and does performs tasks when certain
// things happen. The biggest task is in telling the client things have changed
// using a long-poll system.
func WatchMPD(host string, handlerChan chan string) {
  w, err := gompd.NewWatcher("tcp", host, "")
  if err != nil {
    log.Fatal("Couldn't start watching MPD")
  }

  mw := new(mpdWatcher)
  mw.w = w
  mw.host = host
  mw.handlerChan = handlerChan
  mw.resetChan = make(chan bool)

  log.Println("Staring mpdWatcher for", host)

  go mw.onWatcherEvents()
  go mw.onWatcherErrors()
}

func (mw *mpdWatcher) onWatcherEvents() {
  for {
    select {
    case subsystem := <-mw.w.Event:
      mw.handlerChan <- subsystem
    case <-mw.resetChan:
      break
    }
  }
}

func (mw *mpdWatcher) onWatcherErrors() {
  for err := range mw.w.Error {
    log.Println("MPD Watcher Error!\n", err)

    mw.restart()
    break
  }
}

func (mw *mpdWatcher) restart() {
  log.Println("Restarting MPD Watcher")
  if err := mw.w.Close(); err != nil {
    log.Fatal("Error closing mpd.Watcher\n\t", err)
  } else {
    mw.resetChan <- true

    go mw.onWatcherEvents()
    go mw.onWatcherErrors()
  }
}
