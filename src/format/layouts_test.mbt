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
  // rfc1123's %Z can't be parsed, kitchen has no seconds, and stamp/
  // stamp_milli/stamp_micro/stamp_nano carry no year at all (matching
  // Go's own layouts, meant for display alongside separately-known
  // context) — so only date_only/time_only round-trip on their own.
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
