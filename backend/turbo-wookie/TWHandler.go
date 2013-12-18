package turbowookie

import (
  "encoding/json"
  "fmt"
  "github.com/gorilla/mux"
  "log"
  "net/http"
  "net/http/httputil"
  "net/url"
  "strconv"
  "time"
)

// TWHandler is our custom http.Handler used to actually do the HTTP stuff.
type TWHandler struct {
  // MpdClient is our MPD Client, used to tell MPD to do things. Important
  // things.
  MpdClient *TWMPDClient

  // ServerConfig is a map of configuration key/values found in
  // a config.yaml file.
  ServerConfig map[string]string

  // Router is a mux.Router, it's what really does all the HTTP stuff, we just
  // act as the interface. And the HandlerFuncs
  Router *mux.Router

  // updater is a channel used by our long poller/polar system. It contains
  // the message of what's been changed.
  updater chan string

  // pollerClients is the number of people currently connected to the long
  // poller.
  pollerClients int
}

// NewTWHandler creates a new TWHandler, using the passed in filename as a
// yaml file containing the server's configuation settings.
func NewTWHandler(filename string, serveDart, startMPD bool, portOverride int) (*TWHandler, error) {
  // make us a pointer to a handler.
  h := &TWHandler{}

  // attempt to read the passed in config file. See `yaml.go` for more info.
  config, err := ReadConfig(filename)
  if err != nil {
    return nil, err
  }

  if !(config["server_port"] != "9000" && portOverride == 9000) {
    config["server_port"] = strconv.Itoa(portOverride)
  }

  h.ServerConfig = config
  h.MpdClient = NewTWMPDClient(h.ServerConfig, startMPD) // see TWMPDClient.go

  // Make sure there's a server to connect to, and run some other startup
  // commands (like making sure there's music playing...).
  err = h.MpdClient.Startup()
  if err != nil {
    log.Fatal("Error running the TWMPDClient startup...\n", err)
  }

  // Actually make our HTTP Router
  h.Router = mux.NewRouter()

  // Let us play the MPD without having to deal with cross origin stuff.
  // Because cross origin is kinda a bitch.
  h.Router.HandleFunc("/stream", httputil.NewSingleHostReverseProxy(
    &url.URL{
      Scheme: "http",
      Host:   h.ServerConfig["mpd_domain"] + ":" + h.ServerConfig["mpd_http_port"],
      Path:   "/",
    }).ServeHTTP)

  h.Router.HandleFunc("/songs", h.listSongs)
  h.Router.HandleFunc("/artists", h.listArtists)
  h.Router.HandleFunc("/albums", h.listArtistAlbums)
  h.Router.HandleFunc("/current", h.getCurrentSong)
  h.Router.HandleFunc("/upcoming", h.getUpcomingSongs)
  h.Router.HandleFunc("/add", h.addSong)
  h.Router.HandleFunc("/polar", h.bear)

  // This needs to be last, otherwise it'll override all routes after it
  // because we're matching EVERYTHING.
  fileDir := h.ServerConfig["turbo_wookie_directory"] + "/frontend/turbo_wookie"
  if serveDart {
    fileDir += "/web"
  } else {
    fileDir += "/build"
  }
  h.Router.PathPrefix("/").Handler(http.FileServer(http.Dir(fileDir)))

  // setup our poller/polar stuff.
  h.updater = make(chan string)
  h.pollerClients = 0

  // nothing bad happened. Suprise!
  return h, nil
}

// Make TWHandler an HTTP.Handler. Hackily. Just pass up the underlying
// Router's function.
func (h *TWHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  h.Router.ServeHTTP(w, r)
}

// HandleFunc make TWHandler extendible...
// Same as ServeHTTP, just pass up the Router's function.
func (h *TWHandler) HandleFunc(path string, f func(w http.ResponseWriter, r *http.Request)) *mux.Route {
  return h.Router.HandleFunc(path, f)
}

// ListenAndServe serve up some TurboWookie. And setup an MPD Watcher to see
// when things happen to the stream. Because things sometimes happen to the
// stream.
func (h *TWHandler) ListenAndServe() error {
  // Setup a watcher.
  WatchMPD(h.ServerConfig["mpd_domain"]+":"+h.ServerConfig["mpd_control_port"], h)

  port := ":" + h.ServerConfig["server_port"]
  log.Println("Starting server on " + port)
  return http.ListenAndServe(port, h)
}

/************************
    HANDLER FUNCTIONS
************************/

// List all songs in the library, and information about those songs.
func (h *TWHandler) listSongs(w http.ResponseWriter, r *http.Request) {
  files, err := h.MpdClient.GetFiles()
  if err != nil {
    printError(w, "An error occured while processing your request", err)
    return
  }

  fmt.Fprintf(w, jsoniffy(files))
}

func (h *TWHandler) listArtists(w http.ResponseWriter, r *http.Request) {
  artists, err := h.MpdClient.GetArtists()
  if err != nil {
    printError(w, "An error occured while processing your request", err)
    return
  }

  fmt.Fprintf(w, jsoniffy(artists))
}

func (h *TWHandler) listArtistAlbums(w http.ResponseWriter, r *http.Request) {
  r.ParseForm()
  artist, ok := r.Form["artist"]
  var albums []string
  var err error
  if !ok {
    albums, err = h.MpdClient.GetAlbums("")
  } else {
    albums, err = h.MpdClient.GetAlbums(artist[0])
  }
  if err != nil {
    printError(w, "An error occured while processing your request", err)
    return
  }

  fmt.Fprintf(w, jsoniffy(albums))
}

// Return information about the currently playing song.
func (h *TWHandler) getCurrentSong(w http.ResponseWriter, r *http.Request) {
  currentSong, err := h.MpdClient.CurrentSong()
  if err != nil {
    printError(w, "Couldn't get current song info", err)
    return
  }

  fmt.Fprintf(w, jsoniffy(currentSong))
}

// Return a list of all upcoming songs in the playlist.
// As in, return `playlist[current song + 1 :]`.
func (h *TWHandler) getUpcomingSongs(w http.ResponseWriter, r *http.Request) {
  upcoming, err := h.MpdClient.GetUpcoming()
  if err != nil {
    printError(w, "Couldn't get upcoming playlist", err)
    return
  }

  fmt.Fprintf(w, jsoniffy(upcoming))
}

// Add a song to the playlist. Using the format
//    `/add?song=[FilePath of song]`
func (h *TWHandler) addSong(w http.ResponseWriter, r *http.Request) {
  // for some reason Go doesn't do this automatically.
  r.ParseForm()

  // Get the song from the GET request variables,
  // and check that there's actually something called `song` in the request.
  song, ok := r.Form["song"]
  if !ok {
    printError(w, "No song specified", nil)
    return
  }

  // Attempt to add the song to the playlist
  err := h.MpdClient.Add(song[0])
  if err != nil {
    printError(w, "Unknown song", err)
    return
  }

  // Return a simple note saying that we got the song
  m := make(map[string]string)
  m["note"] = "Added song: " + song[0]
  fmt.Fprintf(w, jsoniffy(m))

  // tell long pollers that the playlist changed.
  h.PolarChanged("playlist")
}

// Our long poller. Accessed through `/polar`.
// Clients connect to this, and wait for either five minutes (after which
// they probably reconnect) or until the server tells them something has
// changed.
//
// This is done so that clients don't need to make periodic requests
// asking for the current playlist.
func (h *TWHandler) bear(w http.ResponseWriter, r *http.Request) {
  // we got another live one.
  h.pollerClients += 1

  // Setup a timeout to make sure the client doesn't sit here forever.
  timeout := make(chan bool)
  defer func() { h.pollerClients -= 1 }()
  go func() {
    // if after five minutes nothing has changed, timeout and have the client
    // connect again.
    time.Sleep(5 * time.Minute)
    timeout <- true
  }()

  // Either the updater has news or the timeout expired.
  // Depending on which, tell the client something or nothing changed.
  select {
  case msg := <-h.updater:
    fmt.Fprintf(w, msg)
    if h.pollerClients > 1 {
      h.updater <- msg
    }
  case <-timeout:
    m := make(map[string]string)
    m["changed"] = "nothing"

    fmt.Fprintf(w, jsoniffy(m))
  }
}

/************************
    HELPER FUNCTIONS
************************/

// Print an error the the screen, and send a simple message to the client.
func printError(w http.ResponseWriter, msg string, err error) {
  log.Println("ERROR:", err)
  log.Println("Sending to client:", msg)
  fmt.Fprintf(w, msg+"\n")
}

// Turn things into JSON.
func jsoniffy(v interface{}) string {
  obj, err := json.MarshalIndent(v, "", "  ")
  if err != nil {
    log.Print("Couldn't turn something into JSON: ", v)
    log.Fatal(err)
  }

  return string(obj)
}

// PolarChanged tell clients connected to our long-poll system that something
// (element) has changed.
func (h *TWHandler) PolarChanged(element string) {
  if h.pollerClients < 1 {
    return
  }
  
  m2 := make(map[string]string)
  m2["changed"] = element
  h.updater <- jsoniffy(m2)
}
