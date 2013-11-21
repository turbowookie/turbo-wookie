package main

import (
  "log"
  "github.com/gorilla/mux"
  "net/http"
  "net/http/httputil"
  "net/url"
  "github.com/fhs/gompd/mpd"
  "github.com/ascherkus/go-id3/src/id3"
  "os"
  "fmt"
  "encoding/json"
  "strconv"
  "time"
  "io"
  "os/exec"
  "github.com/kylelemons/go-gypsy/yaml"
)

// TODO: consider if global is really the best idea, or if we should 
//       make some classes, or something...
var mpd_conn *mpd.Client


func main() {	
	//get yaml config file info
	file, err := yaml.ReadFile("config.yaml")
	if err != nil {
      log.Fatal("Cannot read config.yaml")
      return
   }
   
   //just pull out the mpc command from config.yaml
   mpdCommand, err := file.Get("mpd_command")
   if err != nil {
      log.Fatal("could not get mpc command from config.yaml")
      return
   }
  
	//start up MPD
	go startMpd(mpdCommand)
  // setup our global MPD connection
  mpd_conn = mpdConnect("localhost:6600")
  defer mpd_conn.Close()

  if mpd_conn == nil {
    log.Fatal("MPD Connection is nil!")
  }


  // create a new mux router for our server.
  r := mux.NewRouter()

  // requests to `/stream` are proxied to the MPD httpd.
  r.HandleFunc("/stream", 
    httputil.NewSingleHostReverseProxy(
      &url.URL{
        Scheme:"http", 
        Host: "localhost:8000", 
        Path: "/",
      }).ServeHTTP)

  r.HandleFunc("/songs", listSongs)
  r.HandleFunc("/current", getCurrentSong)
  r.HandleFunc("/upcoming", getUpcomingSongs)

  // This MUST go last! It takes precidence over any after it, meaning
  // the server will try to serve a file, which most likely doesn't exist,
  // and will 404.
  //
  // serve up the frontend files.
  r.PathPrefix("/").Handler(http.FileServer(http.Dir("../frontend/turbo_wookie/web")))


  // sit, waiting, like a hunter, spying on its prey.
  log.Println("Starting server on port 9000")
  http.ListenAndServe(":9000", r)
}


/********************
  Handler Functions
 ********************/

// return all songs known to MPD to the client.
func listSongs(w http.ResponseWriter, r *http.Request) {
  // get all files from MPD
  mpdfiles, err := mpd_conn.GetFiles()
  if err != nil {
    count := 0

    for err != nil && count < 10 {
      time.Sleep(10)

      mpdfiles, err = mpd_conn.GetFiles()
      count ++
    }

    if err != nil {
      error(w, "Couldn't get a list of files...", err)
      return
    }
  }

  // create a slice of id3.File s
  //files := make([]*id3.File, 0)
  files := make([]*TBFile, 0)

  for _, song := range mpdfiles {
    // grab the file on the filesystem
    file, err := os.Open("mpd/music/" + song)
    if err != nil {
      error(w, "Couldn't open file: " + song, err)
      return
    }

    // add the current file to our slice
    id3_file := id3Read(file, song)
    files = append(files, id3_file)
  }

  // send the json to the client.
  fmt.Fprintf(w, jsoniffy(files))
}


// Return a JSON representation of the currently playing song.
func getCurrentSong(w http.ResponseWriter, r *http.Request) {
  currentSong, err := mpd_conn.CurrentSong()
  if err != nil {

    count := 0;
    for err != nil && count < 10 {
      time.Sleep(10)

      currentSong, err = mpd_conn.CurrentSong()
      count ++
    }

    if err != nil {
      error(w, "Couldn't get current song info for upcoming list", err)
      return
    }
  }

  fmt.Fprintf(w, jsoniffy(currentSong))
}


func getUpcomingSongs(w http.ResponseWriter, r *http.Request) {
  currentSong, err := mpd_conn.CurrentSong()
  if err != nil {

    count := 0;
    for err != nil && count < 10 {
      time.Sleep(10)

      currentSong, err = mpd_conn.CurrentSong()
      count ++
    }

    if err != nil {
      error(w, "Couldn't get current song info for upcoming list", err)
      return
    }
  }

  pos, err := strconv.Atoi(currentSong["Pos"])
  if err != nil {
    error(w, "Couldn't turn current song's position to int", err)
    return
  }

  playlist, err := mpd_conn.PlaylistInfo(-1, -1)
  if err != nil {
    count := 0
    for err != nil && count < 10 {
      time.Sleep(10)

      playlist, err = mpd_conn.PlaylistInfo(-1, -1)
      count ++
    }

    if err != nil {
      error(w, "Couldn't get the current playlist", err)
      return
    }
  }

  upcoming := playlist[pos + 1:]

  fmt.Fprintf(w, jsoniffy(upcoming))
}



/*******************
  Helper Functions  
 *******************/

func startMpd(mpdCommand string){
	log.Println("MPD Starting!")
	cmd := exec.Command(mpdCommand)
	err := cmd.Run()
	if err != nil {
		log.Fatal("Could not start MPD Server! Check the mpc_command in config.yaml.")
	}
	defer stopMPD(cmd.Process)
}

func stopMPD(cmd *os.Process) {
		log.Println("Killing MPD")
		cmd.Kill()
	}
// Connect to MPD's control channel, and set the global mpd_conn to it.
func mpdConnect(url string) *mpd.Client {
  conn, err := mpd.Dial("tcp", url)
  
  // if we can't connect to MPD everything's fucked, nothing's going to work
  // kill all humans, and die, respectfully, after explaining what the issue
  // is.
  if err != nil {
    log.Println("\n\nServer quiting because it can't connect to MPD");
    log.Println(err)

    return nil
  }

  return conn
}

// helper struct; used to hold some ID3 info, plus an MPD file path.
type TBFile struct {id3.File; FilePath string;}

// helper method, returns a pointer to one of our helper structs (see above).
func id3Read(reader io.Reader, filePath string) *TBFile {
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

// turn anything into JSON.
func jsoniffy(v interface {}) string {
  obj, err := json.MarshalIndent(v, "", "  ")
  if err != nil {
    log.Print("Couldn't turn something into JSON: ", v)
    log.Fatal(err)
  }

  return string(obj)
}

func error(w http.ResponseWriter, message string, err interface{Error() string;}) {
  log.Println("An error occured; telling the client.")
  log.Println("Message:", message)
  log.Println("Error:", err, "\n\n")

  fmt.Fprintf(w, message + "\n")
}

func jsonError(w http.ResponseWriter, message string, err interface{Error() string;}) {
  message = "{error:\"" + message + "\"}"
  error(w, message, err)
}

