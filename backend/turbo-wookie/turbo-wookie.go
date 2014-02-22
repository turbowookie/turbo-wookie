package turbowookie

import (
  "math/rand"
  "time"
)

type tbError struct {
  Msg string
  Err error
}

func (e *tbError) Error() string {
  return e.Msg + "\n\t" + e.Err.Error()
}

type tbErrorMsg struct {
  Msg string
}

func (e *tbErrorMsg) Error() string {
  return e.Msg
}

func random(min, max int) int {
  rand.Seed(time.Now().Unix())
  return rand.Intn(max-min) + min
}

func indexOf(arr []string, str string) int  {
	for i, a := range arr {
		if a == str {
			return i
		}
	}

	return -1
}