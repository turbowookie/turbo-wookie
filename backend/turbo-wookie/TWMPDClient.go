package turbowookie

import (
  "github.com/fhs/gompd/mpd"
  "github.com/ascherkus/go-id3/src/id3"
  "os"
  "io"
  "strconv"
  "log"
)

type TWMPDClient struct {
  Domain string 
  Port string
  config map[string]string
  musicDir string
  //Watcher TWMPDWatcher
}

func NewTWMPDClient(config map[string]string) (TWMPDClient) {
  c := TWMPDClient{}
  c.config = config
  c.Domain = c.config["mpd_domain"]
  c.Port = c.config["mpd_control_port"]

  c.musicDir = c.config["turbo_wookie_directory"] + "/" + 
    c.config["mpd_subdirectory"] + "/" + c.config["mpd_music_directory"] + "/"

  //c.Watcher = NewTWMPDWatcher(c.toString())

  return c
}

func (c TWMPDClient) GetClient() (*mpd.Client, error) {
  client, err := mpd.Dial("tcp", c.toString())
  if err != nil {
    return nil, &TBError{Msg: "Couldn't connect to " + c.toString(), Err: err}
  }

  return client, nil
}

func (c TWMPDClient) toString() string {
  return c.Domain + ":" + c.Port
}

func (c TWMPDClient) GetFiles() ([]*TBFile, error) {
  client, err := c.GetClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()

  mpdFiles, err := client.GetFiles()

  if err != nil {
    return nil, &TBError{Msg: "Couldn't get files.", Err: err}
  }

  files := make([]*TBFile, 0)

  for _, song := range mpdFiles {
    file, err := os.Open(c.musicDir + song)
    if err != nil {
      return nil, &TBError{Msg: "Couldn't open file: " + song, Err: err}
    }

    tbFile := tbFileRead(file, song)
    files = append(files, tbFile)
  }

  return files, nil
}

func (c TWMPDClient) CurrentSong() (map[string]string, error) {
  client, err := c.GetClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()

  currentSong, err := client.CurrentSong()
  if err != nil {
    return nil, &TBError{Msg: "Couldn't get current song", Err: err}
  }

  return currentSong, nil
}

func (c TWMPDClient) GetUpcoming() ([]map[string]string, error) {
  currentSong, err := c.CurrentSong()
  if err != nil {
    return nil, &TBError{Msg: "Couldn't get current song info for upcoming list", Err: err}
  }

  pos, err := strconv.Atoi(currentSong["Pos"])
  if err != nil {
    return nil, &TBError{Msg: "Couldn't turn current song's position to int", Err: err}
  }

  playlist, err := c.GetPlaylist()
  if err != nil {
    return nil, err
  }

  return playlist[pos + 1:], nil
}

func (c TWMPDClient) GetPlaylist() ([]map[string]string, error) {
  client, err := c.GetClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()

  playlistAsAttrs, err := client.PlaylistInfo(-1, -1)
  if err != nil {
    return nil, err
  }

  playlist := make([]map[string]string, 0)
  for _, li := range playlistAsAttrs {
    song := make(map[string]string)
    
    for k, v := range li {
      song[k] = v
    }

    playlist = append(playlist, song)
  }

  return playlist, nil
}

func (c TWMPDClient) Add(uri string) error {
  client, err := c.GetClient()
  if err != nil {
    return err
  }
  defer client.Close()

  err = client.Add(uri)
  if err != nil {
    return err
  }

  attrs, err := client.Status()
  if err != nil {
    log.Println("Couldn't get MPD's status.")
    return nil
  }

  if attrs["state"] != "play" {
    plen, err := strconv.Atoi(attrs["playlistlength"])
    if err != nil {
      log.Println("Couldn't get playlistlength...", err)
      return nil
    }

    if client.Play(plen - 1) != nil {
      log.Println("Couldn't play song ", plen)
      return nil
    }
  }

  return nil
}



// TBFiles are used sparingly...
type TBFile struct { id3.File; FilePath string; }
func tbFileRead(reader io.Reader, filePath string) *TBFile {
  id3File := id3.Read(reader)
  
  file := new(TBFile)
  file.Header = id3File.Header
  file.Name = id3File.Name
  file.Artist = id3File.Artist
  file.Album = id3File.Album
  file.Year = id3File.Year
  file.FilePath = filePath

  return file
}