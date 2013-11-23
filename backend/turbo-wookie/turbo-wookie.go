package turbowookie

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