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
