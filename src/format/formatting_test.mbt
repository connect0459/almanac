///|
test "format_date renders year, month, day, and ordinal via %Y %m %d %j" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.format_date(date, "%Y-%m-%d (%j)"), "2024-03-05 (065)")
}

///|
test "format_date pads a negative (BCE) year while preserving its sign" {
  let date = @core.NaiveDate::from_ymd(-7, 1, 1).unwrap()
  assert_eq(@format.format_date(date, "%Y-%m-%d"), "-0007-01-01")
}

///|
test "format_date renders the long and short weekday names via %A and %a" {
  let tuesday = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  for
    case in [
      (-1, "Monday", "Mon"),
      (0, "Tuesday", "Tue"),
      (1, "Wednesday", "Wed"),
      (2, "Thursday", "Thu"),
      (3, "Friday", "Fri"),
      (4, "Saturday", "Sat"),
      (5, "Sunday", "Sun"),
    ] {
    let (offset, long_name, short_name) = case
    let date = tuesday.add_days(offset)
    assert_eq(@format.format_date(date, "%A"), long_name)
    assert_eq(@format.format_date(date, "%a"), short_name)
  }
}

///|
test "format_date raises MissingField for a time-of-day or timezone specifier" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  for
    case in [
      ("%H", @format.Numeric(@format.Hour)),
      ("%M", @format.Numeric(@format.Minute)),
      ("%S", @format.Numeric(@format.Second)),
      ("%f", @format.Numeric(@format.Nanosecond)),
      ("%I", @format.Numeric(@format.Hour12)),
      ("%l", @format.Numeric(@format.Hour12Blank)),
      ("%P", @format.Fixed(@format.AmPmLower)),
      ("%p", @format.Fixed(@format.AmPmUpper)),
      ("%Z", @format.Fixed(@format.TimezoneName)),
      ("%z", @format.Fixed(@format.TimezoneOffset)),
    ] {
    let (fmt, expected_item) = case
    try @format.format_date(date, fmt) |> ignore catch {
      @format.MissingField(item) => assert_eq(item, expected_item)
      _ => fail("expected MissingField")
    } noraise {
      _ => fail("expected format_date to raise MissingField")
    }
  }
}

///|
test "format_date renders the long and short month names via %B, %b, and %h" {
  let march = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.format_date(march, "%B"), "March")
  assert_eq(@format.format_date(march, "%b"), "Mar")
  assert_eq(@format.format_date(march, "%h"), "Mar")
  for
    case in [
      (1, "January", "Jan"),
      (2, "February", "Feb"),
      (4, "April", "Apr"),
      (5, "May", "May"),
      (6, "June", "Jun"),
      (7, "July", "Jul"),
      (8, "August", "Aug"),
      (9, "September", "Sep"),
      (10, "October", "Oct"),
      (11, "November", "Nov"),
      (12, "December", "Dec"),
    ] {
    let (month, long_name, short_name) = case
    let date = @core.NaiveDate::from_ymd(2024, month, 1).unwrap()
    assert_eq(@format.format_date(date, "%B"), long_name)
    assert_eq(@format.format_date(date, "%b"), short_name)
  }
}

///|
test "format_date renders the ISO week-date year and week number via %G, %g, and %V, distinct from the calendar year" {
  let date = @core.NaiveDate::from_ymd(2005, 1, 1).unwrap()
  assert_eq(@format.format_date(date, "%G"), "2004")
  assert_eq(@format.format_date(date, "%g"), "04")
  assert_eq(@format.format_date(date, "%V"), "53")
}

///|
test "format_time renders hour, minute, second, and nanosecond via %H %M %S %f" {
  let time = @core.NaiveTime::from_hms_nano(13, 5, 9, 123456789).unwrap()
  assert_eq(@format.format_time(time, "%H:%M:%S.%f"), "13:05:09.123456789")
}

///|
test "format_time renders a leap second as 60 while %f keeps only the sub-second fraction" {
  let leap = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  assert_eq(@format.format_time(leap, "%H:%M:%S.%f"), "23:59:60.500000000")
}

///|
test "format_time raises MissingField for a date, weekday, or timezone specifier" {
  let time = @core.NaiveTime::from_hms(9, 30, 0).unwrap()
  for
    case in [
      ("%Y", @format.Numeric(@format.Year)),
      ("%m", @format.Numeric(@format.Month)),
      ("%d", @format.Numeric(@format.Day)),
      ("%j", @format.Numeric(@format.Ordinal)),
      ("%A", @format.Fixed(@format.LongWeekdayName)),
      ("%a", @format.Fixed(@format.ShortWeekdayName)),
      ("%B", @format.Fixed(@format.LongMonthName)),
      ("%b", @format.Fixed(@format.ShortMonthName)),
      ("%h", @format.Fixed(@format.ShortMonthName)),
      ("%s", @format.Numeric(@format.Timestamp)),
      ("%G", @format.Numeric(@format.IsoYear)),
      ("%g", @format.Numeric(@format.IsoYear2)),
      ("%V", @format.Numeric(@format.IsoWeekNumber)),
      ("%Z", @format.Fixed(@format.TimezoneName)),
      ("%z", @format.Fixed(@format.TimezoneOffset)),
    ] {
    let (fmt, expected_item) = case
    try @format.format_time(time, fmt) |> ignore catch {
      @format.MissingField(item) => assert_eq(item, expected_item)
      _ => fail("expected MissingField")
    } noraise {
      _ => fail("expected format_time to raise MissingField")
    }
  }
}

///|
test "format_time renders the 12-hour clock and am/pm marker via %I, %l, %P, and %p" {
  for
    case in [
      (0, 0, "12", "12", "am", "AM"),
      (9, 5, "09", " 9", "am", "AM"),
      (12, 0, "12", "12", "pm", "PM"),
      (23, 45, "11", "11", "pm", "PM"),
    ] {
    let (hour, minute, i, l, p_lower, p_upper) = case
    let time = @core.NaiveTime::from_hms(hour, minute, 0).unwrap()
    assert_eq(@format.format_time(time, "%I"), i)
    assert_eq(@format.format_time(time, "%l"), l)
    assert_eq(@format.format_time(time, "%P"), p_lower)
    assert_eq(@format.format_time(time, "%p"), p_upper)
  }
}

///|
test "format_date_time renders date, time, and weekday fields together via %F %T %A" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  assert_eq(
    @format.format_date_time(dt, "%F %T %A"),
    "2024-03-05 09:30:00 Tuesday",
  )
}

///|
test "format_date_time renders %s as the Unix timestamp of the given datetime" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(@format.format_date_time(dt, "%s"), dt.timestamp().to_string())
}

///|
test "format_date_time_tz renders %s as the UTC instant's timestamp, unaffected by the local zone shift" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(
    @format.format_date_time_tz(dt, "%s"),
    naive.timestamp().to_string(),
  )
}

///|
test "format_date_time_tz renders the local wall-clock time shifted by the zone's offset" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.format_date_time_tz(dt, "%F %T"), "2024-03-05 18:30:00")
}

///|
test "format_date_time_tz renders %z as the zone's numeric offset, with no colon" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.format_date_time_tz(dt, "%z"), "+0900")
  let west = @tz.DateTime::from_utc(
    dt.naive_utc(),
    @tz.FixedOffset::west(5 * 3600).unwrap(),
  )
  assert_eq(@format.format_date_time_tz(west, "%z"), "-0500")
}

///|
test "format_date_time_tz renders %Z as \"UTC\" for the Utc zone and as the offset string for a bare FixedOffset" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  let utc_dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(@format.format_date_time_tz(utc_dt, "%Z"), "UTC")
  let fixed_dt = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.format_date_time_tz(fixed_dt, "%Z"), "+09:00")
}

///|
test "format_date_time_tz renders %Z as an IANA zone's abbreviation in effect at that instant" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  let dst_start_2024 = @core.NaiveDateTime::from_timestamp(1_710_054_000L, 0).unwrap()
  let dt = @tz.DateTime::from_utc(dst_start_2024, ny)
  assert_eq(@format.format_date_time_tz(dt, "%Z"), "EDT")
}

///|
test "format_date_time raises MissingField for a timezone specifier, since it carries no offset" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  for
    case in [
      ("%Z", @format.Fixed(@format.TimezoneName)),
      ("%z", @format.Fixed(@format.TimezoneOffset)),
    ] {
    let (fmt, expected_item) = case
    try @format.format_date_time(dt, fmt) |> ignore catch {
      @format.MissingField(item) => assert_eq(item, expected_item)
      _ => fail("expected MissingField")
    } noraise {
      _ => fail("expected format_date_time to raise MissingField")
    }
  }
}
