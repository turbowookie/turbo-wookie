package main

import (
  "./turbo-wookie"
  "log"
)

func main() {
  h, err := turbowookie.NewTWHandler("config.yaml")
  if err != nil {
    log.Fatal(err)
  }

  defer h.MpdClient.KillMpd()

  h.ListenAndServe()
}
