package turbowookie

import (
  "github.com/fhs/gompd/mpd"
)

type TBMPDClient struct {
  Client *mpd.Client
  Domain string 
  Port string
}

func NewTBMPDClient(domain string, port string) (TBMPDClient, error) {
  c := TBMPDClient{}
  c.Domain = domain
  c.Port = port

  err := c.Connect()

  return c, err
}

func (c TBMPDClient) Connect() error {
  client, err := mpd.Dial("tcp", c.toString())
  if err != nil {
    return &TBError{Msg: "Couldn't connect to " + c.toString(), Err: err}
  }

  c.Client = client
  return nil
}

func (c *TBMPDClient) toString() string {
  return c.Domain + ":" + c.Port
}