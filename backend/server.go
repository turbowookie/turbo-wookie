package main

import (
  "./turbo-wookie"
  "flag"
  "log"
  "os"
  "os/signal"
  "bufio"
  "net"
  "fmt"
  "strings"
)

func main() {
  log.SetPrefix("[Turbo Wookie] ")
  

  // Parse out our flags
  serveDart := flag.Bool("dart", false, "Include to serve dart code.")
  noStartMPD := flag.Bool("nompd", false, "Include to not start MPD.")
  configFile := flag.String("config", "config.yaml", "Location of a Turbo Wookie configuration file.")
  portOverride := flag.Int("port", 9000, "Force override Turbo Wookie's port.")

  flag.Parse()

  // create a new Turbo Wookie Handler, using our flags.
  h, err := turbowookie.NewTWHandler(*configFile, *serveDart, *noStartMPD, *portOverride)
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
        h.MpdClient.Shutdown()
        os.Exit(1)
      }
    }()
  }

  go func() {
    for {
      talkToMPD()
    }
  }()

  // Listen for and serve HTTP requests
  if err := h.ListenAndServe(); err != nil {
    log.Println(err)
  }
}

// talkToMPD reads from stdin and sends the inputted text to MPD.
// Valid commands are anything permitted in the MPD protocol.
// The protocol reference can be found at http://www.musicpd.org/doc/protocol/index.html
func talkToMPD() {
  //fmt.Print("\n> ")
  //fmt.Print("\n")

  // Read from the stdin.
  clientReader := bufio.NewReader(os.Stdin)
  requestBytes, _, _ := clientReader.ReadLine()
  request := string(requestBytes)

  // Once we have read, create a connection to MPD.
  conn, err := net.Dial("tcp", "localhost:6600")
  checkErr(err)

  // Write our response to MPD.
  fmt.Fprintf(conn, request + "\n")

  // Read from MPD.
  reader := bufio.NewReader(conn)
  for {
    response, err := reader.ReadString('\n')
    checkErr(err)

    // Using fmt to print a response because we don't care about time.
    fmt.Print(response)

    // If the request was good, MPD's response will end with "OK\n"
    // Otherwise, the response will start with "ACK [<num>@<num>] <error>"
    if strings.HasSuffix(response, "OK\n") {
      break
    } else if strings.HasPrefix(response, "ACK [") {
      break
    }
  }
}

// I got sick of checking for errors after every function call, so I did this.
func checkErr(err error) {
  if err != nil {
    log.Println("Error: %s", err.Error())
    os.Exit(1)
  }
}