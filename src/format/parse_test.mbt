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
    @format.TrailingInput => ()
    _ => fail("expected TrailingInput")
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
    @format.FieldOutOfRange => ()
    _ => fail("expected FieldOutOfRange")
  } noraise {
    _ => fail("expected parse_date to reject Feb 30")
  }
}

///|
test "parse_date rejects an out-of-range ordinal for the given year" {
  try @format.parse_date("2023-366", "%Y-%j") |> ignore catch {
    @format.FieldOutOfRange => ()
    _ => fail("expected FieldOutOfRange")
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
    @format.InputTooShort => ()
    _ => fail("expected InputTooShort")
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
    @format.FieldOutOfRange => ()
    _ => fail("expected FieldOutOfRange")
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
      @format.InputMismatch | @format.InputTooShort => ()
      _ => fail("expected InputMismatch or InputTooShort for \{bad}")
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
    @format.FieldOutOfRange => ()
    _ => fail("expected FieldOutOfRange")
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
test "parse_date_time_tz round-trips %:z, %::z, and %:::z, including a non-whole-minute offset for %::z" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  let east = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  for fmt in ["%F %T%:z", "%F %T%::z", "%F %T%:::z"] {
    assert_eq(
      @format.parse_date_time_tz(@format.format_date_time_tz(east, fmt), fmt),
      east,
    )
  }
  let sub_minute = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600 + 30 * 60 + 15).unwrap(),
  )
  let fmt = "%F %T%::z"
  assert_eq(
    @format.parse_date_time_tz(
      @format.format_date_time_tz(sub_minute, fmt),
      fmt,
    ),
    sub_minute,
  )
}

///|
test "parsing %:z, %::z, and %:::z rejects input that doesn't exactly match their own rendered shape (no lenient colon/space tolerance)" {
  for
    case in [
      ("%:z", "2024-03-05 09:30:00+0900"), // no colon
      ("%::z", "2024-03-05 09:30:00+09:00"), // missing seconds
      ("%:::z", "2024-03-05 09:30:00+09:00"), // has a colon/minutes, %:::z wants hours only
    ] {
    let (fmt, bad) = case
    try @format.parse_date_time_tz(bad, "%F %T" + fmt) |> ignore catch {
      @format.InputMismatch | @format.TrailingInput => ()
      _ => fail("expected InputMismatch or TrailingInput for \{fmt}")
    } noraise {
      _ => fail("expected rejection for \{fmt}")
    }
  }
}

///|
test "parse_date_time_tz round-trips %#z across every shape it accepts: no colon, colon, hours only, and Z" {
  // The input's date/time is the local (wall-clock) reading; the UTC
  // instant is that reading minus the offset.
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(
    @format.parse_date_time_tz("2024-03-05 09:30:00+0900", "%F %T%#z"),
    @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        date,
        @core.NaiveTime::from_hms(0, 30, 0).unwrap(),
      ),
      @tz.FixedOffset::east(9 * 3600).unwrap(),
    ),
  )
  assert_eq(
    @format.parse_date_time_tz("2024-03-05 09:30:00+09:00", "%F %T%#z"),
    @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        date,
        @core.NaiveTime::from_hms(0, 30, 0).unwrap(),
      ),
      @tz.FixedOffset::east(9 * 3600).unwrap(),
    ),
  )
  assert_eq(
    @format.parse_date_time_tz("2024-03-05 09:30:00+09", "%F %T%#z"),
    @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        date,
        @core.NaiveTime::from_hms(0, 30, 0).unwrap(),
      ),
      @tz.FixedOffset::east(9 * 3600).unwrap(),
    ),
  )
  assert_eq(
    @format.parse_date_time_tz("2024-03-05 09:30:00Z", "%F %T%#z"),
    @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        date,
        @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
      ),
      @tz.FixedOffset::east(0).unwrap(),
    ),
  )
  assert_eq(
    @format.parse_date_time_tz("2024-03-05 09:30:00-05:30", "%F %T%#z"),
    @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        date,
        @core.NaiveTime::from_hms(15, 0, 0).unwrap(),
      ),
      @tz.FixedOffset::west(5 * 3600 + 30 * 60).unwrap(),
    ),
  )
}

///|
test "parsing %#z rejects malformed input" {
  for
    bad in [
      "2024-03-05 09:30:00", // absent entirely
       "2024-03-05 09:30:00+9", // only 1 digit hour
       "2024-03-05 09:30:00+09:99", // out-of-range minute
    ] {
    try @format.parse_date_time_tz(bad, "%F %T%#z") |> ignore catch {
      @format.InputMismatch | @format.InputTooShort => ()
      _ => fail("expected InputMismatch or InputTooShort for \{bad}")
    } noraise {
      _ => fail("expected rejection for \{bad}")
    }
  }
}

///|
test "parsing %:z, %::z, %:::z, and %#z rejects malformed input at every failure point" {
  for
    case in [
      // %:z (parse_offset_colon)
      ("%:z", ""),
      ("%:z", "X"),
      ("%:z", "+XX:00"),
      ("%:z", "+09:XX"),
      ("%:z", "+09:99"),
      // %::z (parse_offset_double_colon)
      ("%::z", ""),
      ("%::z", "X"),
      ("%::z", "+XX:00:00"),
      ("%::z", "+0900:00"),
      ("%::z", "+09:XX:00"),
      ("%::z", "+09:99:00"),
      ("%::z", "+09:00:XX"),
      ("%::z", "+09:00:99"),
      // %:::z (parse_offset_triple_colon)
      ("%:::z", ""),
      ("%:::z", "X"),
      ("%:::z", "+XX"),
      // %#z (parse_offset_permissive)
      ("%#z", "X0900"),
    ] {
    let (fmt, bad_offset) = case
    try
      @format.parse_date_time_tz(
        "2024-03-05 09:30:00" + bad_offset,
        "%F %T" + fmt,
      )
      |> ignore
    catch {
      @format.InputMismatch | @format.InputTooShort => ()
      _ =>
        fail(
          "expected InputMismatch or InputTooShort for \{fmt} / \{bad_offset}",
        )
    } noraise {
      _ => fail("expected rejection for \{fmt} / \{bad_offset}")
    }
  }
}

///|
test "parsing %:z/%::z/%:::z/%#z cross-checks against a redundantly-present %z, accepting agreement and rejecting disagreement" {
  assert_eq(
    @format.parse_date_time_tz("2024-03-05 09:30:00+09:00+0900", "%F %T%:z%z"),
    @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
        @core.NaiveTime::from_hms(0, 30, 0).unwrap(),
      ),
      @tz.FixedOffset::east(9 * 3600).unwrap(),
    ),
  )
  try
    @format.parse_date_time_tz("2024-03-05 09:30:00+09:00+0800", "%F %T%:z%z")
    |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_date_time_tz to reject a %:z/%z disagreement")
  }
}

///|
test "parsing %Z consumes and discards a run of non-whitespace characters, whatever its shape" {
  let expected = local_reading(2024, 3, 5, 9, 30)
  for name in ["UTC", "JST", "EDT", "CEST", "+09:00", "XXXXXXXX"] {
    let parsed = @format.parse_date_time(
      "2024-03-05 09:30:00 \{name}",
      "%F %T %Z",
    )
    assert_eq(
      parsed,
      @core.NaiveDateTime::new(
        expected.date(),
        @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
      ),
    )
  }
}

///|
test "parsing %Z stops at whitespace so a following specifier still applies" {
  let dt = @format.parse_date_time_tz(
    "2024-03-05 09:30:00 CEST +0100", "%F %T %Z %z",
  )
  assert_eq(dt.offset(), @tz.FixedOffset::east(3600).unwrap())
  assert_eq(dt.naive_local(), local_reading(2024, 3, 5, 9, 30))
}

///|
test "parsing %Z rejects an empty zone name" {
  for input in ["2024-03-05 09:30:00 ", "2024-03-05 09:30:00"] {
    try @format.parse_date_time(input, "%F %T %Z") |> ignore catch {
      @format.InputTooShort => ()
      _ => fail("expected InputTooShort for \{input}")
    } noraise {
      _ => fail("expected rejection for \{input}")
    }
  }
}

///|
test "a datetime formatted with %Z parses back for every kind of zone name" {
  let utc = @tz.DateTime::from_timestamp(1_709_631_000L, 0, @tz.Utc::new()).unwrap()
  let tokyo = utc.with_timezone(@tz.FixedOffset::east(9 * 3600).unwrap())
  let ny = utc.with_timezone(@tz.Location::load("America/New_York").unwrap())
  assert_eq(
    @format.parse_date_time(
      @format.format_date_time_tz(utc, "%F %T %Z"),
      "%F %T %Z",
    ),
    utc.naive_local(),
  )
  assert_eq(
    @format.parse_date_time(
      @format.format_date_time_tz(tokyo, "%F %T %Z"),
      "%F %T %Z",
    ),
    tokyo.naive_local(),
  )
  assert_eq(
    @format.parse_date_time(
      @format.format_date_time_tz(ny, "%F %T %Z"),
      "%F %T %Z",
    ),
    ny.naive_local(),
  )
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
    @format.FieldOutOfRange => ()
    _ => fail("expected FieldOutOfRange")
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
    @format.FieldOutOfRange => ()
    _ => fail("expected FieldOutOfRange")
  } noraise {
    _ => fail("expected rejection for an out-of-range %w value")
  }
  try @format.parse_date("2024-03-05 0", "%Y-%m-%d %u") |> ignore catch {
    @format.FieldOutOfRange => ()
    _ => fail("expected FieldOutOfRange")
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
    @format.FieldOutOfRange => ()
    _ => fail("expected FieldOutOfRange")
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
test "parse_time round-trips %.f across zero, trimmed, and full-precision fractions" {
  for nanos in [0, 500000000, 120000000, 123456000, 123456789] {
    let time = @core.NaiveTime::from_hms_nano(9, 30, 0, nanos).unwrap()
    let fmt = "%H:%M:%S%.f"
    assert_eq(@format.parse_time(@format.format_time(time, fmt), fmt), time)
  }
}

///|
test "parse_time succeeds when %.f has nothing to consume (no dot in the input)" {
  assert_eq(
    @format.parse_time("09:30:00", "%H:%M:%S%.f"),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
}

///|
test "parsing %.f rejects a dot with no digits following it" {
  try @format.parse_time("09:30:00.", "%H:%M:%S%.f") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected rejection for a dot with no digits")
  }
}

///|
test "parse_time round-trips %3f, %6f, and %9f, all mandatory and fixed-width (each truncated to its own precision)" {
  let time = @core.NaiveTime::from_hms_nano(9, 30, 0, 123456789).unwrap()
  for
    case in [
      ("%H:%M:%S.%3f", 123000000),
      ("%H:%M:%S.%6f", 123456000),
      ("%H:%M:%S.%9f", 123456789),
    ] {
    let (fmt, expected_nanos) = case
    assert_eq(
      @format.parse_time(@format.format_time(time, fmt), fmt),
      @core.NaiveTime::from_hms_nano(9, 30, 0, expected_nanos).unwrap(),
    )
  }
}

///|
test "parse_time rejects %3f, %6f, and %9f when too few digits are present" {
  for case in [("%3f", "12"), ("%6f", "12345"), ("%9f", "12345678")] {
    let (fmt, bad) = case
    try
      @format.parse_time("09:30:00." + bad, "%H:%M:%S." + fmt) |> ignore
    catch {
      @format.InputMismatch => ()
      _ => fail("expected InputMismatch for \{fmt}")
    } noraise {
      _ => fail("expected rejection for \{fmt}")
    }
  }
}

///|
test "parsing %.f cross-checks against a redundantly-present %f, accepting agreement and rejecting disagreement" {
  assert_eq(
    @format.parse_time("09:30:00.5 500000000", "%H:%M:%S%.f %f"),
    @core.NaiveTime::from_hms_nano(9, 30, 0, 500000000).unwrap(),
  )
  try
    @format.parse_time("09:30:00.5 600000000", "%H:%M:%S%.f %f") |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_time to reject a %.f/%f disagreement")
  }
}

///|
test "parse_date round-trips %-Y through format_date, parsing identically to plain %Y regardless of the padding flag" {
  let date = @core.NaiveDate::from_ymd(24, 3, 5).unwrap()
  let fmt = "%-Y-%m-%d"
  assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
}

///|
test "parse_date parses %0e and %_d identically to plain %e/%d, ignoring the padding flag entirely" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.parse_date("2024-03-05", "%Y-%m-%0e"), date)
  assert_eq(@format.parse_date("2024-03-05", "%Y-%m-%_d"), date)
  assert_eq(@format.parse_date("2024-03- 5", "%Y-%m-%0e"), date)
}

///|
test "parsing %s always raises InputMismatch, since parsing it is not yet supported" {
  try @format.parse_date_time("anything", "%s") |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch for %s")
  } noraise {
    _ => fail("expected parse_date_time to reject %s")
  }
}

///|
test "parse_date round-trips ISO week dates through %G, %V and %u, including across a calendar-year boundary" {
  let fmt = "%G-W%V-%u"
  for ymd in [(2024, 3, 5), (2021, 1, 1), (2018, 12, 31), (2020, 12, 31)] {
    let (y, m, d) = ymd
    let date = @core.NaiveDate::from_ymd(y, m, d).unwrap()
    assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
  }
}

///|
test "parse_date reads an ISO week date whose weekday is given by name" {
  assert_eq(
    @format.parse_date("2024 10 Tuesday", "%G %V %A"),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
}

///|
test "parse_date interprets %g via the conventional pivot: below 70 is 20xx, at or above 70 is 19xx" {
  for iso_year in [2069, 1970, 2024, 1999] {
    let date = @core.NaiveDate::from_isoywd(iso_year, 1, @core.Weekday::Mon).unwrap()
    assert_eq(
      @format.parse_date(@format.format_date(date, "%g-%V-%u"), "%g-%V-%u"),
      date,
    )
  }
}

///|
test "parse_date accepts %G and %g together when they agree" {
  assert_eq(
    @format.parse_date("2024 24 10 2", "%G %g %V %u"),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
}

///|
test "parse_date accepts ISO week fields alongside a matching calendar date" {
  assert_eq(
    @format.parse_date("2024-03-05 2024 10", "%Y-%m-%d %G %V"),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
}

///|
test "parse_date accepts %V cross-checked against %Y and %W when no ISO year is given" {
  assert_eq(
    @format.parse_date("2024 10 10 2", "%Y %V %W %u"),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
}

///|
test "parse_date rejects non-numeric text where %G, %g or %V is expected" {
  for spec in ["%G", "%g", "%V"] {
    try @format.parse_date("XX", spec) |> ignore catch {
      @format.InputMismatch => ()
      _ => fail("expected InputMismatch for \{spec}")
    } noraise {
      _ => fail("expected parse_date to reject \{spec}")
    }
  }
}

///|
test "parse_date rejects ISO week fields that disagree with each other or with the calendar date" {
  let cases = [
    ("2024 25 10 2", "%G %g %V %u"),
    ("-100 00 01 1", "%G %g %V %u"),
    ("2025 2024 10 2", "%Y %G %V %u"),
    ("2024-03-05 2024 11", "%Y-%m-%d %G %V"),
    ("2024-03-05 2023 10", "%Y-%m-%d %G %V"),
    ("2024 11 10 2", "%Y %V %W %u"),
  ]
  for c in cases {
    let (input, fmt) = c
    try @format.parse_date(input, fmt) |> ignore catch {
      @format.InconsistentFields => ()
      _ => fail("expected InconsistentFields for \{input}")
    } noraise {
      _ => fail("expected parse_date to reject \{input}")
    }
  }
}

///|
test "parse_date rejects an ISO week number that does not exist in its ISO year" {
  for input in ["2024 53 2", "2024 00 2", "2024 54 2"] {
    try @format.parse_date(input, "%G %V %u") |> ignore catch {
      @format.FieldOutOfRange => ()
      _ => fail("expected FieldOutOfRange for \{input}")
    } noraise {
      _ => fail("expected parse_date to reject \{input}")
    }
  }
}

///|
test "parse_date reports IncompleteFields when ISO week fields lack a year, a week or a weekday" {
  let cases = [
    ("10 2", "%V %u"),
    ("2024 10", "%G %V"),
    ("2024 2", "%G %u"),
    ("2024 10 2", "%Y %V %u"),
  ]
  for c in cases {
    let (input, fmt) = c
    try @format.parse_date(input, fmt) |> ignore catch {
      @format.IncompleteFields => ()
      _ => fail("expected IncompleteFields for \{input}")
    } noraise {
      _ => fail("expected parse_date to reject \{input}")
    }
  }
}

///|
fn local_reading(
  y : Int,
  mo : Int,
  d : Int,
  h : Int,
  mi : Int,
) -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(y, mo, d).unwrap(),
    @core.NaiveTime::from_hms(h, mi, 0).unwrap(),
  )
}

///|
test "parse_date_time_in reads a zone-less layout as wall-clock time in a fixed-offset zone" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = @format.parse_date_time_in("2024-03-05 09:30:00", "%F %T", tokyo)
    .single()
    .unwrap()
  assert_eq(dt.naive_local(), local_reading(2024, 3, 5, 9, 30))
  assert_eq(dt.naive_utc(), local_reading(2024, 3, 5, 0, 30))
  assert_eq(dt.timezone(), tokyo)
}

///|
test "parse_date_time_in resolves the local reading through a Location's offset at that time (America/New_York)" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  let summer = @format.parse_date_time_in("2024-07-01 12:00:00", "%F %T", ny)
    .single()
    .unwrap()
  let winter = @format.parse_date_time_in("2024-01-01 12:00:00", "%F %T", ny)
    .single()
    .unwrap()
  assert_eq(summer.offset(), @tz.FixedOffset::east(-4 * 3600).unwrap())
  assert_eq(winter.offset(), @tz.FixedOffset::east(-5 * 3600).unwrap())
}

///|
test "parse_date_time_in surfaces a spring-forward gap as Absent and a fall-back fold as Ambiguous (America/New_York)" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  assert_true(
    @format.parse_date_time_in("2024-03-10 02:30:00", "%F %T", ny) is @tz.Absent,
  )
  let fold = @format.parse_date_time_in("2024-11-03 01:30:00", "%F %T", ny)
  assert_eq(
    fold.earliest().unwrap().compare_instant(fold.latest().unwrap()),
    -1,
  )
}

///|
test "parse_date_time_in rejects a layout that carries an offset" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  for
    case in [
      ("2024-03-05 09:30:00+0900", "%F %T%z"),
      ("2024-03-05T09:30:00Z 2024", "%+ %Y"),
    ] {
    let (input, fmt) = case
    try @format.parse_date_time_in(input, fmt, tokyo) |> ignore catch {
      @format.InconsistentFields => ()
      _ => fail("expected InconsistentFields for \{fmt}")
    } noraise {
      _ => fail("expected rejection for \{fmt}")
    }
  }
}

///|
test "parse_date_time_in propagates a parse failure and an incomplete layout" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  try @format.parse_date_time_in("garbage", "%F %T", tokyo) |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected rejection")
  }
  try @format.parse_date_time_in("2024-03-05", "%F", tokyo) |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected rejection")
  }
}

///|
test "parse_date_time_in resolves a fall-back fold by the zone abbreviation in the input (America/New_York)" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  let edt = @format.parse_date_time_in(
      "2024-11-03 01:30:00 EDT", "%F %T %Z", ny,
    )
    .single()
    .unwrap()
  let est = @format.parse_date_time_in(
      "2024-11-03 01:30:00 EST", "%F %T %Z", ny,
    )
    .single()
    .unwrap()
  assert_eq(edt.offset(), @tz.FixedOffset::east(-4 * 3600).unwrap())
  assert_eq(est.offset(), @tz.FixedOffset::east(-5 * 3600).unwrap())
  assert_eq(edt.naive_utc(), local_reading(2024, 11, 3, 5, 30))
  assert_eq(est.naive_utc(), local_reading(2024, 11, 3, 6, 30))
  assert_true(edt.timezone() == ny)
}

///|
test "parse_date_time_in trusts the abbreviation's offset over the wall clock, keeping the instant as written" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  let dt = @format.parse_date_time_in("2024-07-01 12:00:00 EST", "%F %T %Z", ny)
    .single()
    .unwrap()
  assert_eq(dt.naive_utc(), local_reading(2024, 7, 1, 17, 0))
  assert_eq(dt.naive_local(), local_reading(2024, 7, 1, 13, 0))
}

///|
test "parse_date_time_in falls back to ordinary local resolution for an abbreviation the zone does not know" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  assert_true(
    @format.parse_date_time_in("2024-03-10 02:30:00 XXX", "%F %T %Z", ny)
    is @tz.Absent,
  )
  let fold = @format.parse_date_time_in(
    "2024-11-03 01:30:00 XXX", "%F %T %Z", ny,
  )
  assert_eq(
    fold.earliest().unwrap().compare_instant(fold.latest().unwrap()),
    -1,
  )
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let named = @format.parse_date_time_in(
      "2024-03-05 09:30:00 JST", "%F %T %Z", tokyo,
    )
    .single()
    .unwrap()
  assert_eq(named.naive_local(), local_reading(2024, 3, 5, 9, 30))
}

///|
test "parse_date_time_in resolves a POSIX rule's own abbreviations" {
  let rule = @tz.parse_posix_tz("FOO5BAR4,M3.2.0,M11.1.0").unwrap()
  let dt = @format.parse_date_time_in(
      "2024-03-10 02:30:00 BAR", "%F %T %Z", rule,
    )
    .single()
    .unwrap()
  assert_eq(dt.naive_utc(), local_reading(2024, 3, 10, 6, 30))
}

///|
test "parsing repeated %Z accepts the same name and rejects differing names" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  assert_true(
    @format.parse_date_time_in("2024-07-01 12:00:00 EDT EDT", "%F %T %Z %Z", ny).single()
    is Some(_),
  )
  try
    @format.parse_date_time_in("2024-07-01 12:00:00 EDT EST", "%F %T %Z %Z", ny)
    |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected rejection")
  }
}

///|
test "parse_date_time_in round-trips a FixedZone's name through %Z" {
  let zone = @tz.FixedZone::new("JST", @tz.FixedOffset::east(9 * 3600).unwrap())
  let dt = @format.parse_date_time_in(
      "2024-06-15 21:00:00 JST", "%F %T %Z", zone,
    )
    .single()
    .unwrap()
  assert_eq(dt.naive_utc().time().hour(), 12)
  assert_eq(dt.timezone(), zone)
}

///|
test "parse_time reads %k as a space- or zero-padded 24-hour field" {
  let expected = @core.NaiveTime::from_hms(9, 5, 7).unwrap()
  assert_eq(@format.parse_time(" 9:05:07", "%k:%M:%S"), expected)
  assert_eq(@format.parse_time("09:05:07", "%k:%M:%S"), expected)
  assert_eq(
    @format.parse_time("23:05:07", "%k:%M:%S"),
    @core.NaiveTime::from_hms(23, 5, 7).unwrap(),
  )
}

///|
test "parse_time round-trips %k through format_time for every hour" {
  for hour in 0..<24 {
    let time = @core.NaiveTime::from_hms(hour, 30, 15).unwrap()
    let fmt = "%k:%M:%S"
    assert_eq(@format.parse_time(@format.format_time(time, fmt), fmt), time)
  }
}

///|
test "parse_time rejects an out-of-range or non-numeric %k field" {
  for input in ["24:00:00", "XX:00:00", " :00:00", "9:00:00"] {
    try @format.parse_time(input, "%k:%M:%S") |> ignore catch {
      @format.InputMismatch | @format.FieldOutOfRange => ()
      _ => fail("expected a rejection for \{input}")
    } noraise {
      _ => fail("expected parse_time to reject \{input}")
    }
  }
}

///|
test "parse_time reads %k alongside %H only when they agree" {
  assert_eq(
    @format.parse_time(" 9 09:05:07", "%k %H:%M:%S"),
    @core.NaiveTime::from_hms(9, 5, 7).unwrap(),
  )
  try @format.parse_time(" 9 10:05:07", "%k %H:%M:%S") |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected parse_time to reject a disagreeing hour")
  }
}

///|
test "parse_time matches %n and %t only against a single newline and tab" {
  let expected = @core.NaiveTime::from_hms(9, 5, 7).unwrap()
  assert_eq(@format.parse_time("09\t05\n07", "%H%t%M%n%S"), expected)
  for input in ["09 05\n07", "09\t05 07", "09\t\t05\n07", "09\t05\n\n07"] {
    try @format.parse_time(input, "%H%t%M%n%S") |> ignore catch {
      @format.InputMismatch => ()
      _ => fail("expected InputMismatch for \{input}")
    } noraise {
      _ => fail("expected parse_time to reject \{input}")
    }
  }
}

///|
test "parse_date_and_remainder returns the parsed date and the unparsed tail" {
  let (date, rest) = @format.parse_date_and_remainder(
    "2024-03-05 and more", "%Y-%m-%d",
  )
  assert_eq(date, @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
  assert_eq(rest, " and more")
}

///|
test "each _and_remainder parser returns an empty tail when the whole input matches" {
  let (date, date_rest) = @format.parse_date_and_remainder("2024-03-05", "%F")
  assert_eq(date, @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
  assert_eq(date_rest, "")
  let (time, time_rest) = @format.parse_time_and_remainder("09:05:07", "%T")
  assert_eq(time, @core.NaiveTime::from_hms(9, 5, 7).unwrap())
  assert_eq(time_rest, "")
}

///|
test "parse_time_and_remainder stops after the format and keeps the rest verbatim" {
  let (time, rest) = @format.parse_time_and_remainder("09:05:07Z tail", "%T")
  assert_eq(time, @core.NaiveTime::from_hms(9, 5, 7).unwrap())
  assert_eq(rest, "Z tail")
}

///|
test "parse_date_time_and_remainder resolves both halves and returns the tail" {
  let (dt, rest) = @format.parse_date_time_and_remainder(
    "2024-03-05 09:05:07;next", "%F %T",
  )
  assert_eq(
    dt,
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 5, 7).unwrap(),
    ),
  )
  assert_eq(rest, ";next")
}

///|
test "parse_date_time_tz_and_remainder applies the parsed offset and returns the tail" {
  let (dt, rest) = @format.parse_date_time_tz_and_remainder(
    "2024-03-05 18:30:00 +0900 rest", "%F %T %z",
  )
  assert_eq(dt.naive_utc().time(), @core.NaiveTime::from_hms(9, 30, 0).unwrap())
  assert_eq(dt.offset(), @tz.FixedOffset::east(9 * 3600).unwrap())
  assert_eq(rest, " rest")
}

///|
test "parse_date_time_in_and_remainder resolves in the zone and returns the tail" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let (mapped, rest) = @format.parse_date_time_in_and_remainder(
    "2024-03-05 18:30:00 rest", "%F %T", tokyo,
  )
  assert_eq(
    mapped.unwrap().naive_utc().time(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  assert_eq(rest, " rest")
}

///|
test "the tail counts characters, not bytes, so a multibyte remainder stays intact" {
  let (date, rest) = @format.parse_date_and_remainder(
    "2024-03-05日本語", "%F",
  )
  assert_eq(date, @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
  assert_eq(rest, "日本語")
}

///|
test "_and_remainder parsers still reject input that fails inside the format" {
  try
    @format.parse_date_and_remainder("2024-XX-05 rest", "%F") |> ignore
  catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected a mismatch inside the format to be rejected")
  }
}

///|
test "_and_remainder parsers still reject incomplete or inconsistent fields in the consumed part" {
  try @format.parse_date_and_remainder("09 rest", "%H") |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected a missing date to be rejected")
  }
}

///|
test "the strict parsers still reject any trailing input" {
  try @format.parse_date("2024-03-05 rest", "%F") |> ignore catch {
    @format.TrailingInput => ()
    _ => fail("expected TrailingInput")
  } noraise {
    _ => fail("expected trailing input to be rejected")
  }
}

///|
test "parsing %Z rejects a zone name that begins with whitespace" {
  try
    @format.parse_date_time("2024-03-05 09:30:00  UTC", "%F %T %Z") |> ignore
  catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected a whitespace-led zone name to be rejected")
  }
}
