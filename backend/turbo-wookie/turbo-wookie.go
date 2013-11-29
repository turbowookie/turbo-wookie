package turbowookie

import (
  "math/rand"
  "time"
)

type TBError struct {
  Msg string
  Err error
}

func (e *TBError) Error() string {
  return e.Msg + "\n\t" + e.Err.Error()
}

type TBErrorMsg struct {
  Msg string
}

func (e *TBErrorMsg) Error() string {
  return e.Msg
}

func random(min, max int) int {
  rand.Seed(time.Now().Unix())
  return rand.Intn(max-min) + min
}
