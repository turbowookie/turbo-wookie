# How to setup MPD directory

Create the following files (no contents):

- `database.db`
- `log`
- `state`
- `sticker.sql`
- `pid`

Create the following directories:

- `music`
- `playlists`

Music is where you'll put any media files you want to use. It's in the gitignore file.

Also, copy `mpd.conf.example` to `mpd.conf`, and adjust as needed (you'll probably need to change the paths, which are all set to `~/code/turbo-wookie/backend/mpd/[x]`).