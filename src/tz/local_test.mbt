///|
test "resolve falls back to the given localtime bytes when TZ is unset" {
  let resolved = @tz.Local::resolve(None, Some(tzif_new_york)).unwrap()
  let dst_start_2024 = @core.NaiveDateTime::from_timestamp(1_710_054_000L, 0).unwrap()
  assert_eq(resolved.tz_name(dst_start_2024), "EDT")
}

///|
test "resolve is None when TZ is unset and no localtime bytes are available" {
  assert_true(@tz.Local::resolve(None, None) is None)
}

///|
test "resolve treats an empty TZ as UTC, ignoring any localtime bytes" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let resolved = @tz.Local::resolve(Some(""), Some(tzif_tokyo)).unwrap()
  assert_eq(resolved.offset_from_utc(dt), @tz.FixedOffset::east(0).unwrap())
  assert_eq(
    resolved.offset_from_local(dt),
    @tz.Single(@tz.FixedOffset::east(0).unwrap()),
  )
  assert_eq(resolved.tz_name(dt), "+00:00")
}

///|
test "resolve loads a named IANA zone from TZ, ignoring any localtime bytes" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let resolved = @tz.Local::resolve(Some("Asia/Tokyo"), Some(tzif_new_york)).unwrap()
  let tokyo = @tz.Location::load("Asia/Tokyo").unwrap()
  assert_eq(resolved.offset_from_utc(dt), tokyo.offset_from_utc(dt))
  assert_eq(resolved.offset_from_local(dt), tokyo.offset_from_local(dt))
  assert_eq(resolved.tz_name(dt), tokyo.tz_name(dt))
}

///|
test "resolve is None when TZ names an unrecognized zone, regardless of localtime bytes" {
  assert_true(
    @tz.Local::resolve(Some("Not/AZone"), Some(tzif_new_york)) is None,
  )
}

///|
test "resolve accepts a bare POSIX rule in TZ, ignoring any localtime bytes" {
  let resolved = @tz.Local::resolve(Some("JST-9"), Some(tzif_new_york)).unwrap()
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  assert_eq(resolved.tz_name(any), "JST")
  assert_eq(
    resolved.offset_from_utc(any),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
}

///|
test "resolve applies the DST part of a bare POSIX rule in TZ" {
  let resolved = @tz.Local::resolve(Some("FOO5BAR4,M3.2.0,M11.1.0"), None).unwrap()
  let winter = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let summer = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  assert_eq(resolved.tz_name(winter), "FOO")
  assert_eq(resolved.tz_name(summer), "BAR")
  assert_eq(
    resolved.offset_from_utc(summer),
    @tz.FixedOffset::east(-4 * 3600).unwrap(),
  )
  let gap = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 10).unwrap(),
    @core.NaiveTime::from_hms(2, 30, 0).unwrap(),
  )
  assert_true(resolved.offset_from_local(gap) is @tz.Absent)
}

///|
test "resolve prefers an IANA zone name over reading TZ as a POSIX rule" {
  let resolved = @tz.Local::resolve(Some("EST5EDT"), None).unwrap()
  let summer = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  assert_eq(resolved.tz_name(summer), "EDT")
}

///|
test "resolve is None when TZ is unset and the localtime bytes are empty or malformed" {
  assert_true(@tz.Local::resolve(None, Some(b"")) is None)
  assert_true(@tz.Local::resolve(None, Some(b"not a tzif file")) is None)
}

///|
test "resolve ignores empty localtime bytes when TZ names a zone" {
  assert_true(@tz.Local::resolve(Some("Asia/Tokyo"), Some(b"")) is Some(_))
  assert_true(@tz.Local::resolve(Some(""), Some(b"")) is Some(_))
}
