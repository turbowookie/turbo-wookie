package turbowookie

import (
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
	"gopkg.in/gorp.v1"
	"log"
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
