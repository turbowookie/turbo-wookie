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

var mpd_conn *mpd.Client

func main() {
  // connect to MPD
  conn, err := mpd.Dial("tcp", "localhost:6600")
  if err != nil {
    log.Fatal(err)
  }
  defer conn.Close()
  mpd_conn = conn


  r := mux.NewRouter()
  r.HandleFunc("/stream", 
    httputil.NewSingleHostReverseProxy(&url.URL{Scheme:"http", Host: "localhost:8000", Path: "/"}).ServeHTTP)
  r.HandleFunc("/songs", listSongs)


  // this MUST go last!
  r.PathPrefix("/").Handler(http.FileServer(http.Dir("../frontend/turbo_wookie/web")))

  server := &http.Server{
    Addr: ":9000",
    Handler: r,
  }
  
  log.Println("Starting server on port 9000")
  server.ListenAndServe()
}

func listSongs(w http.ResponseWriter, r *http.Request) {
  // get all files from MPD
  mpdfiles, err := mpd_conn.GetFiles()
  if err != nil {
    log.Fatal(err)
  }

  files := make([]*id3.File, 0)
  for _, song := range mpdfiles {
    // grab the file on the filesystem
    file, err := os.Open("mpd/music/" + song)
    if err != nil {
      log.Fatal(err)
    }

    id3_file := id3.Read(file)
    files = append(files, id3_file)
  }

  files_json, err := json.MarshalIndent(files, "", "  ")

  fmt.Fprintf(w, string(files_json))
}