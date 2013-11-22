package main

import (
  "github.com/fhs/gompd/mpd"
  "github.com/ascherkus/go-id3/src/id3"
  "os"
  "log"
  "encoding/json"
  "fmt"
  "strconv"
  "time"
  "github.com/kylelemons/go-gypsy/yaml"
  "os/exec"
)

type MusicFile struct {
  Name string
  Artist string
  Album string
}

func main() {
  //testClient()
  //testWatcher()

  config, err := yaml.ReadFile("config.yaml")
  if err != nil {
    log.Fatal("Cannot read config file")
  }

  tbdir, err := config.Get("turbo_wookie_directory")
  if err != nil {
    log.Fatal("No key 'turbo_wookie_directory'.", err)
  }

  mpddir, err := config.Get("mpd_subdirectory")
  if err != nil {
    log.Fatal("No key 'mpd_subdirectory'.", err)
  }

  log.Println("MPD Starting!")
  cmd := exec.Command("mpd", tbdir + mpddir + "/mpd.conf")

  err = cmd.Run()

  time.Sleep(3 * time.Minute)

  if err != nil {
    log.Fatal("Could not start MPD Server!\n", err)
  }

  //defer stopMPD(cmd.Process)

}


func jsoniffy(v interface {}) string {
  obj, _ := json.MarshalIndent(v, "", "  ")
  return string(obj)
}



func testClient() {
  client := clientConnect("localhost:6600")
  defer client.Close()

  upcoming(client)

}

func clientConnect(addr string) *mpd.Client {
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

func upcoming(client *mpd.Client) {
  csong, _ := client.CurrentSong()
  pos, _ := strconv.Atoi(csong["Pos"])

  playlist, _ := client.PlaylistInfo(-1, -1)
  upcoming := playlist[pos:]

  fmt.Print(jsoniffy(upcoming))
}


///////////////////

func testWatcher() {
  w, _ := mpd.NewWatcher("tcp", ":6600", "")
  defer w.Close()

  go logWatcherErrors(w)
  go logWatcherEvents(w)

  time.Sleep(3 * time.Minute)
}

func logWatcherErrors(w *mpd.Watcher) {
  for err := range w.Error {
    log.Println("Error:", err)
  }
}

func logWatcherEvents(w *mpd.Watcher) {
  for subsystem := range w.Event {
    log.Println("Changed subsystem:", subsystem)
  }
}