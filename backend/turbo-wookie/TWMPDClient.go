package turbowookie

import (
  //"github.com/fhs/gompd/mpd"
  "github.com/dkuntz2/gompd/mpd"
  "log"
  "os/exec"
  "strconv"
  "time"
)

// TWMPDClient is a simpler layer over a gompd/mpd.Client.
type TWMPDClient struct {
  // Domain MPD's running on
  Domain string

  // Port MPD's running on
  Port string

  // Underlying command running MPD
  MpdCmd *exec.Cmd

  // configuration stuff
  config map[string]string
}

// NewTWMPDClient creates a new TWMPDClient.
// Takes in a config map (typically
// retreived from a config.yaml file), and a noStartMPD bool (which, if true
// will NOT start MPD . If it's false (and it should default to false), it will
// start MPD as expected).
func NewTWMPDClient(config map[string]string, noStartMPD bool) *TWMPDClient {
  c := new(TWMPDClient)
  c.config = config
  c.Domain = c.config["mpd_domain"]
  c.Port = c.config["mpd_control_port"]

  // Don't start MPD if `noStartMPD` is true.
  if !noStartMPD {
    c.MpdCmd = c.startMpd()
  }

  return c
}

/************************
    HELPER FUNCTIONS
************************/

// Start an MPD instance.
func (c *TWMPDClient) startMpd() *exec.Cmd {
  mpdCommand := c.config["mpd_command"]
  mpdConf := c.config["turbo_wookie_directory"] + "/" + c.config["mpd_subdirectory"] + "/" + "mpd.conf"

  // --no-daemon is for Linux, it tells MPD to run in the foreground, and keeps
  // it attached to cmd's underlying Process. Useful, so we can kill it later.
  // It also doesn't hurt Windows instances, so it's fine. Promise.
  cmd := exec.Command(mpdCommand, "--no-daemon", mpdConf)

  // Run the command in the backround
  err := cmd.Start()
  if err != nil {
    log.Fatal("Error running MPD command")
  }

  // Wait .1 seconds. Otherwise MPD hasn't started completely and we'll get some
  // Fatals saying we couldn't connect to MPD.
  time.Sleep(time.Second / 10)
  return cmd
}

// KillMpd kills the underlying MPD process.
func (c *TWMPDClient) KillMpd() {
  if c.MpdCmd != nil {
    c.MpdCmd.Process.Kill()
  }
}

// Connect to MPD.
// It just means there's slightly less typing involved.
func (c *TWMPDClient) getClient() (*mpd.Client, error) {
  client, err := mpd.Dial("tcp", c.toString())
  if err != nil {
    return nil, &tbError{Msg: "Couldn't connect to " + c.toString(), Err: err}
  }

  return client, nil
}

// simple toString of an MPD Client. Exits to make life easier in
// some small aspects.
func (c *TWMPDClient) toString() string {
  return c.Domain + ":" + c.Port
}

// Startup routine. Makes sure we can connect to MPD and that there's something
// playing.
func (c *TWMPDClient) Startup() error {
  client, err := c.getClient()
  if err != nil {
    return &tbError{Msg: "MPD isn't running.", Err: err}
  }
  defer client.Close()

  // check if client is playing
  attrs, err := client.Status()
  if err != nil {
    return &tbError{Msg: "Couldn't get status from client", Err: err}
  }

  // if we're not playing, play a random song
  if attrs["state"] != "play" {
    songs, err := client.GetFiles()
    if err != nil {
      return &tbError{Msg: "Couldn't get all files...", Err: err}
    }

    song := songs[random(0, len(songs))]
    if err := client.Add(song); err != nil {
      return &tbError{Msg: "Couldn't add song: " + song, Err: err}
    }

    plen, err := strconv.Atoi(attrs["playlistlength"])
    if err != nil {
      return &tbError{Msg: "Couldn't get playlistlength...", Err: err}
    }

    if err := client.Play(plen); err != nil {
      return &tbError{Msg: "Couldn't play song", Err: err}
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

// GetFiles returns a map of all songs in the library, and their stored
// metadata (artist, album, etc).
func (c *TWMPDClient) GetFiles() ([]map[string]string, error) {
  client, err := c.getClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()

  mpdFiles, err := client.ListAllInfo("/")
  if err != nil {
    return nil, &tbError{Msg: "Couldn't listallinfo from MPD", Err: err}
  }

  return attrsToMap(mpdFiles), nil
}

// CurrentSong returns information about the song currently playing.
func (c *TWMPDClient) CurrentSong() (map[string]string, error) {
  client, err := c.getClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()

  currentSong, err := client.CurrentSong()
  if err != nil {
    return nil, &tbError{Msg: "Couldn't get current song", Err: err}
  }

  return currentSong, nil
}

// GetUpcoming returns a list of all upcoming songs in the queue, and 
// their metadata.
func (c *TWMPDClient) GetUpcoming() ([]map[string]string, error) {
  currentSong, err := c.CurrentSong()
  if err != nil {
    return nil, &tbError{Msg: "Couldn't get current song info for upcoming list", Err: err}
  }

  pos, err := strconv.Atoi(currentSong["Pos"])
  if err != nil {
    return nil, &tbError{Msg: "Couldn't turn current song's position to int", Err: err}
  }

  playlist, err := c.GetPlaylist()
  if err != nil {
    return nil, err
  }

  return playlist[pos+1:], nil
}

// GetPlaylist returns the entire playlist queue, played and unplayed.
func (c *TWMPDClient) GetPlaylist() ([]map[string]string, error) {
  client, err := c.getClient()
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

// Add adds the specified uri to the playlist. uri can be a directory or file.
// uri must be relative to MPD's music directory.
func (c *TWMPDClient) Add(uri string) error {
  client, err := c.getClient()
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
