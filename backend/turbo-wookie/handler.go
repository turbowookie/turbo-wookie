package turbowookie

import (
	"encoding/json"
	"fmt"
	"github.com/gorilla/mux"
	"github.com/gorilla/websocket"
	"log"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strconv"
)

// Handler is our custom http.Handler used to actually do the HTTP stuff.
type Handler struct {
	// MpdClient is our MPD Client, used to tell MPD to do things. Important
	// things.
	MpdClient *MPDClient

	// ServerConfig is a map of configuration key/values found in
	// a config.yaml file.
	ServerConfig map[string]string

	// Router is a mux.Router, it's what really does all the HTTP stuff, we just
	// act as the interface. And the HandlerFuncs
	Router *mux.Router

	socketUpgrader websocket.Upgrader

	socketConnections []*websocket.Conn
}

// NewHandler creates a new Handler, using the passed in filename as a
// yaml file containing the server's configuation settings.
func NewHandler(filename string, serveDart, startMPD bool, portOverride int) (*Handler, error) {
	// make us a pointer to a handler.
	h := &Handler{}

	// attempt to read the passed in config file. See `yaml.go` for more info.
	config, err := ReadConfig(filename)
	if err != nil {
		return nil, err
	}

	if !(config["server_port"] != "9000" && portOverride == 9000) {
		config["server_port"] = strconv.Itoa(portOverride)
	}

	h.ServerConfig = config
	h.MpdClient = NewMPDClient(h.ServerConfig, startMPD) // see MPDClient.go

	// Make sure there's a server to connect to, and run some other startup
	// commands (like making sure there's music playing...).
	err = h.MpdClient.Startup()
	if err != nil {
		log.Fatal("Error running the MPDClient startup...\n", err)
	}

	// Actually make our HTTP Router
	h.Router = mux.NewRouter()

	// Let us play the MPD without having to deal with cross origin stuff.
	// Because cross origin is kinda a bitch.
	h.Router.HandleFunc("/stream", httputil.NewSingleHostReverseProxy(
		&url.URL{
			Scheme: "http",
			Host:   h.ServerConfig["mpd_domain"] + ":" + h.ServerConfig["mpd_http_port"],
			Path:   "/",
		}).ServeHTTP)

	h.Router.HandleFunc("/songs", h.listSongs)
	h.Router.HandleFunc("/artists", h.listArtists)
	h.Router.HandleFunc("/albums", h.listArtistAlbums)
	h.Router.HandleFunc("/current", h.getCurrentSong)
	h.Router.HandleFunc("/upcoming", h.getUpcomingSongs)
	h.Router.HandleFunc("/add", h.addSong)
	h.Router.HandleFunc("/search", h.search)
	h.Router.HandleFunc("/socket", h.websocket)

	// This needs to be last, otherwise it'll override all routes after it
	// because we're matching EVERYTHING.
	fileDir := h.ServerConfig["turbo_wookie_directory"] + "/frontend/turbo_wookie"
	if serveDart {
		fileDir += "/web"
	} else {
		fileDir += "/build/web"
	}
	h.Router.PathPrefix("/").Handler(http.FileServer(http.Dir(fileDir)))

	h.socketUpgrader = websocket.Upgrader{
		ReadBufferSize:  1024,
		WriteBufferSize: 1024,
	}
	h.socketConnections = make([]*websocket.Conn, 0)

	// nothing bad happened. Suprise!
	return h, nil
}

// Make Handler an HTTP.Handler. Hackily. Just pass up the underlying
// Router's function.
func (h *Handler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	h.Router.ServeHTTP(w, r)
}

// HandleFunc make Handler extendible...
// Same as ServeHTTP, just pass up the Router's function.
func (h *Handler) HandleFunc(path string, f func(w http.ResponseWriter, r *http.Request)) *mux.Route {
	return h.Router.HandleFunc(path, f)
}

// ListenAndServe serve up some TurboWookie. And setup an MPD Watcher to see
// when things happen to the stream. Because things sometimes happen to the
// stream.
func (h *Handler) ListenAndServe() error {
	// Setup a watcher.
	WatchMPD(h.ServerConfig["mpd_domain"]+":"+h.ServerConfig["mpd_control_port"], h)

	port := ":" + h.ServerConfig["server_port"]
	log.Println("Starting server on " + port)
	return http.ListenAndServe(port, h)
}

/************************
    HANDLER FUNCTIONS
************************/

// List all songs in the library, and information about those songs.
func (h *Handler) listSongs(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	artist, ok1 := r.Form["artist"]
	album, ok2 := r.Form["album"]

	var songs []map[string]string
	var err error

	if ok1 && ok2 {
		songs, err = h.MpdClient.GetSongs(artist[0], album[0])
	} else if ok1 && !ok2 {
		songs, err = h.MpdClient.GetSongs(artist[0], "")
	} else {
		songs, err = h.MpdClient.GetFiles()
	}

	if err != nil {
		printError(w, "An error occured while processing your request", err)
		return
	}

	fmt.Fprintf(w, jsoniffy(songs))
}

func (h *Handler) listArtists(w http.ResponseWriter, r *http.Request) {
	artists, err := h.MpdClient.GetArtists()
	if err != nil {
		printError(w, "An error occured while processing your request", err)
		return
	}

	fmt.Fprintf(w, jsoniffy(artists))
}

func (h *Handler) listArtistAlbums(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	artist, ok := r.Form["artist"]
	var albums map[string][]string
	var err error
	if !ok {
		albums, err = h.MpdClient.GetAlbums("")
	} else {
		albums, err = h.MpdClient.GetAlbums(artist[0])
	}
	if err != nil {
		printError(w, "An error occured while processing your request", err)
		return
	}

	fmt.Fprintf(w, jsoniffy(albums))
}

// Return information about the currently playing song.
func (h *Handler) getCurrentSong(w http.ResponseWriter, r *http.Request) {
	currentSong, err := h.MpdClient.CurrentSong()
	if err != nil {
		printError(w, "Couldn't get current song info", err)
		return
	}

	fmt.Fprintf(w, jsoniffy(currentSong))
}

// Return a list of all upcoming songs in the playlist.
// As in, return `playlist[current song + 1 :]`.
func (h *Handler) getUpcomingSongs(w http.ResponseWriter, r *http.Request) {
	upcoming, err := h.MpdClient.GetUpcoming()
	if err != nil {
		printError(w, "Couldn't get upcoming playlist", err)
		return
	}

	fmt.Fprintf(w, jsoniffy(upcoming))
}

// Add a song to the playlist. Using the format
//    `/add?song=[FilePath of song]`
func (h *Handler) addSong(w http.ResponseWriter, r *http.Request) {
	// for some reason Go doesn't do this automatically.
	r.ParseForm()

	// Get the song from the GET request variables,
	// and check that there's actually something called `song` in the request.
	rawSongs, ok := r.Form["song"]
	if !ok {
		log.Println(r.Form)
		printError(w, "No song specified", nil)
		return
	}

	song, err := url.QueryUnescape(rawSongs[0])
	if err != nil {
		log.Println("Error unescaping song...\n\tError:", err, "\n\tSong:", song)
	} else {
		song = rawSongs[0]
	}

	log.Println("Adding song", song, " : ", rawSongs[0])

	// Attempt to add the song to the playlist
	err = h.MpdClient.Add(song)
	if err != nil {
		printError(w, "Unknown song", err)
		return
	}

	// Return a simple note saying that we got the song
	m := make(map[string]string)
	m["note"] = "Added song: " + song
	fmt.Fprintf(w, jsoniffy(m))

	// tell long pollers that the playlist changed.
	h.PolarChanged("playlist")
}

// Searches for an artist, album, or song in the database.
func (h *Handler) search(w http.ResponseWriter, r *http.Request) {
	// Get the query string.
	r.ParseForm()
	query, ok := r.Form["search"]
	if !ok {
		log.Println("No search specified", nil)
		return
	}

	// Create the response variables.
	artistResponse := make([]string, 0)
	albumResponse := make([]string, 0)
	songsResponse := make([]map[string]string, 0)

	// Search for all artists.
	songsArtist, err := h.MpdClient.Search("artist \"" + query[0] + "\"")
	if err != nil {
		log.Println("Error searching MPD")
		return
	}

	// Add each artist to the list.
	for _, song := range songsArtist {
		if indexOf(artistResponse, song["Artist"]) == -1 {
			artistResponse = append(artistResponse, song["Artist"])
		}
	}

	// Search for all albums.
	songsAlbum, err := h.MpdClient.Search("album \"" + query[0] + "\"")
	if err != nil {
		log.Println("Error searching MPD")
		return
	}

	// Add each album to the list.
	for _, song := range songsAlbum {
		if indexOf(albumResponse, song["Album"]) == -1 {
			albumResponse = append(albumResponse, song["Album"])
		}
	}

	// Search for all songs.
	songsSongs, err := h.MpdClient.Search("title \"" + query[0] + "\"")
	if err != nil {
		log.Println("Error searching MPD")
		return
	}

	// Add each song to the list.
	for _, song := range songsSongs {
		songsResponse = append(songsResponse, song)
	}

	// Create the json response and send it to the client.
	responseMap := make(map[string]interface{})
	responseMap["artist"] = artistResponse
	responseMap["album"] = albumResponse
	responseMap["song"] = songsResponse

	fmt.Fprintf(w, jsoniffy(responseMap))
}

func (h *Handler) websocket(w http.ResponseWriter, r *http.Request) {
	conn, err := h.socketUpgrader.Upgrade(w, r, nil)
	if err != nil {
		printError(w, "Error upgrading to websocket connection!", err)
		return
	}

	log.Println("Websocket connection established!")

	h.socketConnections = append(h.socketConnections, conn)

	for {
		messageType, bytesBody, err := conn.ReadMessage()
		body := string(bytesBody[:])
		if err != nil {
			log.Println("WS Read Error", err)

			if websocket.IsUnexpectedCloseError(err) {
				h.removeWebSocket(conn)
			}

			break
		}

		if messageType == websocket.TextMessage {
			log.Println("WS From", r.RemoteAddr, "\n\tBody:", body)
		} else if messageType == websocket.CloseMessage {
			log.Println("WS Closing", r.RemoteAddr)

			h.removeWebSocket(conn)
			break
		}
	}
}

/************************
    HELPER FUNCTIONS
************************/

func (h *Handler) CloseWebSockets() {
	for _, conn := range h.socketConnections {
		err := conn.Close()
		if err != nil {
			log.Println("Error closing websocket")
		}
	}
}

// Print an error the the screen, and send a simple message to the client.
func printError(w http.ResponseWriter, msg string, err error) {
	log.Println("ERROR:", err)
	log.Println("Sending to client:", msg)
	fmt.Fprintf(w, msg+"\n")
}

// Turn things into JSON.
func jsoniffy(v interface{}) string {
	obj, err := json.MarshalIndent(v, "", "  ")
	if err != nil {
		log.Print("Couldn't turn something into JSON: ", v)
		log.Fatal(err)
	}

	return string(obj)
}

// PolarChanged tell clients connected to our long-poll system that something
// (element) has changed.
func (h *Handler) PolarChanged(element string) {
	connsToDelete := make([]*websocket.Conn, 0)
	for _, conn := range h.socketConnections {
		if conn == nil {
			connsToDelete = append(connsToDelete, conn)
			continue
		}
		log.Println("WS Sending", element)
		err := conn.WriteMessage(websocket.TextMessage, []byte(element))

		if err != nil {
			log.Println("WS Error writing update")
		}
	}

	for _, conn := range connsToDelete {
		h.removeWebSocket(conn)
	}
}

func (h *Handler) removeWebSocket(conn *websocket.Conn) {
	for i := 0; i < len(h.socketConnections); i++ {
		if h.socketConnections[i] == conn {
			h.socketConnections[i] = nil
			h.socketConnections[i] = h.socketConnections[len(h.socketConnections)-1]
			h.socketConnections = h.socketConnections[len(h.socketConnections)-1:]
			//copy(h.socketConnections[i:], h.socketConnections[i+1:])
			//h.socketConnections[len(h.socketConnections)-1] = nil

			log.Println("Removing WS from slice")
			return
		}
	}
	log.Println("WS made it through remove loop.....")
}
