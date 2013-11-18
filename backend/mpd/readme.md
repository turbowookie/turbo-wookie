# MPD Info

All MPD files are stored in `./backend/mpd`.

To setup your MPD config, open your mpd directory, and do the following:

1.  Make sure you have the following files:
    a.  database.db
    b.  log
    c.  pid
    d.  state
    e.  sticker.sql
    f.  a `music/` directory
    g.  a `playlits/` directory
    
    You may need to make the directories, as I think they're currently ignored.

2.  Copy `mpd.conf.example` to `mpd.conf`, and adjust the values as needed.
    Everything you need to change should be in the first 55 lines. Just change
    the file paths.

3.  Copy some music into your `music/` directory. It doesn't matter what you
    copy because the music directory is ignored.

4.  Run `mpd [path to mpd.conf]` in Linux. Windows users ... I'm not sure what
    you need to do.
