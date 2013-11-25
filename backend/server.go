package main

import (
  "log"
  "./turbo-wookie"
)

func main() {
  h, err := turbowookie.NewTWHandler("config.yaml")
  if err != nil {
    log.Fatal(err)
  }

  h.ListenAndServe()
}
