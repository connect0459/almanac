///|
test "to_rfc3339 renders a UTC instant with a trailing Z and no fractional seconds" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@format.to_rfc3339(dt), "2024-03-05T09:30:00Z")
}

///|
test "to_rfc3339 renders a non-zero fixed offset in colon-separated form, shifted to local wall-clock time" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.to_rfc3339(dt), "2024-03-05T18:30:00+09:00")
  let west = @tz.DateTime::from_utc(
    dt.naive_utc(),
    @tz.FixedOffset::west(5 * 3600).unwrap(),
  )
  assert_eq(@format.to_rfc3339(west), "2024-03-05T04:30:00-05:00")
}

///|
test "to_rfc3339 renders fractional seconds with the fewest of 3, 6 or 9 digits that represent them, omitting them entirely when zero" {
  let base = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  for
    case in [
      (0, "2024-03-05T09:30:00Z"),
      (123000000, "2024-03-05T09:30:00.123Z"),
      (100000000, "2024-03-05T09:30:00.100Z"),
      (500000000, "2024-03-05T09:30:00.500Z"),
      (123456000, "2024-03-05T09:30:00.123456Z"),
      (1000, "2024-03-05T09:30:00.000001Z"),
      (1, "2024-03-05T09:30:00.000000001Z"),
      (123456789, "2024-03-05T09:30:00.123456789Z"),
    ] {
    let (nanos, expected) = case
    let dt = @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        base,
        @core.NaiveTime::from_hms_nano(9, 30, 0, nanos).unwrap(),
      ),
      @tz.Utc::new(),
    )
    assert_eq(@format.to_rfc3339(dt), expected)
  }
}

///|
test "to_rfc3339 renders a leap second as :60, matching NaiveTime's leap-second convention" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2016, 12, 31).unwrap(),
      @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@format.to_rfc3339(dt), "2016-12-31T23:59:60.500Z")
}

///|
test "to_rfc3339 matches the general format engine byte-for-byte for a whole-second UTC instant" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(
    @format.to_rfc3339(dt),
    @format.format_date_time(naive, "%Y-%m-%dT%H:%M:%SZ"),
  )
}

///|
test "parse_rfc3339 round-trips through to_rfc3339 for a UTC instant" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms_nano(9, 30, 0, 123000000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  let text = @format.to_rfc3339(dt)
  let parsed = @format.parse_rfc3339(text)
  assert_eq(parsed.naive_utc(), dt.naive_utc())
  assert_eq(parsed.offset(), @tz.FixedOffset::east(0).unwrap())
}

///|
test "parse_rfc3339 round-trips through to_rfc3339 for a non-zero fixed offset" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600 + 30 * 60).unwrap(),
  )
  let text = @format.to_rfc3339(dt)
  let parsed = @format.parse_rfc3339(text)
  assert_eq(parsed.naive_utc(), dt.naive_utc())
  assert_eq(parsed.offset(), dt.offset())
}

///|
test "parse_rfc3339 accepts lowercase \"t\" and \"z\" separators" {
  let parsed = @format.parse_rfc3339("2024-03-05t09:30:00z")
  assert_eq(
    parsed.naive_utc(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
  )
  assert_eq(parsed.offset(), @tz.FixedOffset::east(0).unwrap())
}

///|
test "parse_rfc3339 accepts a numeric \"+00:00\" offset as equivalent to \"Z\"" {
  let parsed = @format.parse_rfc3339("2024-03-05T09:30:00+00:00")
  assert_eq(parsed.offset(), @tz.FixedOffset::east(0).unwrap())
}

///|
test "parse_rfc3339 accepts a leap second and reconstructs NaiveTime's leap-second representation" {
  let parsed = @format.parse_rfc3339("2016-12-31T23:59:60.5Z")
  assert_eq(
    parsed.naive_utc().time(),
    @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap(),
  )
}

///|
test "parse_rfc3339 truncates a fractional-second field with more than 9 digits" {
  let parsed = @format.parse_rfc3339("2024-03-05T09:30:00.1234567891234Z")
  assert_eq(
    parsed.naive_utc().time(),
    @core.NaiveTime::from_hms_nano(9, 30, 0, 123456789).unwrap(),
  )
}

///|
test "parse_rfc3339 rejects malformed input" {
  for
    bad in [
      "2024-03-05 09:30:00Z", // space instead of T
       "2024/03/05T09:30:00Z", // wrong date separator
       "2024-03-05T09:30:00", // missing offset
       "2024-03-05T09:30:00+09:00trailing", // trailing garbage
       "2024-13-05T09:30:00Z", // invalid month
       "2024-03-05T09:30:00+05:99", // invalid offset minutes
       "2024-03-05T09:30:00.Z", // "." with no digits
       "not-a-date", "", "2024-XXX05T09:30:00Z", // non-digit month
       "2024-03X05T09:30:00Z", // missing '-' before day
       "2024-03-XXT09:30:00Z", // non-digit day
       "2024-03-05TXX:30:00Z", // non-digit hour
       "2024-03-05T09X30:00Z", // missing ':' after hour
       "2024-03-05T09:XX:00Z", // non-digit minute
       "2024-03-05T09:30X00Z", // missing ':' after minute
       "2024-03-05T09:30:XXZ", // non-digit second
       "2024-03-05T09:30:61Z", // second out of range (above a leap second)
       "2024-03-05T24:00:00Z", // hour out of range
       "2024-03-05T09:30:00+XX:00", // non-digit offset hour
       "2024-03-05T09:30:00+09X00", // missing ':' in offset
       "2024-03-05T09:30:00+09:XX", // non-digit offset minute
       "2024-03-05T09:30:00+99:00", // offset magnitude out of range
       "2024-03-05T09:30:00Q", // unrecognized offset marker
    ] {
    try @format.parse_rfc3339(bad) |> ignore catch {
      @format.InvalidRfc3339 => ()
      _ => fail("expected InvalidRfc3339 for \{bad}")
    } noraise {
      _ => fail("expected parse_rfc3339 to reject \{bad}")
    }
  }
}

///|
fn opts_instant(
  nanos : Int64,
  offset_secs : Int,
) -> @tz.DateTime[@tz.FixedOffset] {
  let base = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 15).unwrap(),
  )
  @tz.DateTime::from_utc(
    base.add_signed(@core.TimeDelta::nanoseconds(nanos).unwrap()),
    @tz.FixedOffset::east(offset_secs).unwrap(),
  )
}

///|
test "to_rfc3339_opts renders a fixed number of fractional digits for Millis, Micros and Nanos, padding with zeros" {
  let dt = opts_instant(123_456_789L, 0)
  assert_eq(
    @format.to_rfc3339_opts(dt, @format.Millis),
    "2024-03-05T09:30:15.123Z",
  )
  assert_eq(
    @format.to_rfc3339_opts(dt, @format.Micros),
    "2024-03-05T09:30:15.123456Z",
  )
  assert_eq(
    @format.to_rfc3339_opts(dt, @format.Nanos),
    "2024-03-05T09:30:15.123456789Z",
  )
  let whole = opts_instant(0L, 0)
  assert_eq(
    @format.to_rfc3339_opts(whole, @format.Millis),
    "2024-03-05T09:30:15.000Z",
  )
  assert_eq(
    @format.to_rfc3339_opts(whole, @format.Nanos),
    "2024-03-05T09:30:15.000000000Z",
  )
}

///|
test "to_rfc3339_opts with Secs drops the fraction entirely" {
  assert_eq(
    @format.to_rfc3339_opts(opts_instant(999_999_999L, 0), @format.Secs),
    "2024-03-05T09:30:15Z",
  )
}

///|
test "to_rfc3339_opts truncates rather than rounds when fewer digits are asked for than the value has" {
  let dt = opts_instant(999_999_999L, 0)
  assert_eq(
    @format.to_rfc3339_opts(dt, @format.Millis),
    "2024-03-05T09:30:15.999Z",
  )
  assert_eq(
    @format.to_rfc3339_opts(dt, @format.Micros),
    "2024-03-05T09:30:15.999999Z",
  )
}

///|
test "to_rfc3339_opts with Auto matches to_rfc3339 when use_z is true" {
  for nanos in [0L, 500_000_000L, 123_456_000L, 123_456_789L] {
    let dt = opts_instant(nanos, 9 * 3600)
    assert_eq(@format.to_rfc3339_opts(dt, @format.Auto), @format.to_rfc3339(dt))
  }
}

///|
test "to_rfc3339_opts renders a zero offset as +00:00 when use_z is false and Z when it is true" {
  let dt = opts_instant(0L, 0)
  assert_eq(
    @format.to_rfc3339_opts(dt, @format.Secs, use_z=false),
    "2024-03-05T09:30:15+00:00",
  )
  assert_eq(@format.to_rfc3339_opts(dt, @format.Secs), "2024-03-05T09:30:15Z")
}

///|
test "to_rfc3339_opts ignores use_z for a non-zero offset" {
  let dt = opts_instant(0L, 9 * 3600)
  assert_eq(
    @format.to_rfc3339_opts(dt, @format.Secs),
    "2024-03-05T18:30:15+09:00",
  )
  assert_eq(
    @format.to_rfc3339_opts(dt, @format.Secs, use_z=false),
    "2024-03-05T18:30:15+09:00",
  )
}

///|
test "to_rfc3339_opts renders a leap second as :60 with the requested fraction" {
  let leap = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2016, 12, 31).unwrap(),
      @core.NaiveTime::from_hms_milli(23, 59, 59, 1_500).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(
    @format.to_rfc3339_opts(leap, @format.Millis),
    "2016-12-31T23:59:60.500Z",
  )
  assert_eq(@format.to_rfc3339_opts(leap, @format.Secs), "2016-12-31T23:59:60Z")
}
