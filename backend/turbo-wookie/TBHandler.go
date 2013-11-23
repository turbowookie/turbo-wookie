package turbowookie

import (
  //"github.com/fhs/gompd/mpd"
  "github.com/gorilla/mux"
  //"net/http"
)

type TBHandler struct {
  MpdClient TBMPDClient
  ServerConfig map[string]string
  Router mux.Router
}

func NewTBHandler(filename string) (*TBHandler, error) {
  h := TBHandler{}
  config, err := ReadConfig(filename)
  if err != nil {
    return nil, err
  }

  h.ServerConfig = config

  mpdClient, err := NewTBMPDClient(h.ServerConfig["mpd_domain"], h.ServerConfig["mpd_control_port"])
  h.MpdClient = mpdClient

  // TODO make work
  return &h, nil
}