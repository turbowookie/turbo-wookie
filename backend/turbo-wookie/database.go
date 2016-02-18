package turbowookie

import (
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/gorp.v1"
	"log"
	"strconv"
)

type Song struct {
	Id        int64
	Artist    string
	Album     string
	Title     string
	Uri       string
	PlayCount int64
	SkipCount int64
}

func (song Song) ToMap() map[string]string {
	response := make(map[string]string)
	response["Id"] = strconv.FormatInt(song.Id, 10)
	response["Artist"] = song.Artist
	response["Album"] = song.Album
	response["Title"] = song.Title
	response["file"] = song.Uri
	response["Uri"] = song.Uri

	return response
}

func InitDB() *gorp.DbMap {
	db, err := sql.Open("sqlite3", "turbowookie.db")
	if err != nil {
		log.Fatal(err)
	}

	dbmap := &gorp.DbMap{Db: db, Dialect: gorp.SqliteDialect{}}

	dbmap.AddTable(Song{}).SetKeys(true, "Id")

	err = dbmap.CreateTablesIfNotExists()

	return dbmap
}
