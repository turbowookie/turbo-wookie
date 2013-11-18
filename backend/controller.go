package main

import (
  "github.com/fhs/gompd/mpd"
  "github.com/ascherkus/go-id3/src/id3"
  "os"
  "log"
  "encoding/json"
  "fmt"
)

type MusicFile struct {
  Name string
  Artist string
  Album string
}

func main() {
  client := connect("localhost:6600")
  defer client.Close()

  getCurrentSong(client)

}

func connect(addr string) *mpd.Client {
  client, err := mpd.Dial("tcp", addr)
  if err != nil {
    return nil
  }

  return client
} 

func listSongs(client *mpd.Client) {
  files, _ := client.GetFiles()

  // TODO: grab this from a config.yaml file
  const music_dir string = "mpd/music/"
  
  for _, song := range files {
    f, err := os.Open(music_dir + song)
    if err != nil {
      log.Fatal(err)
      break
    }

    id3_file := id3.Read(f)

    //log.Printf("%s by %s", id3_file.Name, id3_file.Artist)
    //mfile := MusicFile{id3_file.Name, id3_file.Artist, id3_file.}

    obj, _ := json.Marshal(id3_file)
    log.Print(string(obj))
  }
}

func getCurrentSong(client *mpd.Client) {
  csong, _ := client.CurrentSong()
  obj, _ := json.MarshalIndent(csong, "", "  ")
  fmt.Print(string(obj))
}