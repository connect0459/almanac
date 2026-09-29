///|
test "parse_date round-trips through format_date for a positive year" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let fmt = "%Y-%m-%d (%j) %A"
  assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
}

///|
test "parse_date round-trips through format_date for a negative (BCE) year" {
  let date = @core.NaiveDate::from_ymd(-7, 1, 1).unwrap()
  let fmt = "%Y-%m-%d"
  assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
}

///|
test "parse_date rejects a weekday name inconsistent with the actual date" {
  try
    @format.parse_date("2024-03-05 Wednesday", "%Y-%m-%d %A") |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject a mismatched weekday")
  }
}

///|
test "parse_date rejects a format with no date field at all" {
  try @format.parse_date("09", "%H") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected parse_date to reject a dateless format")
  }
}

///|
test "parse_date rejects input whose literal text doesn't match the format" {
  try @format.parse_date("2024/03/05", "%Y-%m-%d") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected parse_date to reject a wrong separator")
  }
}

///|
test "parse_date rejects trailing input beyond what the format consumes" {
  try @format.parse_date("2024extra", "%Y") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected parse_date to reject trailing garbage")
  }
}

///|
test "parse_date round-trips using the short weekday name and an ordinal-only date" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let fmt = "%Y-%j %a"
  assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
}

///|
test "parse_date rejects a calendar-invalid month/day combination" {
  try @format.parse_date("2024-02-30", "%Y-%m-%d") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject Feb 30")
  }
}

///|
test "parse_date rejects an out-of-range ordinal for the given year" {
  try @format.parse_date("2023-366", "%Y-%j") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject ordinal 366 in a non-leap year")
  }
}

///|
test "parse_date rejects a year with neither month/day nor an ordinal" {
  try @format.parse_date("2024", "%Y") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected parse_date to reject a year-only format")
  }
}

///|
test "parse_date rejects a format with month present but no day" {
  try @format.parse_date("2024-03", "%Y-%m") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected parse_date to reject a monthless-day format")
  }
}

///|
test "parse_date rejects unrecognized weekday text" {
  try @format.parse_date("2024-03-05 Blah", "%Y-%m-%d %A") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected parse_date to reject unrecognized weekday text")
  }
}

///|
test "parse_date rejects input that runs out before a literal separator" {
  try @format.parse_date("2024-03", "%Y-%m-%d") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected parse_date to reject truncated input")
  }
}

///|
test "parse_date rejects a non-digit year" {
  try @format.parse_date("abcd-03-05", "%Y-%m-%d") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected parse_date to reject a non-digit year")
  }
}

///|
test "parsing rejects a malformed numeric field for every fixed-width numeric specifier" {
  for
    case in [
      ("%m", "XX"),
      ("%d", "XX"),
      ("%j", "12"),
      ("%H", "XX"),
      ("%M", "XX"),
      ("%S", "XX"),
      ("%f", "12345"),
      ("%I", "XX"),
      ("%C", "XX"),
      ("%y", "XX"),
      ("%q", "X"),
      ("%e", "XX"),
      ("%w", "X"),
      ("%u", "X"),
      ("%U", "XX"),
      ("%W", "XX"),
    ] {
    let (fmt, bad) = case
    try @format.parse_date_time(bad, fmt) |> ignore catch {
      @format.InputMismatch => ()
      _ => fail("expected InputMismatch for \{fmt}")
    } noraise {
      _ => fail("expected rejection for \{fmt}")
    }
  }
}

///|
test "parsing rejects the same specifier appearing twice with different values" {
  try @format.parse_time("09 10", "%H %H") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ =>
      fail("expected rejection for a duplicate specifier with different values")
  }
}

///|
test "parse_date cross-checks a redundantly-present ordinal against month/day" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let fmt = "%Y-%m-%d (%j)"
  assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
  try @format.parse_date("2024-03-05 (999)", fmt) |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject a mismatched ordinal")
  }
}

///|
test "parse_time round-trips nanosecond precision through format_time" {
  let time = @core.NaiveTime::from_hms_nano(13, 5, 9, 123456789).unwrap()
  let fmt = "%H:%M:%S.%f"
  assert_eq(@format.parse_time(@format.format_time(time, fmt), fmt), time)
}

///|
test "parse_time round-trips a leap second through format_time" {
  let leap = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  let fmt = "%H:%M:%S.%f"
  assert_eq(@format.parse_time(@format.format_time(leap, fmt), fmt), leap)
}

///|
test "parse_time rejects an out-of-range hour" {
  try @format.parse_time("25:00:00", "%H:%M:%S") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_time to reject an out-of-range hour")
  }
}

///|
test "parse_time rejects a format missing the hour, minute, or second field" {
  for case in [("30:00", "%M:%S"), ("09:00", "%H:%S"), ("09:30", "%H:%M")] {
    let (input, fmt) = case
    try @format.parse_time(input, fmt) |> ignore catch {
      @format.IncompleteFields => ()
      _ => fail("expected IncompleteFields for \{fmt}")
    } noraise {
      _ => fail("expected rejection for \{fmt}")
    }
  }
}

///|
test "parse_date_time round-trips through format_date_time" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  let fmt = "%F %T %A"
  assert_eq(@format.parse_date_time(@format.format_date_time(dt, fmt), fmt), dt)
}

///|
test "parse_date_time_tz round-trips through format_date_time_tz for a positive and a negative offset" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  let fmt = "%F %T%z"
  let east = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  let east_text = @format.format_date_time_tz(east, fmt)
  let east_parsed = @format.parse_date_time_tz(east_text, fmt)
  assert_eq(east_parsed.naive_utc(), east.naive_utc())
  assert_eq(east_parsed.offset(), east.offset())
  let west = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::west(5 * 3600).unwrap(),
  )
  let west_text = @format.format_date_time_tz(west, fmt)
  let west_parsed = @format.parse_date_time_tz(west_text, fmt)
  assert_eq(west_parsed.naive_utc(), west.naive_utc())
  assert_eq(west_parsed.offset(), west.offset())
}

///|
test "parse_date_time_tz rejects a malformed %z field" {
  for
    bad in [
      "2024-03-05 09:30:00", // %z present in fmt but absent from input
       "2024-03-05 09:30:00Z", // RFC 3339's "Z" isn't valid for strftime %z
       "2024-03-05 09:30:00+XX00", // non-digit offset hour
       "2024-03-05 09:30:00+09XX", // non-digit offset minute
       "2024-03-05 09:30:00+0999", // offset minute out of range
    ] {
    try @format.parse_date_time_tz(bad, "%F %T%z") |> ignore catch {
      @format.InputMismatch => ()
      _ => fail("expected InputMismatch for \{bad}")
    } noraise {
      _ => fail("expected rejection for \{bad}")
    }
  }
}

///|
test "parse_date_time_tz rejects an offset magnitude outside FixedOffset's range" {
  try
    @format.parse_date_time_tz("2024-03-05 09:30:00+9900", "%F %T%z") |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected rejection for an out-of-range offset magnitude")
  }
}

///|
test "parse_date_time_tz rejects a format with no offset field" {
  try
    @format.parse_date_time_tz("2024-03-05 09:30:00", "%F %T") |> ignore
  catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected parse_date_time_tz to reject a format without %z")
  }
}

///|
test "parsing %Z always raises InputMismatch, since a zone name can't be resolved generically" {
  try @format.parse_date_time("anything", "%Z") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected parse_date_time to reject %Z")
  }
}

///|
test "parse_date round-trips using the long or short month name alongside day and year" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(
    @format.parse_date(@format.format_date(date, "%B %d %Y"), "%B %d %Y"),
    date,
  )
  assert_eq(
    @format.parse_date(@format.format_date(date, "%b %d %Y"), "%b %d %Y"),
    date,
  )
  assert_eq(@format.parse_date("05 Mar 2024", "%d %h %Y"), date)
}

///|
test "parse_date rejects unrecognized month name text" {
  try @format.parse_date("Blah 05 2024", "%B %d %Y") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected parse_date to reject unrecognized month text")
  }
}

///|
test "parse_time round-trips the 12-hour clock and am/pm marker through format_time" {
  for case in [(0, 0), (9, 5), (12, 0), (13, 30), (23, 45)] {
    let (hour, minute) = case
    let time = @core.NaiveTime::from_hms(hour, minute, 0).unwrap()
    assert_eq(
      @format.parse_time(
        @format.format_time(time, "%I:%M:%S %p"),
        "%I:%M:%S %p",
      ),
      time,
    )
    assert_eq(
      @format.parse_time(
        @format.format_time(time, "%l:%M:%S %P"),
        "%l:%M:%S %P",
      ),
      time,
    )
  }
}

///|
test "parse_time accepts %p/%P case-insensitively regardless of which specifier rendered it" {
  let time = @core.NaiveTime::from_hms(15, 0, 0).unwrap()
  assert_eq(@format.parse_time("03:00:00 pm", "%I:%M:%S %p"), time)
  assert_eq(@format.parse_time("03:00:00 PM", "%I:%M:%S %p"), time)
  assert_eq(@format.parse_time("03:00:00 pm", "%I:%M:%S %P"), time)
}

///|
test "parse_time rejects a 12-hour value present without its am/pm marker" {
  try @format.parse_time("09:00", "%I:%M") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected parse_time to reject %I without %p/%P")
  }
}

///|
test "parse_time cross-checks a redundant 12-hour field against %H, accepting agreement and rejecting disagreement" {
  assert_eq(
    @format.parse_time("15:00:00 03 PM", "%H:%M:%S %I %p"),
    @core.NaiveTime::from_hms(15, 0, 0).unwrap(),
  )
  try @format.parse_time("15:00:00 04 PM", "%H:%M:%S %I %p") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_time to reject a disagreeing 12-hour field")
  }
}

///|
test "parse_time rejects unrecognized am/pm text" {
  for bad in ["xm", "ax", "qm", "px"] {
    try @format.parse_time("03:00:00 " + bad, "%I:%M:%S %p") |> ignore catch {
      @format.InputMismatch => ()
      _ => fail("expected InputMismatch for \{bad}")
    } noraise {
      _ => fail("expected rejection for \{bad}")
    }
  }
}

///|
test "parse_time rejects a malformed %l field (neither two digits nor a space plus one digit)" {
  try @format.parse_time("XX:00:00 PM", "%l:%M:%S %p") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected rejection for a malformed %l field")
  }
}

///|
test "parse_time rejects a 12-hour value outside 1..=12" {
  try @format.parse_time("00:00:00 AM", "%I:%M:%S %p") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected rejection for an out-of-range %I value")
  }
}

///|
test "parse_date cross-checks a redundantly-present quarter against month/day" {
  let date = @core.NaiveDate::from_ymd(2024, 7, 15).unwrap()
  let fmt = "%Y-%m-%d (%q)"
  assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
  try @format.parse_date("2024-07-15 (1)", fmt) |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject a mismatched quarter")
  }
}

///|
test "parse_date round-trips the space-padded day via %e, sharing %d's field" {
  let fmt = "%Y-%m-%e"
  for day in [5, 15] {
    let date = @core.NaiveDate::from_ymd(2024, 3, day).unwrap()
    assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
  }
  assert_eq(
    @format.parse_date("2024-03- 5", fmt),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
}

///|
test "parse_date round-trips the numeric weekday via %w and %u across every day of the week, cross-checked against %A" {
  let sunday = @core.NaiveDate::from_ymd(2024, 3, 3).unwrap()
  for offset in [0, 1, 2, 3, 4, 5, 6] {
    let date = sunday.add_days(offset)
    assert_eq(
      @format.parse_date(
        @format.format_date(date, "%Y-%m-%d %w"),
        "%Y-%m-%d %w",
      ),
      date,
    )
    assert_eq(
      @format.parse_date(
        @format.format_date(date, "%Y-%m-%d %u"),
        "%Y-%m-%d %u",
      ),
      date,
    )
  }
  try
    @format.parse_date("2024-03-05 Tuesday 1", "%Y-%m-%d %A %u") |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject a %A/%u disagreement")
  }
}

///|
test "parsing %w/%u rejects a digit outside the valid weekday range" {
  try @format.parse_date("2024-03-05 7", "%Y-%m-%d %w") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected rejection for an out-of-range %w value")
  }
  try @format.parse_date("2024-03-05 0", "%Y-%m-%d %u") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected rejection for an out-of-range %u value")
  }
}

///|
test "parse_date reconstructs the year from %C and %y together" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let fmt = "%C%y-%m-%d"
  assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
}

///|
test "parse_date interprets a lone %y (no %C) via the conventional pivot: below 70 is 20xx, at or above 70 is 19xx" {
  assert_eq(
    @format.parse_date("24-03-05", "%y-%m-%d"),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
  assert_eq(
    @format.parse_date("69-03-05", "%y-%m-%d"),
    @core.NaiveDate::from_ymd(2069, 3, 5).unwrap(),
  )
  assert_eq(
    @format.parse_date("70-03-05", "%y-%m-%d"),
    @core.NaiveDate::from_ymd(1970, 3, 5).unwrap(),
  )
  assert_eq(
    @format.parse_date("99-03-05", "%y-%m-%d"),
    @core.NaiveDate::from_ymd(1999, 3, 5).unwrap(),
  )
}

///|
test "parse_date rejects %C without %y, since a century alone is insufficient" {
  try @format.parse_date("20-03-05", "%C-%m-%d") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected parse_date to reject %C without %y")
  }
}

///|
test "parse_date cross-checks %Y against a redundantly-present %C/%y, and rejects a negative year combined with either" {
  assert_eq(
    @format.parse_date("2024-20-24-03-05", "%Y-%C-%y-%m-%d"),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
  try @format.parse_date("2024-19-24-03-05", "%Y-%C-%y-%m-%d") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject a mismatched %C")
  }
  try
    @format.parse_date("-0007-00-93-01-01", "%Y-%C-%y-%m-%d") |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ =>
      fail("expected parse_date to reject a negative year combined with %C/%y")
  }
}

///|
test "parse_date round-trips the US-style week number via %U/%W combined with a weekday" {
  for
    case in [
      (2024, 1, 1),
      (2024, 1, 6),
      (2024, 1, 7),
      (2024, 1, 8),
      (2024, 12, 31),
      (2023, 1, 1),
      (2023, 1, 2),
      (2021, 1, 1),
      (2021, 1, 3),
      (2021, 1, 4),
    ] {
    let (year, month, day) = case
    let date = @core.NaiveDate::from_ymd(year, month, day).unwrap()
    let u_fmt = "%Y %U %A"
    assert_eq(@format.parse_date(@format.format_date(date, u_fmt), u_fmt), date)
    let w_fmt = "%Y %W %A"
    assert_eq(@format.parse_date(@format.format_date(date, w_fmt), w_fmt), date)
  }
}

///|
test "parse_date rejects %U/%W without a weekday, since the week number alone doesn't determine a day" {
  try @format.parse_date("2024 01", "%Y %U") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected parse_date to reject %U without a weekday")
  }
}

///|
test "parse_date rejects a %U/%W and weekday combination that names an impossible date" {
  try @format.parse_date("2024 53 Sunday", "%Y %U %A") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ =>
      fail("expected parse_date to reject an impossible %U/weekday combination")
  }
}

///|
test "parse_date rejects disagreeing %U and %W values for the same date" {
  try @format.parse_date("2024 01 05 Monday", "%Y %U %W %A") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject disagreeing %U/%W")
  }
}

///|
test "parse_date cross-checks a redundantly-present %U/%W against an already-determined date" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let u_fmt = "%Y-%m-%d %U"
  assert_eq(@format.parse_date(@format.format_date(date, u_fmt), u_fmt), date)
  try @format.parse_date("2024-03-05 99", u_fmt) |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject a mismatched %U")
  }
  let w_fmt = "%Y-%m-%d %W"
  assert_eq(@format.parse_date(@format.format_date(date, w_fmt), w_fmt), date)
  try @format.parse_date("2024-03-05 99", w_fmt) |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date to reject a mismatched %W")
  }
}

///|
test "parse_date rejects a weekday with no month/day/ordinal and no %U/%W to combine it with" {
  try @format.parse_date("2024 Monday", "%Y %A") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ =>
      fail(
        "expected parse_date to reject a bare weekday with no other date fields",
      )
  }
}

///|
test "parse_date round-trips through the compound date specifiers %D, %x, and %v" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  for fmt in ["%D", "%x", "%v"] {
    assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
  }
}

///|
test "parse_time round-trips through the compound time specifiers %X and %r" {
  for
    case in [
      @core.NaiveTime::from_hms(9, 5, 0).unwrap(),
      @core.NaiveTime::from_hms(9, 5, 30).unwrap(),
      @core.NaiveTime::from_hms(21, 45, 30).unwrap(),
    ] {
    assert_eq(@format.parse_time(@format.format_time(case, "%X"), "%X"), case)
    assert_eq(@format.parse_time(@format.format_time(case, "%r"), "%r"), case)
  }
}

///|
test "parse_time parses %R's hour and minute fields, but rejects it alone since %R carries no seconds" {
  assert_eq(
    @format.parse_time("09:05 30", "%R %S"),
    @core.NaiveTime::from_hms(9, 5, 30).unwrap(),
  )
  try @format.parse_time("09:05", "%R") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected parse_time to reject a bare %R with no seconds field")
  }
}

///|
test "parse_date_time round-trips through the ctime-style compound specifier %c" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 5, 30).unwrap(),
  )
  assert_eq(
    @format.parse_date_time(@format.format_date_time(dt, "%c"), "%c"),
    dt,
  )
}

///|
test "parse_date_time_tz round-trips through %+ identically to parse_rfc3339" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms_nano(9, 30, 0, 123000000).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  let rendered = @format.format_date_time_tz(dt, "%+")
  assert_eq(@format.parse_date_time_tz(rendered, "%+"), dt)
  assert_eq(
    @format.parse_date_time_tz(rendered, "%+"),
    @format.parse_rfc3339(rendered),
  )
}

///|
test "parsing %+ rejects malformed RFC 3339 text" {
  try @format.parse_date_time_tz("not-a-datetime", "%+") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected rejection for malformed %+ input")
  }
}

///|
test "parsing %+ cross-checks its fields against a redundantly-present specifier, accepting agreement and rejecting disagreement" {
  assert_eq(
    @format.parse_date_time("2024-03-05T09:30:00Z 2024", "%+ %Y"),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
  )
  try
    @format.parse_date_time("2024-03-05T09:30:00Z 2025", "%+ %Y") |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date_time to reject a %+/%Y disagreement")
  }
}

///|
test "parsing %+ reconstructs a leap second into the same second/nanosecond fields %S/%f would produce" {
  let via_plus = @format.parse_date_time("2024-03-05T09:30:60Z", "%+")
  let via_specifiers = @format.parse_date_time(
    "2024-03-05 09:30:60", "%Y-%m-%d %H:%M:%S",
  )
  assert_eq(via_plus, via_specifiers)
}

///|
test "parsing %s, %G, %g, and %V always raise InputMismatch, since parsing them is not yet supported" {
  for spec in ["%s", "%G", "%g", "%V"] {
    try @format.parse_date_time("anything", spec) |> ignore catch {
      @format.InputMismatch => ()
      _ => fail("expected InputMismatch for \{spec}")
    } noraise {
      _ => fail("expected parse_date_time to reject \{spec}")
    }
  }
}
