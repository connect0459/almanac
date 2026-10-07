///|
fn embedded_tzif(name : String) -> Bytes {
  resolve_tzdata_bytes(tzdata_zones, tzdata_aliases, name).unwrap()
}

///|
fn files_reader(files : Map[String, Bytes]) -> (String) -> Bytes? {
  path => files.get(path)
}

///|
fn no_files(_path : String) -> Bytes? {
  None
}

///|
test "resolve falls back to the given localtime bytes when TZ is unset" {
  let resolved = Local::resolve(
    None,
    files_reader({ "/etc/localtime": embedded_tzif("America/New_York") }),
  ).unwrap()
  let dst_start_2024 = @core.NaiveDateTime::from_timestamp(1_710_054_000L, 0).unwrap()
  assert_eq(resolved.zone_name(dst_start_2024), "EDT")
}

///|
test "resolve is None when TZ is unset and no localtime bytes are available" {
  assert_true(Local::resolve(None, no_files) is None)
}

///|
test "resolve treats an empty TZ as UTC, ignoring any localtime bytes" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let resolved = Local::resolve(
    Some(""),
    files_reader({ "/etc/localtime": embedded_tzif("Asia/Tokyo") }),
  ).unwrap()
  assert_eq(resolved.offset_from_utc(dt), FixedOffset::east(0).unwrap())
  assert_eq(
    resolved.offset_from_local(dt),
    Single(FixedOffset::east(0).unwrap()),
  )
  assert_eq(resolved.zone_name(dt), "+00:00")
}

///|
test "resolve loads a named IANA zone from TZ, ignoring any localtime bytes" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let resolved = Local::resolve(
    Some("Asia/Tokyo"),
    files_reader({ "/etc/localtime": embedded_tzif("America/New_York") }),
  ).unwrap()
  let tokyo = Location::load("Asia/Tokyo").unwrap()
  assert_eq(resolved.offset_from_utc(dt), tokyo.offset_from_utc(dt))
  assert_eq(resolved.offset_from_local(dt), tokyo.offset_from_local(dt))
  assert_eq(resolved.zone_name(dt), tokyo.zone_name(dt))
}

///|
test "resolve is None when TZ names an unrecognized zone, regardless of localtime bytes" {
  assert_true(
    Local::resolve(
      Some("Not/AZone"),
      files_reader({ "/etc/localtime": embedded_tzif("America/New_York") }),
    )
    is None,
  )
}

///|
test "resolve accepts a bare POSIX rule in TZ, ignoring any localtime bytes" {
  let resolved = Local::resolve(
    Some("JST-9"),
    files_reader({ "/etc/localtime": embedded_tzif("America/New_York") }),
  ).unwrap()
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  assert_eq(resolved.zone_name(any), "JST")
  assert_eq(resolved.offset_from_utc(any), FixedOffset::east(9 * 3600).unwrap())
}

///|
test "resolve applies the DST part of a bare POSIX rule in TZ" {
  let resolved = Local::resolve(Some("FOO5BAR4,M3.2.0,M11.1.0"), no_files).unwrap()
  let winter = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let summer = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  assert_eq(resolved.zone_name(winter), "FOO")
  assert_eq(resolved.zone_name(summer), "BAR")
  assert_eq(
    resolved.offset_from_utc(summer),
    FixedOffset::east(-4 * 3600).unwrap(),
  )
  let gap = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 10).unwrap(),
    @core.NaiveTime::from_hms(2, 30, 0).unwrap(),
  )
  assert_true(resolved.offset_from_local(gap) is Absent)
}

///|
test "resolve prefers an IANA zone name over reading TZ as a POSIX rule" {
  let resolved = Local::resolve(Some("EST5EDT"), no_files).unwrap()
  let summer = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  assert_eq(resolved.zone_name(summer), "EDT")
}

///|
test "resolve is None when TZ is unset and the localtime bytes are empty or malformed" {
  assert_true(
    Local::resolve(None, files_reader({ "/etc/localtime": b"" })) is None,
  )
  assert_true(
    Local::resolve(None, files_reader({ "/etc/localtime": b"not a tzif file" }))
    is None,
  )
}

///|
test "resolve ignores empty localtime bytes when TZ names a zone" {
  assert_true(
    Local::resolve(Some("Asia/Tokyo"), files_reader({ "/etc/localtime": b"" }))
    is Some(_),
  )
  assert_true(
    Local::resolve(Some(""), files_reader({ "/etc/localtime": b"" })) is Some(_),
  )
}

///|
test "a Local resolved from each source reports DST like the underlying zone" {
  let summer = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  let winter = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let iana = Local::resolve(Some("America/New_York"), no_files).unwrap()
  let posix = Local::resolve(Some("FOO5BAR4,M3.2.0,M11.1.0"), no_files).unwrap()
  let fixed = Local::resolve(Some(""), no_files).unwrap()
  assert_true(iana.is_dst(summer))
  assert_false(iana.is_dst(winter))
  assert_true(posix.is_dst(summer))
  assert_false(posix.is_dst(winter))
  assert_false(fixed.is_dst(summer))
}

///|
test "a Local resolved from each source reports the same zone bounds as the underlying zone" {
  let summer = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  let ny = Location::load("America/New_York").unwrap()
  let rule = parse_posix_tz("FOO5BAR4,M3.2.0,M11.1.0").unwrap()
  let iana = Local::resolve(Some("America/New_York"), no_files).unwrap()
  let posix = Local::resolve(Some("FOO5BAR4,M3.2.0,M11.1.0"), no_files).unwrap()
  let fixed = Local::resolve(Some(""), no_files).unwrap()
  assert_eq(iana.transition_bounds(summer), ny.transition_bounds(summer))
  assert_eq(posix.transition_bounds(summer), rule.transition_bounds(summer))
  assert_eq(fixed.transition_bounds(summer).start(), None)
  assert_eq(fixed.transition_bounds(summer).end(), None)
}

///|
test "a Local resolves abbreviations through its underlying zone" {
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let iana = Local::resolve(Some("America/New_York"), no_files).unwrap()
  let posix = Local::resolve(Some("FOO5BAR4,M3.2.0,M11.1.0"), no_files).unwrap()
  let fixed = Local::resolve(Some(""), no_files).unwrap()
  assert_eq(
    iana.offset_from_abbreviation("EDT", any),
    FixedOffset::east(-4 * 3600),
  )
  assert_eq(
    posix.offset_from_abbreviation("BAR", any),
    FixedOffset::east(-4 * 3600),
  )
  assert_eq(fixed.offset_from_abbreviation("UTC", any), None)
}

///|
test "resolve treats a lone colon in TZ as UTC, like an empty TZ" {
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let resolved = Local::resolve(
    Some(":"),
    files_reader({ "/etc/localtime": embedded_tzif("Asia/Tokyo") }),
  ).unwrap()
  assert_eq(resolved.offset_from_utc(any), FixedOffset::east(0).unwrap())
  assert_eq(resolved.zone_name(any), "+00:00")
}

///|
test "resolve ignores a leading colon before an IANA zone name in TZ" {
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let resolved = Local::resolve(Some(":Asia/Tokyo"), no_files).unwrap()
  assert_eq(resolved.offset_from_utc(any), FixedOffset::east(9 * 3600).unwrap())
  assert_eq(resolved.zone_name(any), "JST")
}

///|
test "resolve ignores a leading colon before a bare POSIX rule in TZ" {
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let resolved = Local::resolve(Some(":JST-9"), no_files).unwrap()
  assert_eq(resolved.zone_name(any), "JST")
  assert_eq(resolved.offset_from_utc(any), FixedOffset::east(9 * 3600).unwrap())
}

///|
test "resolve strips only one leading colon from TZ" {
  assert_true(
    Local::resolve(
      Some("::/zones/custom"),
      files_reader({ "/zones/custom": embedded_tzif("Asia/Tokyo") }),
    )
    is None,
  )
}

///|
test "resolve reads the TZif file at an absolute path in TZ" {
  let files = { "/zones/custom": embedded_tzif("Asia/Tokyo") }
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let resolved = Local::resolve(Some("/zones/custom"), files_reader(files)).unwrap()
  assert_eq(resolved.offset_from_utc(any), FixedOffset::east(9 * 3600).unwrap())
  assert_eq(resolved.zone_name(any), "JST")
}

///|
test "resolve reads the TZif file at an absolute path behind a leading colon" {
  let files = { "/zones/custom": embedded_tzif("America/New_York") }
  let summer = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  let resolved = Local::resolve(Some(":/zones/custom"), files_reader(files)).unwrap()
  assert_eq(resolved.zone_name(summer), "EDT")
}

///|
test "resolve prefers the file at an absolute path over the localtime file" {
  let files = {
    "/etc/localtime": embedded_tzif("America/New_York"),
    "/zones/custom": embedded_tzif("Asia/Tokyo"),
  }
  let any = @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap()
  let resolved = Local::resolve(Some("/zones/custom"), files_reader(files)).unwrap()
  assert_eq(resolved.zone_name(any), "JST")
}

///|
test "resolve is None when the file at an absolute path in TZ is missing" {
  assert_true(Local::resolve(Some("/zones/missing"), no_files) is None)
  assert_true(Local::resolve(Some(":/zones/missing"), no_files) is None)
}

///|
test "resolve is None when the file at an absolute path in TZ is not TZif data" {
  let files = { "/zones/bad": b"not a tzif file", "/zones/empty": b"" }
  assert_true(Local::resolve(Some("/zones/bad"), files_reader(files)) is None)
  assert_true(Local::resolve(Some("/zones/empty"), files_reader(files)) is None)
}
