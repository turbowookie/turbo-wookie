package turbowookie


type twError struct {
  Msg string
  Err error
}

func (e *twError) Error() string {
  return e.Msg + "\n\t" + e.Err.Error()
}

type twErrorMsg struct {
  Msg string
}

func (e *twErrorMsg) Error() string {
  return e.Msg
}


// backend player types
type MusicClient interface {
  Startup() error
  Shutdown()
  Add(uri string) error
  CurrentSong() (map[string]string, error)
  GetAlbums(artist string) ([]string, error)
  GetArtists() ([]string, error)
  GetFiles() ([]map[string]string, error)
  GetPlaylist() ([]map[string]string, error)
  GetSongs(artist, album string) ([]map[string]string, error)
  GetUpcoming() ([]map[string]string, error)
  QueueRandomSong()
}