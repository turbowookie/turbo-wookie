package turbowookie

import (
	"fmt"
	"github.com/turbowookie/gompd/mpd"
	"gopkg.in/gorp.v1"
	"io"
	"log"
	"os"
	"os/exec"
	"strconv"
	"time"
)

// MPDClient is a simpler layer over a gompd/mpd.Client.
type MPDClient struct {
	// Domain MPD's running on
	Domain string

	// Port MPD's running on
	Port string

	// Underlying command running MPD
	MpdCmd *exec.Cmd

	dbmap *gorp.DbMap

	// configuration stuff
	config map[string]string

	queueingSong bool
}

// NewMPDClient creates a new MPDClient.
// Takes in a config map (typically
// retreived from a config.yaml file), and a noStartMPD bool (which, if true
// will NOT start MPD . If it's false (and it should default to false), it will
// start MPD as expected).
func NewMPDClient(config map[string]string, noStartMPD bool) *MPDClient {
	c := new(MPDClient)
	c.config = config
	c.Domain = c.config["mpd_domain"]
	c.Port = c.config["mpd_control_port"]
	c.dbmap = InitDB()
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
func (c *MPDClient) startMpd() *exec.Cmd {
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
func (c *MPDClient) KillMpd() {
	if c.MpdCmd != nil {
		c.MpdCmd.Process.Kill()
	}
}

// Connect to MPD.
// It just means there's slightly less typing involved.
func (c *MPDClient) getClient() (*mpd.Client, error) {
	client, err := mpd.Dial("tcp", c.toString())
	if err != nil {
		return nil, &tbError{Msg: "Couldn't connect to " + c.toString(), Err: err}
	}

	return client, nil
}

// simple toString of an MPD Client. Exits to make life easier in
// some small aspects.
func (c *MPDClient) toString() string {
	return c.Domain + ":" + c.Port
}

// Startup routine. Makes sure we can connect to MPD and that there's something
// playing.
func (c *MPDClient) Startup() error {
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
    THINGS THE Handler WANTS
*********************************/

// GetFiles returns a map of all songs in the library, and their stored
// metadata (artist, album, etc).
func (c *MPDClient) GetFiles() ([]map[string]string, error) {
	var songs []Song
	_, err := c.dbmap.Select(&songs, "select * from Song order by Artist asc, Album asc")
	if err != nil {
		return nil, err
	}

	response := make([]map[string]string, len(songs))
	for i, song := range songs {
		response[i] = song.ToMap()
	}

	return response, nil
}

func (c *MPDClient) GetSongs(artist string, album string) ([]map[string]string, error) {
	var songs []Song
	var err error
	if album == "" {
		_, err = c.dbmap.Select(&songs, "select * from Song where Artist = ? order by Artist asc, Album asc", artist)
	} else {
		_, err = c.dbmap.Select(&songs, "select * from Song where Artist = ? and Album = ? order by Artist asc, Album asc", artist, album)
	}

	if err != nil {
		return nil, err
	}

	response := make([]map[string]string, len(songs))
	for i, song := range songs {
		response[i] = song.ToMap()
	}

	return response, nil
}

func (c *MPDClient) GetArtists() ([]string, error) {
	var artists []string
	_, err := c.dbmap.Select(&artists, "select distinct(Artist) from Song order by Artist asc")
	return artists, err
}

func (c *MPDClient) GetAlbums(artist string) (map[string][]string, error) {
	var songs []struct {
		Artist string
		Album  string
	}
	var err error

	if artist == "" {
		_, err = c.dbmap.Select(&songs, "select Artist, Album from Song group by Artist, Album order by Artist asc")
	} else {
		_, err = c.dbmap.Select(&songs, "select Artist, Album from Song where Artist = ? group by Artist, Album order by Artist asc", artist)
	}

	if err != nil {
		return nil, err
	}

	albums := make(map[string][]string, 0)

	for _, song := range songs {
		albumList, exists := albums[song.Artist]
		if !exists {
			albumList = make([]string, 0)
		}

		albums[song.Artist] = append(albumList, song.Album)
	}

	return albums, nil
}

// CurrentSong returns information about the song currently playing.
func (c *MPDClient) CurrentSong() (map[string]string, error) {
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
func (c *MPDClient) GetUpcoming() ([]map[string]string, error) {
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
func (c *MPDClient) GetPlaylist() ([]map[string]string, error) {
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
func (c *MPDClient) Add(uri string) error {
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

	result, err := c.dbmap.Exec("UPDATE Song SET PlayCount = PlayCount + 1 WHERE Uri = ?", uri)
	if err != nil {
		log.Println("Couldn't increment play count for", uri)
		log.Println(err)
	}

	lastUpdate, err := result.RowsAffected()
	if err != nil || lastUpdate != 1 {
		log.Println("Couldn't increment play count for", uri)
		log.Println(err)
	}

	return nil
}

func (c *MPDClient) QueueSong() {
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
		var song Song
		err := c.dbmap.SelectOne(&song, "select * from Song order by random() limit 1")
		if err != nil {
			log.Fatal(err)
		}

		if client.Add(song.Uri) != nil {
			log.Fatal("Couldn't add song", song.Uri)
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

func (c *MPDClient) Search(query string) ([]map[string]string, error) {
	client, err := c.getClient()
	if err != nil {
		log.Fatal("Couldn't get client", err)
	}
	defer client.Close()

	attrs, err := client.Search(query)
	if err != nil {
		log.Fatal("Couldn't search MPD", err)
	}

	response := attrsToMap(attrs)

	return response, nil
}

func (c *MPDClient) SearchSongs(query string) []map[string]string {
	likeQuery := fmt.Sprintf("%%%s%%", query)

	var songs []Song
	_, err := c.dbmap.Select(&songs, "select * from Song where Title like ?", likeQuery)
	if err != nil {
		log.Fatal("Couldn't search for song titles using query", likeQuery, "\n", err)
	}

	response := make([]map[string]string, 0)

	for _, song := range songs {
		response = append(response, song.ToMap())
	}

	return response
}

func (c *MPDClient) SearchAlbums(query string) []string {
	likeQuery := fmt.Sprintf("%%%s%%", query)

	var albums []string
	_, err := c.dbmap.Select(&albums, "select distinct(Album) from Song where Album like ?", likeQuery)
	if err != nil {
		log.Fatal("Couldn't search for album using query", likeQuery, "\n", err)
	}

	return albums
}

func (c *MPDClient) SearchArtists(query string) []string {
	likeQuery := fmt.Sprintf("%%%s%%", query)

	var artists []string
	_, err := c.dbmap.Select(&artists, "select distinct(Artist) from Song where Artist like ?", likeQuery)
	if err != nil {
		log.Fatal("Couldn't search for artist using query", likeQuery, "\n", err)
	}

	return artists
}

func (c *MPDClient) ScanLibrary() {
	client, err := c.getClient()
	if err != nil {
		log.Fatal("Couldn't get client", err)
	}
	defer client.Close()

	mpd_files, err := client.GetFiles()
	if err != nil {
		log.Fatal(err)
	}

	for _, file := range mpd_files {
		files_info, err := client.ListAllInfo(file)
		if err != nil {
			log.Fatal(err)
		}

		file_info := files_info[0]

		title := file_info["Title"]
		album := file_info["Album"]

		artist, is_set := file_info["AlbumArtist"]
		if !is_set {
			artist = file_info["Artist"]
		}

		if title == "" {
			continue
		}

		var song Song
		err = c.dbmap.SelectOne(&song, "select * from Song where Uri=?", file)
		if err != nil {
			song = Song{Title: title, Artist: artist, Album: album, PlayCount: 0, SkipCount: 0, Uri: file}
			c.dbmap.Insert(&song)
		}
	}
}
