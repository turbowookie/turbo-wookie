package main

import (
  //"fmt"
  "log"
  "github.com/gorilla/mux"
  "net/http"
  "net/http/httputil"
  "net/url"
  //"net"
  //"io"
)

func main() {
  r := mux.NewRouter()
  r.HandleFunc("/stream", 
    httputil.NewSingleHostReverseProxy(&url.URL{Scheme:"http", Host: "localhost:8000", Path: "/"}).ServeHTTP)
  r.HandleFunc("/", http.FileServer(http.Dir("../frontend/turbo_wookie/web/html")).ServeHTTP)

  http.Handle("/", r)

  log.Println("Starting server on port 9000")
  http.ListenAndServe(":9000", nil)
}

func StreamForwarder(w http.ResponseWriter, r *http.Request) {

}


func DefaultHandler(w http.ResponseWriter, r *http.Request) {
  // serve from `frontend/turbo_wookie/web/html`
}