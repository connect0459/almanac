///|
fn naive(
  y : Int,
  mo : Int,
  d : Int,
  h : Int,
  mi : Int,
  s : Int,
  nano? : Int = 0,
) -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(y, mo, d).unwrap(),
    @core.NaiveTime::from_hms_nano(h, mi, s, nano).unwrap(),
  )
}

///|
test "parse_iso8601 reads an offset date-time as the instant it names" {
  let expected = @tz.DateTime::from_utc(
    naive(2024, 3, 5, 0, 30, 0),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.parse_iso8601("2024-03-05T09:30:00+09:00"), Zoned(expected))
}

///|
test "parse_iso8601 reads a date-time without an offset as a local date-time" {
  assert_eq(
    @format.parse_iso8601("2024-03-05T09:30:15"),
    Local(naive(2024, 3, 5, 9, 30, 15)),
  )
}

///|
test "parse_iso8601 reads a bare date as a date" {
  assert_eq(
    @format.parse_iso8601("2024-03-05"),
    DateOnly(@core.NaiveDate::from_ymd(2024, 3, 5).unwrap()),
  )
}

///|
test "parse_iso8601 reads a bare time of day as a time" {
  assert_eq(
    @format.parse_iso8601("09:30:15"),
    TimeOnly(@core.NaiveTime::from_hms(9, 30, 15).unwrap()),
  )
}

///|
test "parse_iso8601 accepts T, t or a single space between the date and the time" {
  let expected = @format.Iso8601::Local(naive(2024, 3, 5, 9, 30, 15))
  for sep in ["T", "t", " "] {
    assert_eq(@format.parse_iso8601("2024-03-05\{sep}09:30:15"), expected)
  }
}

///|
test "parse_iso8601 accepts a time of day without seconds" {
  assert_eq(
    @format.parse_iso8601("2024-03-05T09:30"),
    Local(naive(2024, 3, 5, 9, 30, 0)),
  )
  assert_eq(
    @format.parse_iso8601("09:30"),
    TimeOnly(@core.NaiveTime::from_hms(9, 30, 0).unwrap()),
  )
}

///|
test "parse_iso8601 accepts an offset on a date-time with or without seconds" {
  let utc = @tz.FixedOffset::east(0).unwrap()
  assert_eq(
    @format.parse_iso8601("2024-03-05 09:30Z"),
    Zoned(@tz.DateTime::from_utc(naive(2024, 3, 5, 9, 30, 0), utc)),
  )
}

///|
test "parse_iso8601 reads Z and z as a zero offset and a signed HH:MM as that offset" {
  let zero = @tz.FixedOffset::east(0).unwrap()
  let west = @tz.FixedOffset::west(5 * 3600 + 30 * 60).unwrap()
  for s in ["2024-03-05T09:30:15Z", "2024-03-05T09:30:15z"] {
    assert_eq(
      @format.parse_iso8601(s),
      Zoned(@tz.DateTime::from_utc(naive(2024, 3, 5, 9, 30, 15), zero)),
    )
  }
  assert_eq(
    @format.parse_iso8601("2024-03-05T09:30:15-05:30"),
    Zoned(@tz.DateTime::from_utc(naive(2024, 3, 5, 15, 0, 15), west)),
  )
}

///|
test "parse_iso8601 keeps fractional seconds and truncates beyond nanoseconds" {
  assert_eq(
    @format.parse_iso8601("2024-03-05T09:30:15.5"),
    Local(naive(2024, 3, 5, 9, 30, 15, nano=500_000_000)),
  )
  assert_eq(
    @format.parse_iso8601("2024-03-05T09:30:15.1234567891"),
    Local(naive(2024, 3, 5, 9, 30, 15, nano=123_456_789)),
  )
}

///|
test "parse_iso8601 maps second 60 to the leap-second convention of NaiveTime" {
  assert_eq(
    @format.parse_iso8601("2016-12-31T23:59:60"),
    Local(naive(2016, 12, 31, 23, 59, 59, nano=1_000_000_000)),
  )
}

///|
test "parse_iso8601 rejects text that is not a date or time in any accepted shape" {
  for
    bad in [
      "", "not a date", "2024-03-05T", "2024-03-05T09", "2024-13-01", "2024-02-30",
      "2024/03/05", "24-03-05", "2024-03-05T24:00:00", "2024-03-05T09:60:00", "2024-03-05T09:30:61",
      "2024-03-05T09:30:15+25:00", "2024-03-05T09:30:15.", "2024-03-05T09:30.5",
      "2024-03-05T09:30:15Zx", "2024-03-05T09:30:15 ", " 2024-03-05", "2024-03-05  09:30",
      "2024-03-05T09:30:15 +09:00", "2024-03-05Z", "2024-03-05+09:00", "09:30:15Z",
      "09:30:15+09:00",
    ] {
    assert_iso8601_rejected(bad)
  }
}

///|
fn assert_iso8601_rejected(bad : String) -> Unit raise {
  try @format.parse_iso8601(bad) |> ignore catch {
    @format.InvalidIso8601 => ()
    _ => fail("expected InvalidIso8601 for \{bad}")
  } noraise {
    _ => fail("expected \{bad} to be rejected")
  }
}
