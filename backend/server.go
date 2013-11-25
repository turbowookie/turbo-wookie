package main

import (
  "log"
  "./turbo-wookie"
)

func main() {
  h, err := turbowookie.NewTBHandler("config.yaml")
  if err != nil {
    log.Fatal(err)
  }

  h.ListenAndServe()
}
