package turbowookie

import (
	"github.com/turbowookie/gompd/mpd"
	"log"
)

type mpdWatcher struct {
	w    *mpd.Watcher
	host string
	h    *Handler
	c    chan bool
}

// WatchMPD starts up an MPD watcher, and does performs tasks when certain
// things happen. The biggest task is in telling the client things have changed
// using a long-poll system.
func WatchMPD(host string, handler *Handler) {
	w, err := mpd.NewWatcher("tcp", host, "")
	if err != nil {
		log.Fatal("Couldn't start watching MPD")
	}

	mw := new(mpdWatcher)
	mw.w = w
	mw.host = host
	mw.h = handler
	mw.c = make(chan bool)

	log.Println("Staring mpdWatcher for", host)

	go mw.onWatcherEvents()
	go mw.onWatcherErrors()
}

func (mw *mpdWatcher) onWatcherEvents() {
	for {
		select {
		case subsystem := <-mw.w.Event:
			if subsystem == "player" {
				//mw.queueSong()
				mw.h.MpdClient.QueueSong()
			}

			//log.Println("Subsystem changed:", subsystem)

			// alert the Handler that something in MPD has changed, so it can tell
			// the client.
			mw.h.PolarChanged(subsystem)
		case <-mw.c:
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
		mw.c <- true

		go mw.onWatcherEvents()
		go mw.onWatcherErrors()
	}
}
