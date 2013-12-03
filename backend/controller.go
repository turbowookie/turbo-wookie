package main

import (
  "encoding/json"
  "fmt"
  "github.com/ascherkus/go-id3/src/id3"
  //"github.com/fhs/gompd/mpd"
  //"github.com/dkuntz2/gompd/mpd"
  "../../gompd/mpd"
  "log"
  "os"
  "strconv"
  "time"
  //"github.com/kylelemons/go-gypsy/yaml"
  //"os/exec"
  "math/rand"
)

type MusicFile struct {
  Name   string
  Artist string
  Album  string
}

func main() {
  testClient()
  //testWatcher()
}

func jsoniffy(v interface{}) string {
  obj, _ := json.MarshalIndent(v, "", "  ")
  return string(obj)
}

func testClient() {
  client := clientConnect("localhost:6600")
  defer client.Close()

  plinfo(client)
  //move(client, 1, 4)
}

func clientConnect(addr string) *mpd.Client {
  client, err := mpd.Dial("tcp", addr)
  if err != nil {
    return nil
  }

  return client
}

func move(c *mpd.Client, id, pos int) {
  err := c.Move(id, -1, pos)
  if err != nil {
    log.Println(err)
  }
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

func plinfo(client *mpd.Client) {
  /*attrs, _ := client.PlaylistInfo(-1, -1)
    for _, song := range attrs {
      fmt.Println(song)
    }*/

  attrs, _ := client.ListAllInfo("/")
  for _, song := range attrs {
    fmt.Println(song, "\n")
  }
}

///////////////////

func testWatcher() {
  w, err := mpd.NewWatcher("tcp", ":6600", "")
  if err != nil {
    log.Fatal("Couldn't start watching mpd...\n", err)
  }
  defer w.Close()

  go logWatcherErrors(w)
  go logWatcherEvents(w)

  time.Sleep(3 * time.Minute)
  return
}

func logWatcherErrors(w *mpd.Watcher) {
  for err := range w.Error {
    log.Println("Error:", err)
  }
}

func logWatcherEvents(w *mpd.Watcher) {
  for subsystem := range w.Event {
    log.Println("Changed subsystem:", subsystem)

    /*
       if subsystem == "player" {
         client := clientConnect("localhost:6600")
         attrs, err := client.Status()
         if err != nil {
           log.Fatal("Couldn't get status...", err)
         }


         if attrs["state"] != "play" {
           for k, v := range attrs {
             fmt.Println("attrs[" + k + "] = " + v)
           }

           songs, err := client.GetFiles()
           if err != nil {
             log.Fatal("Couldn't get files...", err)
           }

           song := songs[random(0, len(songs))]
           if client.Add(song) != nil {
             log.Fatal("Couldn't add song:", song)
           }

           plen, err := strconv.Atoi(attrs["playlistlength"])
           if err != nil {
             log.Fatal("Couldn't get playlistlength...", err)
           }

           if client.Play(plen) != nil {
             log.Fatal("Couldn't play song")
           }
         }

         client.Close()
       }
    */
  }
}

func random(min, max int) int {
  rand.Seed(time.Now().Unix())
  return rand.Intn(max-min) + min
}

// PlaylistInfo returns attributes for songs in the current playlist. If
// both start and end are negative, it does this for all songs in
// playlist. If end is negative but start is positive, it does it for the
// song at position start. If both start and end are positive, it does it
// for positions in range [start, end).
/*
func (c *Client) PlaylistInfo(start, end int) (pls []Attrs, err error) {
  if start < 0 && end >= 0 {
    return nil, errors.New("negative start index")
  }
  if start >= 0 && end < 0 {
    id, err := c.cmd("playlistinfo %d", start)
    if err != nil {
      return nil, err
    }
    c.text.StartResponse(id)
    defer c.text.EndResponse(id)
    return c.readAttrsList("file")
  }
  id, err := c.cmd("playlistinfo")
  if err != nil {
    return nil, err
  }
  c.text.StartResponse(id)
  defer c.text.EndResponse(id)
  pls, err = c.readAttrsList("file")
  if err != nil || start < 0 || end < 0 {
    return
  }
  return pls[start:end], nil
}
*/
