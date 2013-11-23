package turbowookie

import (
  //"github.com/fhs/gompd/mpd"
  "github.com/gorilla/mux"
  "net/http"
  "net/http/httputil"
  "net/url"
  "log"
  "fmt"
  "encoding/json"
)

type TBHandler struct {
  MpdClient TBMPDClient
  ServerConfig map[string]string
  Router *mux.Router
}

func NewTBHandler(filename string) (*TBHandler, error) {
  h := TBHandler{}
  config, err := ReadConfig(filename)
  if err != nil {
    return nil, err
  }

  h.ServerConfig = config

  h.MpdClient = NewTBMPDClient(h.ServerConfig)


  h.Router = mux.NewRouter()
  
  // Play MPD
  h.Router.HandleFunc("/stream", httputil.NewSingleHostReverseProxy(
    &url.URL{
      Scheme: "http",
      Host: h.ServerConfig["mpd_domain"] + ":" + h.ServerConfig["mpd_http_port"],
      Path: "/",
    }).ServeHTTP)

  h.Router.HandleFunc("/songs", h.listSongs)
  h.Router.HandleFunc("/current", h.getCurrentSong)
  h.Router.HandleFunc("/upcoming", h.getUpcomingSongs)
  h.Router.HandleFunc("/add", h.addSong)


  h.Router.PathPrefix("/").Handler(http.FileServer(http.Dir(h.ServerConfig["turbo_wookie_directory"] + "/frontend/turbo_wookie/web")))

  // TODO make work
  return &h, nil
}

// Make TBHandler an HTTP.Handler
func (h *TBHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
  h.Router.ServeHTTP(w, r)
}

// Make TBHandler extendible...
func (h *TBHandler) HandleFunc(path string, f func(w http.ResponseWriter, r *http.Request)) *mux.Route {
  return h.Router.HandleFunc(path, f)
}

func (h *TBHandler) listSongs(w http.ResponseWriter, r *http.Request) {
  files, err := h.MpdClient.GetFiles()
  if err != nil {
    printError(w, "An error occured while processing your request", err)
    return
  }

  fmt.Fprintf(w, jsoniffy(files))
}

func (h *TBHandler) getCurrentSong(w http.ResponseWriter, r *http.Request) {
  currentSong, err := h.MpdClient.CurrentSong()
  if err != nil {
    printError(w, "Couldn't get current song info", err)
    return
  }

  fmt.Fprintf(w, jsoniffy(currentSong))
}

func (h *TBHandler) getUpcomingSongs(w http.ResponseWriter, r *http.Request) {
  upcoming, err := h.MpdClient.GetUpcoming()
  if err != nil {
    printError(w, "Couldn't get upcoming playlist", err)
    return
  }

  fmt.Fprintf(w, jsoniffy(upcoming))
}

func (h *TBHandler) addSong(w http.ResponseWriter, r *http.Request) {
  r.ParseForm()
  song, ok := r.Form["song"]
  if !ok {
    printError(w, "No song specified", nil)
    return
  }

  err := h.MpdClient.Add(song[0])
  if err != nil {
    printError(w, "Unknown song", err)
    return
  }

  m := make(map[string]string)
  m["note"] = "Added song: " + song[0]
  fmt.Fprintf(w, jsoniffy(m))
}



/************************
    HELPER FUNCTIONS
************************/

func printError(w http.ResponseWriter, msg string, err error) {
  log.Println("ERROR: ", err)
  log.Println("Sending to client:", msg)
  fmt.Fprintf(w, msg + "\n")
}

func jsoniffy(v interface {}) string {
  obj, err := json.MarshalIndent(v, "", "  ")
  if err != nil {
    log.Print("Couldn't turn something into JSON: ", v)
    log.Fatal(err)
  }

  return string(obj)
}