///|
fn utc_instant(year : Int32, month : Int32, day : Int32) -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(year, month, day).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
}

///|
test "a Windows zone key name maps to the IANA name of its territory 001 entry" {
  assert_eq(windows_zone_iana_name("Tokyo Standard Time"), Some("Asia/Tokyo"))
  assert_eq(
    windows_zone_iana_name("Eastern Standard Time"),
    Some("America/New_York"),
  )
  assert_eq(windows_zone_iana_name("UTC"), Some("Etc/UTC"))
}

///|
test "a Windows zone key name that is absent from the table has no IANA name" {
  assert_eq(windows_zone_iana_name("Atlantis Standard Time"), None)
}

///|
test "an empty Windows zone key name has no IANA name" {
  assert_eq(windows_zone_iana_name(""), None)
}

///|
test "Windows zone key names are matched exactly" {
  assert_eq(windows_zone_iana_name("tokyo standard time"), None)
  assert_eq(windows_zone_iana_name(" Tokyo Standard Time"), None)
}

///|
test "every IANA name in the Windows zone table loads from the embedded database" {
  for key, iana in windows_zone_iana_names {
    guard Location::load(iana) is Some(_) else {
      fail("\{key} maps to \{iana}, which is not in the embedded database")
    }
  }
}

///|
test "the Windows zone table keeps at least 100 zones, guarding against a truncated regeneration" {
  assert_true(windows_zone_iana_names.length() >= 100)
}

///|
test "resolving a Windows zone key name follows the offsets of the mapped IANA zone" {
  let tokyo = Local::from_windows_zone("Tokyo Standard Time").unwrap()
  assert_eq(
    tokyo.offset_from_utc(utc_instant(2024, 6, 15)).local_minus_utc(),
    32400,
  )
  let new_york = Local::from_windows_zone("Eastern Standard Time").unwrap()
  assert_eq(
    new_york.offset_from_utc(utc_instant(2024, 1, 15)).local_minus_utc(),
    -18000,
  )
  assert_eq(
    new_york.offset_from_utc(utc_instant(2024, 7, 15)).local_minus_utc(),
    -14400,
  )
}

///|
test "resolving a Windows zone key name that has no mapping is None, never UTC" {
  assert_true(Local::from_windows_zone("Atlantis Standard Time") is None)
  assert_true(Local::from_windows_zone("") is None)
}
