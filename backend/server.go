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

  h.ListenAndServe()
}
