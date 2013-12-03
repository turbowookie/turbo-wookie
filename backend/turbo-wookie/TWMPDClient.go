package turbowookie

import (
  "github.com/ascherkus/go-id3/src/id3"
  //"github.com/fhs/gompd/mpd"
  "github.com/dkuntz2/gompd/mpd"
  "io"
  "log"
  "os/exec"
  "strconv"
  "time"
)

// Simpler layer over a gompd/mpd.Client.
type TWMPDClient struct {
  // Domain MPD's running on
  Domain string

  // Port MPD's running on
  Port string

  // Underlying command running MPD
  MpdCmd *exec.Cmd

  // configuration stuff
  config   map[string]string
  musicDir string
  //Watcher TWMPDWatcher
}

// Create a new TWMPDClient.
func NewTWMPDClient(config map[string]string) TWMPDClient {
  c := TWMPDClient{}
  c.config = config
  c.Domain = c.config["mpd_domain"]
  c.Port = c.config["mpd_control_port"]
  c.musicDir = c.config["turbo_wookie_directory"] + "/" +
    c.config["mpd_subdirectory"] + "/" + c.config["mpd_music_directory"] + "/"

  c.MpdCmd = c.startMPD()

  return c
}

/************************
    HELPER FUNCTIONS
************************/

// Start an MPD instance
func (c TWMPDClient) startMPD() *exec.Cmd {
  //log.Println("Starting MPD")
  mpdCommand := c.config["mpd_command"]
  mpdConf := c.config["turbo_wookie_directory"] + "/" + c.config["mpd_subdirectory"] + "/" + "mpd.conf"

  // --no-daemon is for Linux, it tells MPD to run in the foreground, and keeps
  // it attached to cmd's underlying Process. Useful, so we can kill it later.
  cmd := exec.Command(mpdCommand, "--no-daemon", mpdConf)

  // Run the command in the backround
  err := cmd.Start()
  if err != nil {
    log.Fatal("Error running MPD command")
  }

  // Wait 1 second. Otherwise MPD hasn't started completely and we'll get some
  // Fatals saying we couldn't connect to MPD.
  time.Sleep(time.Second)
  return cmd
}

// Kill the underlying MPD process.
func (c TWMPDClient) KillMpd() {
  c.MpdCmd.Process.Kill()
}

// Connect to MPD.
// It just means there's slightly less typing involved.
func (c TWMPDClient) GetClient() (*mpd.Client, error) {
  client, err := mpd.Dial("tcp", c.toString())
  if err != nil {
    return nil, &TBError{Msg: "Couldn't connect to " + c.toString(), Err: err}
  }

  return client, nil
}

// simple toString of an MPD Client. Exits to make life easier in
// some small aspects.
func (c TWMPDClient) toString() string {
  return c.Domain + ":" + c.Port
}

// Startup routine. Makes sure we can connect to MPD and that there's something
// playing.
func (c TWMPDClient) Startup() error {
  client, err := c.GetClient()
  if err != nil {
    return &TBError{Msg: "MPD isn't running.", Err: err}
  }
  defer client.Close()

  // check if client is playing
  attrs, err := client.Status()
  if err != nil {
    return &TBError{Msg: "Couldn't get status from client", Err: err}
  }

  // if we're not playing, play a random song
  if attrs["state"] != "play" {
    songs, err := client.GetFiles()
    if err != nil {
      return &TBError{Msg: "Couldn't get all files...", Err: err}
    }

    song := songs[random(0, len(songs))]
    if client.Add(song) != nil {
      return &TBErrorMsg{Msg: "Couldn't add song: " + song}
    }

    plen, err := strconv.Atoi(attrs["playlistlength"])
    if err != nil {
      return &TBError{Msg: "Couldn't get playlistlength...", Err: err}
    }

    if client.Play(plen) != nil {
      return &TBErrorMsg{Msg: "Couldn't play song"}
    }
  }

  return nil
}

// convert []mpd.Attrs to standard []map[string]string, because dealing with
// non typical types is annoying if you're outside that library, and Go doesn't
// consider types to be aliases, even if they are.
func attrsToMap(attrs []mpd.Attrs) []map[string]string {
  out := make([]map[string]string, 0)
  for i := 0; i < len(attrs); i++ {
    m := make(map[string]string)
    for k, v := range attrs[i] {
      m[k] = v
    }
    out = append(out, m)
  }

  return out
}

/*********************************
    THINGS THE TWHandler WANTS
*********************************/

// Return a all songs in the library, and their information (artist, album, etc).
func (c TWMPDClient) GetFiles() ([]map[string]string, error) {
  client, err := c.GetClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()

  mpdFiles, err := client.ListAllInfo("/")
  if err != nil {
    return nil, &TBError{Msg: "Couldn't listallinfo from MPD", Err: err}
  }

  return attrsToMap(mpdFiles), nil
}

// Return's information about the current song
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

// Returns all upcoming songs in the playlist, and their information.
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

  return playlist[pos+1:], nil
}

// Returns the entire playlist, played and unplayed.
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

// Add the specified uri to the playlist. uri can be a directory or file.
// uri must be relative to MPD's music directory.
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

  // try to automatically start playing if we aren't currently.
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

    if client.Play(plen-1) != nil {
      log.Println("Couldn't play song ", plen)
      return nil
    }
  }

  return nil
}
