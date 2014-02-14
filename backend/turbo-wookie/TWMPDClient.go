package turbowookie

import (
  //"github.com/fhs/gompd/mpd"
  "github.com/turbowookie/gompd/mpd"
  //"../../../gompd/mpd"
  "log"
  "os/exec"
  "strconv"
  "time"
  "io"
  "os"
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

  queueingSong bool
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
  c.queueingSong = false

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

  log.Println(mpdConf)

  // --no-daemon is for Linux, it tells MPD to run in the foreground, and keeps
  // it attached to cmd's underlying Process. Useful, so we can kill it later.
  // It also doesn't hurt Windows instances, so it's fine. Promise.
  cmd := exec.Command(mpdCommand, "--no-daemon", mpdConf)
  cmdOut, err := cmd.StdoutPipe()
  if err != nil {
    log.Fatal("Couldn't get MPD command's stdout pipe", err)
  }
  cmdErr, err := cmd.StderrPipe()
  if err != nil {
    log.Fatal("Couldn't get MPD command's stderr pipe", err)
  }

  go io.Copy(os.Stdout, cmdOut)
  go io.Copy(os.Stderr, cmdErr)

  // Run the command in the backround
  err = cmd.Start()
  if err != nil {
    log.Fatal("Error running MPD command")
  }


  log.Println("Starting MPD")

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

func (c *TWMPDClient) GetSongs(artist string, album string) ([]map[string]string, error) {
  client, err := c.getClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()

  var requestStr string

  if album != "" {
    requestStr = "artist \"" + artist + "\" album \"" + album + "\""
  } else {
    requestStr = "artist \"" + artist + "\""
  }

  mpdFiles, err := client.Find(requestStr)
  if err != nil {
    return nil, &tbError{Msg: "Couldn't search from MPD", Err: err}
  }

  return attrsToMap(mpdFiles), nil
}

func (c *TWMPDClient) GetArtists() ([]string, error) {
  client, err := c.getClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()

  artists, err := client.List("artist")
  if err != nil {
    return nil, err
  }

  return artists, nil
}

func (c *TWMPDClient) GetAlbums(artist string) (map[string][]string, error) {
  client, err := c.getClient()
  if err != nil {
    return nil, err
  }
  defer client.Close()
  
  albums := make(map[string][]string, 0)

  // Only get the artist requested.
  if len(artist) > 0 {
    artistAlbums, err := client.List("album artist \"" + artist + "\"")
    if err != nil {
      return nil, err
    }
    albums[artist] = artistAlbums

  } else {
    // Get all albums.
    artists, err := client.List("artist")
    if err != nil {
      return nil, err
    }
    
    // For earch artist, create list in the map, keyed to the artist and add
    // all the artist's albums to it.
    for _, artist := range artists {
      artistAlbums, err := client.List("album artist \"" + artist + "\"")
      if err != nil {
        return nil, err
      }
      albums[artist] = artistAlbums
    }
  }

  return albums, nil
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

  if len(currentSong) == 0 {
    c.QueueSong()
    return c.CurrentSong()
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

func (c *TWMPDClient) QueueSong() {
  if c.queueingSong {
    return
  }

  c.queueingSong = true
  defer func() { c.queueingSong = false }()

  client, err := c.getClient()
  if err != nil {
    log.Fatal("Couldn't get client", err)
  }
  defer client.Close()

  attrs, err := client.Status()
  if err != nil {
    log.Fatal("Couldn't get status from client.", err)
  }

  if attrs["state"] != "play" {
    songs, err := client.GetFiles()
    if err != nil {
      log.Fatal("Couldn't get all files...", err)
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
}
