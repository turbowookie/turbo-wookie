package main

import (
  "log"
  "github.com/gorilla/mux"
  "net/http"
  "net/http/httputil"
  "net/url"
  "github.com/fhs/gompd/mpd"
  "github.com/ascherkus/go-id3/src/id3"
  "os"
  "fmt"
  "encoding/json"
)

// TODO: consider if global is really the best idea, or if we should 
//       make some classes, or something...
var mpd_conn *mpd.Client


func main() {

  // TODO: functionize?
  // connect to MPD
  conn, err := mpd.Dial("tcp", "localhost:6600")
  
  // if we can't connect to MPD everything's fucked, nothing's going to work
  // kill all humans, and die, respectfully, after explaining what the issue
  // is.
  if err != nil {
    log.Fatal(err)
    log.Println("\n\nServer quiting because it can't connect to MPD");
    return
  }
  defer conn.Close()

  // set global mpd_conn to our new connection.
  mpd_conn = conn

  // create a new mux router for our server.
  r := mux.NewRouter()

  // requests to `/stream` are proxied to the MPD httpd.
  r.HandleFunc("/stream", 
    httputil.NewSingleHostReverseProxy(&url.URL{Scheme:"http", Host: "localhost:8000", Path: "/"}).ServeHTTP)

  // list all songs
  r.HandleFunc("/songs", listSongs)

  r.HandleFunc("/current", getCurrentSong)

  // This MUST go last! It takes precidence over any after it, meaning
  // the server will try to serve a file, which most likely doesn't exist,
  // and will 404.
  //
  // serve up the frontend files.
  r.PathPrefix("/").Handler(http.FileServer(http.Dir("../frontend/turbo_wookie/web")))

  // create a new http.Server
  server := &http.Server{
    Addr: ":9000",
    Handler: r,
  }
  
  log.Println("Starting server on port 9000")

  // sit, waiting, like a hunter, spying on its prey.
  server.ListenAndServe()
}

func jsoniffy(v interface {}) string {
  obj, err := json.MarshalIndent(v, "", "  ")
  if err != nil {
    log.Print("Couldn't turn something into JSON: ", v)
    log.Fatal(err)
  }

  return string(obj)
}

func listSongs(w http.ResponseWriter, r *http.Request) {
  // get all files from MPD
  mpdfiles, err := mpd_conn.GetFiles()
  if err != nil {
    log.Println("Couldn't get a list of files...")
    log.Fatal(err)
  }

  // create a slice of id3.File s
  files := make([]*id3.File, 0)

  for _, song := range mpdfiles {
    // grab the file on the filesystem
    file, err := os.Open("mpd/music/" + song)
    if err != nil {
      log.Println("Couldn't open file: " + song)
      log.Fatal(err)
    }

    // add the current file to our slice
    id3_file := id3.Read(file)
    files = append(files, id3_file)
  }

  // turn the files slice into some json
  files_json, err := json.MarshalIndent(files, "", "  ")
  if err != nil {
    log.Println("Couldn't turn files into json")
    log.Fatal(err)
  }

  // send the json to the client.
  fmt.Fprintf(w, string(files_json))
}

func getCurrentSong(w http.ResponseWriter, r *http.Request) {
  currentSong, err := mpd_conn.CurrentSong()
  if err != nil {
    log.Println("Couldn't get current song info")
    log.Fatal(err)
  }

  fmt.Fprintf(w, jsoniffy(currentSong))
}

