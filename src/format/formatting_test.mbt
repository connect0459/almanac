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
      ("%.f", @format.Numeric(@format.DotFraction)),
      ("%3f", @format.Numeric(@format.Nanosecond3)),
      ("%6f", @format.Numeric(@format.Nanosecond6)),
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
test "format_date renders the century and year-without-century via %C and %y" {
  for case in [(2024, "20", "24"), (2005, "20", "05"), (1999, "19", "99")] {
    let (year, century, year_mod_100) = case
    let date = @core.NaiveDate::from_ymd(year, 1, 1).unwrap()
    assert_eq(@format.format_date(date, "%C"), century)
    assert_eq(@format.format_date(date, "%y"), year_mod_100)
  }
}

///|
test "format_date renders the quarter via %q" {
  for
    case in [
      (1, "1"),
      (3, "1"),
      (4, "2"),
      (6, "2"),
      (7, "3"),
      (9, "3"),
      (10, "4"),
      (12, "4"),
    ] {
    let (month, quarter) = case
    let date = @core.NaiveDate::from_ymd(2024, month, 1).unwrap()
    assert_eq(@format.format_date(date, "%q"), quarter)
  }
}

///|
test "format_date renders the space-padded day via %e" {
  assert_eq(
    @format.format_date(@core.NaiveDate::from_ymd(2024, 3, 5).unwrap(), "%e"),
    " 5",
  )
  assert_eq(
    @format.format_date(@core.NaiveDate::from_ymd(2024, 3, 15).unwrap(), "%e"),
    "15",
  )
}

///|
test "format_date renders the numeric weekday via %w (Sunday=0) and %u (Monday=1)" {
  let sunday = @core.NaiveDate::from_ymd(2024, 3, 3).unwrap()
  for offset in [0, 1, 2, 3, 4, 5, 6] {
    let date = sunday.add_days(offset)
    assert_eq(@format.format_date(date, "%w"), offset.to_string())
    let expected_u = if offset == 0 { 7 } else { offset }
    assert_eq(@format.format_date(date, "%u"), expected_u.to_string())
  }
}

///|
test "format_date renders the US-style week number via %U (Sunday start) and %W (Monday start)" {
  for
    case in [
      (2024, 1, 1, "00", "01"),
      (2024, 1, 6, "00", "01"),
      (2024, 1, 7, "01", "01"),
      (2024, 1, 8, "01", "02"),
      (2024, 12, 31, "52", "53"),
      (2023, 1, 1, "01", "00"),
      (2023, 1, 2, "01", "01"),
      (2021, 1, 1, "00", "00"),
      (2021, 1, 3, "01", "00"),
      (2021, 1, 4, "01", "01"),
    ] {
    let (year, month, day, u, w) = case
    let date = @core.NaiveDate::from_ymd(year, month, day).unwrap()
    assert_eq(@format.format_date(date, "%U"), u)
    assert_eq(@format.format_date(date, "%W"), w)
  }
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
test "format_time renders %.f with the fewest of 3, 6 or 9 digits that represent the nanoseconds, or nothing when zero" {
  for
    case in [
      (0, ""),
      (500000000, ".500"),
      (120000000, ".120"),
      (1000000, ".001"),
      (123456000, ".123456"),
      (100000, ".000100"),
      (1000, ".000001"),
      (123456789, ".123456789"),
      (1, ".000000001"),
    ] {
    let (nanos, expected) = case
    let time = @core.NaiveTime::from_hms_nano(9, 30, 0, nanos).unwrap()
    assert_eq(@format.format_time(time, "%.f"), expected)
  }
}

///|
test "format_time renders %3f, %6f, and %9f as always-present, fixed-width truncated fractions" {
  let time = @core.NaiveTime::from_hms_nano(9, 30, 0, 123456789).unwrap()
  assert_eq(@format.format_time(time, "%3f"), "123")
  assert_eq(@format.format_time(time, "%6f"), "123456")
  assert_eq(@format.format_time(time, "%9f"), "123456789")
  let zero = @core.NaiveTime::from_hms(9, 30, 0).unwrap()
  assert_eq(@format.format_time(zero, "%3f"), "000")
  assert_eq(@format.format_time(zero, "%6f"), "000000")
  assert_eq(@format.format_time(zero, "%9f"), "000000000")
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
      ("%C", @format.Numeric(@format.Century)),
      ("%y", @format.Numeric(@format.YearMod100)),
      ("%q", @format.Numeric(@format.Quarter)),
      ("%e", @format.Numeric(@format.DayBlank)),
      ("%w", @format.Numeric(@format.WeekdayNumberSunday0)),
      ("%u", @format.Numeric(@format.WeekdayNumberMonday1)),
      ("%U", @format.Numeric(@format.WeekSunday)),
      ("%W", @format.Numeric(@format.WeekMonday)),
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
test "format_date_time_tz renders %:z as ±HH:MM, %::z as ±HH:MM:SS, and %:::z as ±HH only" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  let east = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.format_date_time_tz(east, "%:z"), "+09:00")
  assert_eq(@format.format_date_time_tz(east, "%::z"), "+09:00:00")
  assert_eq(@format.format_date_time_tz(east, "%:::z"), "+09")
  let west = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::west(5 * 3600).unwrap(),
  )
  assert_eq(@format.format_date_time_tz(west, "%:z"), "-05:00")
  assert_eq(@format.format_date_time_tz(west, "%::z"), "-05:00:00")
  assert_eq(@format.format_date_time_tz(west, "%:::z"), "-05")
  // A non-whole-minute historical offset: only %::z can represent it exactly.
  let sub_minute = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600 + 30 * 60 + 15).unwrap(),
  )
  assert_eq(@format.format_date_time_tz(sub_minute, "%::z"), "+09:30:15")
}

///|
test "format_date_time_tz raises MissingField for %#z, which is parse-only" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  try @format.format_date_time_tz(dt, "%#z") |> ignore catch {
    @format.MissingField(@format.Fixed(@format.TimezoneOffsetPermissive)) => ()
    _ => fail("expected MissingField(Fixed(TimezoneOffsetPermissive))")
  } noraise {
    _ => fail("expected format_date_time_tz to reject %#z")
  }
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
test "format_date renders the compound date specifiers %D, %x, and %v" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.format_date(date, "%D"), "03/05/24")
  assert_eq(@format.format_date(date, "%x"), "03/05/24")
  assert_eq(@format.format_date(date, "%v"), " 5-Mar-2024")
}

///|
test "format_time renders the compound time specifiers %R, %X, and %r" {
  let time = @core.NaiveTime::from_hms(9, 5, 30).unwrap()
  assert_eq(@format.format_time(time, "%R"), "09:05")
  assert_eq(@format.format_time(time, "%X"), "09:05:30")
  assert_eq(@format.format_time(time, "%r"), "09:05:30 AM")
}

///|
test "format_date_time renders the ctime-style compound specifier %c" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 5, 30).unwrap(),
  )
  assert_eq(@format.format_date_time(dt, "%c"), "Tue Mar  5 09:05:30 2024")
}

///|
test "format_date_time_tz renders %+ identically to to_rfc3339" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms_nano(9, 30, 0, 123000000).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.format_date_time_tz(dt, "%+"), @format.to_rfc3339(dt))
  assert_eq(
    @format.format_date_time_tz(dt, "%+"),
    "2024-03-05T18:30:00.123+09:00",
  )
}

///|
test "format_date, format_time, and format_date_time raise MissingField for %+, which needs a date, time, and offset together" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @core.NaiveTime::from_hms(9, 30, 0).unwrap()
  let dt = @core.NaiveDateTime::new(date, time)
  try @format.format_date(date, "%+") |> ignore catch {
    @format.MissingField(@format.Rfc3339) => ()
    _ => fail("expected MissingField(Rfc3339)")
  } noraise {
    _ => fail("expected format_date to reject %+")
  }
  try @format.format_time(time, "%+") |> ignore catch {
    @format.MissingField(@format.Rfc3339) => ()
    _ => fail("expected MissingField(Rfc3339)")
  } noraise {
    _ => fail("expected format_time to reject %+")
  }
  try @format.format_date_time(dt, "%+") |> ignore catch {
    @format.MissingField(@format.Rfc3339) => ()
    _ => fail("expected MissingField(Rfc3339)")
  } noraise {
    _ => fail("expected format_date_time to reject %+")
  }
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
      ("%:z", @format.Fixed(@format.TimezoneOffsetColonMinutes)),
      ("%::z", @format.Fixed(@format.TimezoneOffsetColonSeconds)),
      ("%:::z", @format.Fixed(@format.TimezoneOffsetColonHours)),
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

///|
test "format_date renders %-Y with no padding, even for a value that normally zero-pads" {
  let date = @core.NaiveDate::from_ymd(24, 3, 5).unwrap()
  assert_eq(@format.format_date(date, "%-Y"), "24")
  assert_eq(@format.format_date(date, "%Y"), "0024")
}

///|
test "format_date renders %0e with zero-padding, overriding %e's normal space-padding" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.format_date(date, "%0e"), "05")
  assert_eq(@format.format_date(date, "%e"), " 5")
}

///|
test "format_date renders %_d with space-padding, overriding %d's normal zero-padding" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.format_date(date, "%_d"), " 5")
  assert_eq(@format.format_date(date, "%d"), "05")
}

///|
test "format_date preserves the sign for %-Y and %_Y on a negative (BCE) year" {
  let date = @core.NaiveDate::from_ymd(-7, 1, 1).unwrap()
  assert_eq(@format.format_date(date, "%-Y"), "-7")
  assert_eq(@format.format_date(date, "%_Y"), "  -7")
}

///|
test "format_date/format_time render every eligible Numeric kind via %0<X>, matching the bare specifier's own zero-padded default" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @core.NaiveTime::from_hms(9, 5, 3).unwrap()
  for
    letter in [
      "Y", "m", "d", "j", "G", "g", "V", "C", "y", "U", "W", "q", "w", "u",
    ] {
    assert_eq(
      @format.format_date(date, "%0" + letter),
      @format.format_date(date, "%" + letter),
    )
  }
  for letter in ["H", "M", "S", "I"] {
    assert_eq(
      @format.format_time(time, "%0" + letter),
      @format.format_time(time, "%" + letter),
    )
  }
  // DayBlank/Hour12Blank default to space-padding, so %0 visibly differs.
  assert_eq(@format.format_date(date, "%0e"), "05")
  assert_eq(@format.format_time(time, "%0l"), "09")
}

///|
test "format_time/format_date raise MissingField for every eligible padding-flagged specifier when its data is absent" {
  let time = @core.NaiveTime::from_hms(9, 5, 3).unwrap()
  for
    letter in [
      "Y", "m", "d", "j", "G", "g", "V", "C", "y", "q", "e", "w", "u", "U", "W",
    ] {
    try @format.format_time(time, "%0" + letter) |> ignore catch {
      @format.MissingField(@format.PaddedNumeric(_, _)) => ()
      _ => fail("expected MissingField for %0\{letter}")
    } noraise {
      _ => fail("expected format_time to reject %0\{letter}")
    }
  }
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  for letter in ["H", "M", "S", "I", "l"] {
    try @format.format_date(date, "%0" + letter) |> ignore catch {
      @format.MissingField(@format.PaddedNumeric(_, _)) => ()
      _ => fail("expected MissingField for %0\{letter}")
    } noraise {
      _ => fail("expected format_date to reject %0\{letter}")
    }
  }
}

///|
test "format_date_time_tz renders %Z as a FixedZone's name rather than its offset" {
  let zone = @tz.FixedZone::new("JST", @tz.FixedOffset::east(9 * 3600).unwrap())
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
    ),
    zone,
  )
  assert_eq(@format.format_date_time_tz(dt, "%T %Z %z"), "21:00:00 JST +0900")
}
