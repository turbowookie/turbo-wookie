package turbowookie

import (
  //"log"
  "github.com/kylelemons/go-gypsy/yaml"
)

func ReadConfig(filename string) (map[string]string, error) {
  tb_keys := [...]string{
    "mpd_command",
    "server_port",
    "server_domain",
    "mpd_domain",
    "mpd_http_port",
    "mpd_control_port",
    "turbo_wookie_directory",
    "mpd_subdirectory",
    "mpd_music_directory",
    "mpd_playlist_directory",
    "mpd_db_file",
    "mpd_log_file",
    "mpd_state_file",
    "mpd_sticker_file",
  }

  file, err := yaml.ReadFile(filename)

  if err != nil {
    return nil, &TBError{Msg: "Cannot read " + filename + " for YAML parsing", Err: err}
    //log.Fatal("Cannot read", filename, "for YAML parsing")
  }

  config := make(map[string]string)

  for _, key := range tb_keys {
    val, err := file.Get(key)
    if err != nil {
      return nil, &TBError{Msg: "Config is missing key `" + key + "`", Err: err}
      //log.Fatal("Config is missing key", key)
    }

    config[key] = val
  }

  return config, nil
}
