///|
test "rfc1123 renders a weekday, zero-padded day, short month, year, time, and zone name" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 5, 3).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(
    @format.format_date_time_tz(dt, @format.rfc1123),
    "Tue, 05 Mar 2024 09:05:03 UTC",
  )
}

///|
test "kitchen renders an unpadded 12-hour clock immediately followed by am/pm, no colon padding on the hour" {
  for
    case in [
      (9, 5, "9:05AM"),
      (0, 0, "12:00AM"),
      (13, 30, "1:30PM"),
      (23, 59, "11:59PM"),
    ] {
    let (hour, minute, expected) = case
    let time = @core.NaiveTime::from_hms(hour, minute, 0).unwrap()
    assert_eq(@format.format_time(time, @format.kitchen), expected)
  }
}

///|
test "stamp renders a short month, space-padded day, and HH:MM:SS" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 5, 3).unwrap(),
  )
  assert_eq(@format.format_date_time(dt, @format.stamp), "Mar  5 09:05:03")
  let two_digit_day = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 5, 3).unwrap(),
  )
  assert_eq(
    @format.format_date_time(two_digit_day, @format.stamp),
    "Mar 15 09:05:03",
  )
}

///|
test "stamp_milli/stamp_micro/stamp_nano render stamp with fixed-width fractional seconds" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms_nano(9, 5, 3, 123456789).unwrap(),
  )
  assert_eq(
    @format.format_date_time(dt, @format.stamp_milli),
    "Mar  5 09:05:03.123",
  )
  assert_eq(
    @format.format_date_time(dt, @format.stamp_micro),
    "Mar  5 09:05:03.123456",
  )
  assert_eq(
    @format.format_date_time(dt, @format.stamp_nano),
    "Mar  5 09:05:03.123456789",
  )
}

///|
test "date_only renders %Y-%m-%d" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.format_date(date, @format.date_only), "2024-03-05")
}

///|
test "time_only renders %H:%M:%S" {
  let time = @core.NaiveTime::from_hms(9, 5, 3).unwrap()
  assert_eq(@format.format_time(time, @format.time_only), "09:05:03")
}

///|
test "date_only and time_only round-trip through parse_date/parse_time, being the only layouts here with a complete field set for it" {
  // kitchen has no seconds, and stamp/stamp_milli/stamp_micro/stamp_nano
  // carry no year at all (meant for display alongside
  // separately-known context) — so only date_only/time_only
  // round-trip on their own.
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(
    @format.parse_date(
      @format.format_date(date, @format.date_only),
      @format.date_only,
    ),
    date,
  )
  let time = @core.NaiveTime::from_hms(9, 5, 3).unwrap()
  assert_eq(
    @format.parse_time(
      @format.format_time(time, @format.time_only),
      @format.time_only,
    ),
    time,
  )
}

///|
test "rfc1123 parses back into its wall-clock reading, discarding the zone name" {
  let parsed = @format.parse_date_time(
    "Tue, 05 Mar 2024 09:05:03 UTC", @format.rfc1123,
  )
  assert_eq(
    parsed,
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 5, 3).unwrap(),
    ),
  )
}

///|
fn layout_instant() -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 5, 3).unwrap(),
  )
}

///|
fn layout_utc() -> @tz.DateTime[@tz.Utc] {
  @tz.DateTime::from_utc(layout_instant(), @tz.Utc::new())
}

///|
fn layout_tokyo() -> @tz.DateTime[@tz.FixedOffset] {
  @tz.DateTime::from_utc(
    layout_instant(),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
}

///|
test "each added layout constant is its documented strftime string" {
  assert_eq(@format.ansic, "%a %b %e %H:%M:%S %Y")
  assert_eq(@format.unix_date, "%a %b %e %H:%M:%S %Z %Y")
  assert_eq(@format.ruby_date, "%a %b %d %H:%M:%S %z %Y")
  assert_eq(@format.rfc822, "%d %b %y %H:%M %Z")
  assert_eq(@format.rfc822z, "%d %b %y %H:%M %z")
  assert_eq(@format.rfc850, "%A, %d-%b-%y %H:%M:%S %Z")
  assert_eq(@format.rfc1123z, "%a, %d %b %Y %H:%M:%S %z")
  assert_eq(@format.date_time, "%F %T")
}

///|
test "the layout constants render the documented text for a known instant" {
  assert_eq(
    @format.format_date_time_tz(layout_utc(), @format.ansic),
    "Tue Mar  5 09:05:03 2024",
  )
  assert_eq(
    @format.format_date_time_tz(layout_utc(), @format.unix_date),
    "Tue Mar  5 09:05:03 UTC 2024",
  )
  assert_eq(
    @format.format_date_time_tz(layout_tokyo(), @format.ruby_date),
    "Tue Mar 05 18:05:03 +0900 2024",
  )
  assert_eq(
    @format.format_date_time_tz(layout_utc(), @format.rfc822),
    "05 Mar 24 09:05 UTC",
  )
  assert_eq(
    @format.format_date_time_tz(layout_tokyo(), @format.rfc822z),
    "05 Mar 24 18:05 +0900",
  )
  assert_eq(
    @format.format_date_time_tz(layout_utc(), @format.rfc850),
    "Tuesday, 05-Mar-24 09:05:03 UTC",
  )
  assert_eq(
    @format.format_date_time_tz(layout_tokyo(), @format.rfc1123z),
    "Tue, 05 Mar 2024 18:05:03 +0900",
  )
  assert_eq(
    @format.format_date_time(layout_instant(), @format.date_time),
    "2024-03-05 09:05:03",
  )
}

///|
test "the numeric-offset layouts read back the instant and offset they render" {
  for layout in [@format.ruby_date, @format.rfc1123z] {
    let text = @format.format_date_time_tz(layout_tokyo(), layout)
    assert_eq(
      @format.parse_date_time_fixed_offset(text, layout),
      layout_tokyo(),
    )
  }
}

///|
test "the zone-name layouts read back the wall-clock reading they render" {
  for layout in [@format.unix_date, @format.rfc850, @format.ansic] {
    let text = @format.format_date_time_tz(layout_utc(), layout)
    assert_eq(@format.parse_date_time(text, layout), layout_instant())
  }
}

///|
test "date_time reads back what it renders" {
  assert_eq(
    @format.parse_date_time(
      @format.format_date_time(layout_instant(), @format.date_time),
      @format.date_time,
    ),
    layout_instant(),
  )
}

///|
test "the minute-precision RFC 822 layouts drop the seconds and read back zero" {
  let on_the_minute = @core.NaiveDateTime::new(
    layout_instant().date(),
    @core.NaiveTime::from_hms(9, 5, 0).unwrap(),
  )
  let text = @format.format_date_time_tz(layout_utc(), @format.rfc822)
  assert_eq(@format.parse_date_time(text, @format.rfc822), on_the_minute)
  let zoned = @format.format_date_time_tz(layout_tokyo(), @format.rfc822z)
  assert_eq(
    @format.parse_date_time_fixed_offset(zoned, @format.rfc822z).naive_local(),
    @core.NaiveDateTime::new(
      layout_instant().date(),
      @core.NaiveTime::from_hms(18, 5, 0).unwrap(),
    ),
  )
}

///|
test "the two-digit-year layouts read 69 and below as 20xx and 70 and above as 19xx" {
  assert_eq(
    @format.parse_date_time("05 Mar 69 09:05 UTC", @format.rfc822).date(),
    @core.NaiveDate::from_ymd(2069, 3, 5).unwrap(),
  )
  assert_eq(
    @format.parse_date_time("05 Mar 70 09:05 UTC", @format.rfc822).date(),
    @core.NaiveDate::from_ymd(1970, 3, 5).unwrap(),
  )
}
