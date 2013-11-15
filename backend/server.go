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

  r.PathPrefix("/").Handler(http.FileServer(http.Dir("../frontend/turbo_wookie/web")))

  server := &http.Server{
    Addr: ":9000",
    Handler: r,
  }
  
  log.Println("Starting server on port 9000")
  server.ListenAndServe()
}

