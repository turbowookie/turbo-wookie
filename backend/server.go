package main

import (
  "./turbo-wookie"
  "log"
  "os"
  "os/signal"
  "flag"
)

func main() {
  serveDart := flag.Bool("dart", false, "Include to serve dart code.")
  noStartMPD := flag.Bool("nompd", false, "Include to not start MPD.")
  flag.Parse()

  h, err := turbowookie.NewTWHandler("config.yaml", *serveDart, *noStartMPD)
  if err != nil {
    log.Fatal(err)
  }

  // This waits for SIGINT (Signal Interrupt) to come in, when a SIGINT is
  // received (typically through CTRL+C) we tell our MPDClient to kill the
  // MPD instance we started up, and we exit the program, status 1 ("A-OK!").
  if (*noStartMPD) {
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt)
    go func() {
      for _ = range c {
        h.MpdClient.KillMpd()
        os.Exit(1)
      }
    }()
  }

  // Listen for and serve HTTP requests
  h.ListenAndServe()
}
