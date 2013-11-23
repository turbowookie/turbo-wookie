package turbowookie

type TBError struct {
  Msg string
  Err error
}

func (e *TBError) Error() string {
  return e.Msg + "\n\t" + e.Err.Error()
}