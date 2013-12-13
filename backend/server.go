package main

import (
  "./turbo-wookie"
  "flag"
  "log"
  "os"
  "os/signal"
)

func main() {
  // Parse out our flags
  serveDart := flag.Bool("dart", false, "Include to serve dart code.")
  noStartMPD := flag.Bool("nompd", false, "Include to not start MPD.")
  configFile := flag.String("config", "config.yaml", "Location of a Turbo Wookie configuration file.")

  flag.Parse()

  // create a new Turbo Wookie Handler, using our flags.
  h, err := turbowookie.NewTWHandler(*configFile, *serveDart, *noStartMPD)
  if err != nil {
    log.Fatal(err)
  }

  // This waits for SIGINT (Signal Interrupt) to come in, when a SIGINT is
  // received (typically through CTRL+C) we tell our MPDClient to kill the
  // MPD instance we started up, and we exit the program, status 1 ("A-OK!").
  if *noStartMPD {
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
