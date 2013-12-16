# Turbo Wookie

Turbo Wookie is a whimsically named product. More importantly, it's a collaborative music jukebox which streams music to multiple clients concurrently.

If that doesn't really explain anything, in less technical terms, Turbo Wookie is a collaborative jukebox; a group of people (probably friends?) can start up a Turbo Wookie instance, share the address amongst themselves, and build a playlist that they'll be able to listen to at the same time.

Think of it like an internet radio station, but the only music played is yours, and the DJ is everyone you let access your Turbo Wookie instance.

## Background

Turbo Wookie started as a group final project for a Software Design and Development course. We liked it more than the other ideas proposed to the group.

## How does it work?

Turbo Wookie has four main components, in three parts:

1. A Music Stream. That's manipulable.
2. A Music Library.
3. A Web Server that serves clients and manipulates the stream.
4. A Web-based Frontend. Because who wants to download another application?

The three parts are:

1. [MPD](http://www.musicpd.org/) (Music Player Daemon). It acts as both our stream and library.
2. Our [backend server](https://github.com/turbowookie/turbo-wookie/tree/master/backend). It's written in [Go](http://golang.org), and is where we actually tell MPD to do things.
3. Our [frontend](https://github.com/turbowookie/turbo-wookie/tree/master/frontend/turbo_wookie). It's written in [Dart](http://dartlang.org) and is where the stream is played, and where users ask for the stream to be manipulated. It also shows the library. We think it's kinda pretty.

Thus far, running Turbo Wookie been tested on Linux (Ubuntu and Arch) and Windows. Presumably it'll run on OS X, we just don't have any team members running OS X.

## How can I use it?

If you want to follow our incredibly snarky [manual](http://turbowookie.github.io/manual.html), you can do that.

If you'd rather just have the gist, and figure it out yourself:

1. Install MPD, Go, and Dart (or at least `dart2js` and `pub`). Make sure MPD's executable is in your path.
2. Build the `frontend/turbo_wookie/` dart project (using `pub get && pub update && pub build`), which will compile our dart code to javascript.
3. Copy `backend/mpd/mpd.conf.example` to `backend/mpd/mpd.conf`, and modify it so it uses your directories, instead of mine.
4. Copy `backend/config.example.yaml` to `backend/config.yaml`, and adjust as needed. If all you change in `mpd.conf` is the directories, you only need to change `turbo_wookie_directory` and `mpd_subdirectory` (and probably not even `mpd_subdirectory`).
5. Open the `backend` directory, and run `server.go` (if you don't want to build it, `go run server.go`, if you want to build it `go build server.go && ./server`). You might need to grab some dependencies.

Eventually (hopefully) we'll put together an executable, complete with the frontend, so you don't have to manually build all that stuff.

Turbo Wookie assumes you're running it in a directory with a `config.yaml` file with the required keys for Turbo Wookie. If you aren't, you can specify the location of a config file using the `-config` flag (like this: `go run server.go -config /path/to/config.yaml`).


## How can I play with it?

You need the same things installed as before, in addition to [Dartium](https://www.dartlang.org/tools/dartium/), a Chromium build that can run unconverted Dart code, if you want to play with the frontend.

The only difference between the above steps for getting Turbo Wookie running is that when you run the server, you might want to use one of our three flags:

- `-dart` (bool) will serve up the unconverted dart code (the `frontend/turbo_wookie/web` directory instead of the `frontend/turbo_wookie/build` directory).
- `-nompd` (bool) will *not* start MPD with the server, it'll assume you've started MPD already. If you don't start MPD and use this flag, bad things will happen (as in, the server won't start because it won't be able to talk to MPD).
- `-config` (string) will specify a specific config file. If you don't include the config flag, it will assume there's a config file in your current working directory.

Using the flags is easy, even if you're using `go run`, just append them to the end of the command (as in `go run server.go -dart -config /path/to/config.yaml -nompd`).

Everything is fairly well documented.

## Other Uses

If you really want to, you can use Turbo Wookie as an MPD controller, and output
to your speakers instead of to the web (or do both). In this case, just adjust
your `backend/mpd/mpd.conf`. Uncomment one of the other `audio_output` blocks
(for most Linux users, the `alsa` output should be fine; OS X and Windows users,
I'm not sure what output you need).
