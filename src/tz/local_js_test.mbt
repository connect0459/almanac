///|
test "new() resolves the host's configured local time zone" {
  assert_true(@tz.Local::new() is Some(_))
}

///|
test "Local::now() is the current instant expressed in the host's local zone" {
  let before = @tz.Utc::now()
  let now = @tz.Local::now().unwrap()
  let after = @tz.Utc::now()
  assert_true(now.signed_duration_since(before).num_milliseconds() >= 0L)
  assert_true(after.signed_duration_since(now).num_milliseconds() >= 0L)
}

///|
test "Local::now() uses the same zone as Local::new()" {
  let now = @tz.Local::now().unwrap()
  let zone = @tz.Local::new().unwrap()
  assert_eq(now.offset(), zone.offset_from_utc(now.naive_utc()))
  assert_eq(now.zone_name(), zone.zone_name(now.naive_utc()))
}
