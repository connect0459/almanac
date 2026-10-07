///|
test "zone names include well-known IANA zones" {
  let names = @tz.Location::zone_names()
  assert_true(names.contains("Asia/Tokyo"))
  assert_true(names.contains("America/New_York"))
}

///|
test "zone names are sorted and free of duplicates" {
  let names = @tz.Location::zone_names()
  for i in 1..<names.length() {
    assert_true(names[i - 1] < names[i])
  }
}

///|
test "every listed zone name loads under that name" {
  for name in @tz.Location::zone_names() {
    assert_eq(@tz.Location::load(name).unwrap().name(), Some(name))
  }
}

///|
test "mutating the returned zone names does not affect later calls" {
  let names = @tz.Location::zone_names()
  let count = names.length()
  names.clear()
  assert_eq(@tz.Location::zone_names().length(), count)
}

///|
test "tzdata version reports the embedded release rather than the unknown placeholder" {
  let version = @tz.Location::tzdata_version()
  assert_true(version.length() > 0)
  assert_true(version != "unknown")
}
