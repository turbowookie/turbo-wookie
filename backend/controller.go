package main

import (
  "github.com/fhs/gompd/mpd"
  "fmt"
  //"log"
  //"time"
)

func main() {
  client := connect("localhost:6600")
  defer client.Close()

  files, _ := client.GetFiles()
  
  //fmt.Printf("%s\n", files)
  for _, song := range files {
    fmt.Printf("%s\n", song)
  }

  /*
  line := ""
  line1 := ""
  for {
    status, err := client.Status()
    if err != nil {
      log.Fatalln(err)
    }

    song, err := client.CurrentSong()
    if err != nil {
      log.Fatalln(err)
    }

    if status["state"] == "play" {
      line1 = fmt.Sprintf("%s - %s", song["Artist"], song["Title"])
    } else {
      line1 = fmt.Sprintf("State: %s", status["state"])
    }

    if line != line1 {
      line = line1
      fmt.Println(line)
    }

    time.Sleep(1e9)
  }
  */

  // do something awesome?
}

func connect(addr string) *mpd.Client {
  client, err := mpd.Dial("tcp", addr)
  if err != nil {
    return nil
  }

  return client
} 