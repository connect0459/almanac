///|
test "new() resolves the host's configured local time zone" {
  assert_true(@tz.Local::new() is Some(_))
}
