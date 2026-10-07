///|
test "to_rfc2822 renders a datetime, shifted to local wall-clock time, with an unpadded day" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2003, 7, 1).unwrap(),
      @core.NaiveTime::from_hms(8, 52, 37).unwrap(),
    ),
    @tz.FixedOffset::east(2 * 3600).unwrap(),
  )
  assert_eq(@format.to_rfc2822(dt), "Tue, 1 Jul 2003 10:52:37 +0200")
}

///|
test "to_rfc2822 zero-pads a two-digit day" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2015, 2, 18).unwrap(),
      @core.NaiveTime::from_hms(23, 16, 9).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@format.to_rfc2822(dt), "Wed, 18 Feb 2015 23:16:09 +0000")
}

///|
test "to_rfc2822 renders a negative offset" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
    ),
    @tz.FixedOffset::west(5 * 3600).unwrap(),
  )
  assert_eq(@format.to_rfc2822(dt), "Tue, 5 Mar 2024 04:30:00 -0500")
}

///|
test "to_rfc2822 renders a leap second as :60, matching NaiveTime's leap-second convention" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2016, 12, 31).unwrap(),
      @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@format.to_rfc2822(dt), "Sat, 31 Dec 2016 23:59:60 +0000")
}

///|
test "to_rfc2822 raises InvalidRfc2822 for a year outside RFC 2822's 0..=9999 range" {
  let out_of_range = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(-1, 1, 1).unwrap(),
      @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  try @format.to_rfc2822(out_of_range) |> ignore catch {
    @format.InvalidRfc2822 => ()
    _ => fail("expected InvalidRfc2822")
  } noraise {
    _ => fail("expected to_rfc2822 to reject a negative year")
  }
  let too_large = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(10000, 1, 1).unwrap(),
      @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  try @format.to_rfc2822(too_large) |> ignore catch {
    @format.InvalidRfc2822 => ()
    _ => fail("expected InvalidRfc2822")
  } noraise {
    _ => fail("expected to_rfc2822 to reject a year past 9999")
  }
}

///|
test "parse_rfc2822 round-trips through to_rfc2822" {
  for
    case in [
      (2003, 7, 1, 8, 52, 37, 2 * 3600),
      (2015, 2, 18, 23, 16, 9, 0),
      (2024, 3, 5, 9, 30, 0, -5 * 3600),
      (1999, 12, 31, 23, 59, 59, 9 * 3600),
    ] {
    let (year, month, day, hour, minute, second, offset_secs) = case
    let dt = @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        @core.NaiveDate::from_ymd(year, month, day).unwrap(),
        @core.NaiveTime::from_hms(hour, minute, second).unwrap(),
      ),
      @tz.FixedOffset::east(offset_secs).unwrap(),
    )
    assert_eq(@format.parse_rfc2822(@format.to_rfc2822(dt)), dt)
  }
}

///|
test "parse_rfc2822 accepts a documented RFC 2822 example verbatim" {
  assert_eq(
    @format.parse_rfc2822("Wed, 18 Feb 2015 23:16:09 +0000"),
    @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(
        @core.NaiveDate::from_ymd(2015, 2, 18).unwrap(),
        @core.NaiveTime::from_hms(23, 16, 9).unwrap(),
      ),
      @tz.FixedOffset::east(0).unwrap(),
    ),
  )
}

///|
test "parse_rfc2822 accepts either a one- or two-digit day" {
  // The input's "10:52:37 +0200" is the local reading; the UTC instant
  // is that reading minus the offset.
  let expected = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2003, 7, 1).unwrap(),
      @core.NaiveTime::from_hms(8, 52, 37).unwrap(),
    ),
    @tz.FixedOffset::east(2 * 3600).unwrap(),
  )
  assert_eq(@format.parse_rfc2822("Tue, 1 Jul 2003 10:52:37 +0200"), expected)
  assert_eq(@format.parse_rfc2822("Tue, 01 Jul 2003 10:52:37 +0200"), expected)
}

///|
test "parse_rfc2822 rejects malformed input at every field, since this project's parser is strict (with no tolerance for RFC 2822's obsolete format)" {
  for
    bad in [
      "1 Jul 2003 10:52:37 +0200", // missing weekday
       "Tue 1 Jul 2003 10:52:37 +0200", // missing comma
       "Tue,1 Jul 2003 10:52:37 +0200", // missing space after comma
       "Tue,  1 Jul 2003 10:52:37 +0200", // extra space (not flexible whitespace)
       "Tue, XX Jul 2003 10:52:37 +0200", // non-digit day
       "Tue, 1 Ju 2003 10:52:37 +0200", // truncated month name
       "Tue, 1 Jul 03 10:52:37 +0200", // 2-digit obsolete year, unsupported
       "Tue, 1 Jul 2003 1:52:37 +0200", // hour not 2 digits
       "Tue, 1 Jul 2003 10.52:37 +0200", // wrong hour/minute separator
       "Tue, 1 Jul 2003 10:52 +0200", // missing (mandatory) seconds
       "Tue, 1 Jul 2003 10:52:37 GMT", // named zone, unsupported
       "Tue, 1 Jul 2003 10:52:37 Z", // military/Zulu zone, unsupported
       "Tue, 1 Jul 2003 10:52:37+0200", // missing space before offset
       "Tue, 1 Jul 2003 10:52:37 +0200 (CEST)", // trailing comment, unsupported
       "Tue, 1 Jul 2003 10:52:37 +9900", // offset magnitude out of range
       "", // empty
    ] {
    try @format.parse_rfc2822(bad) |> ignore catch {
      @format.InvalidRfc2822 => ()
      _ => fail("expected InvalidRfc2822 for \{bad}")
    } noraise {
      _ => fail("expected rejection for \{bad}")
    }
  }
}

///|
test "parse_rfc2822 rejects a day of week that disagrees with the date" {
  for
    bad in ["Mon, 20 Jan 2015 17:35:20 -0800", "Wed, 1 Jul 2003 10:52:37 +0200"] {
    try @format.parse_rfc2822(bad) |> ignore catch {
      @format.InvalidRfc2822 => ()
      _ => fail("expected InvalidRfc2822 for \{bad}")
    } noraise {
      _ => fail("expected rejection for \{bad}")
    }
  }
}

///|
test "parse_rfc2822 accepts a day of week that agrees with the date" {
  let dt = @format.parse_rfc2822("Tue, 20 Jan 2015 17:35:20 -0800")
  assert_eq(@format.to_rfc2822(dt), "Tue, 20 Jan 2015 17:35:20 -0800")
}

///|
test "parse_rfc2822 rejects a long day name, since RFC 2822 day-name has short names only" {
  try
    @format.parse_rfc2822("Tuesday, 20 Jan 2015 17:35:20 -0800") |> ignore
  catch {
    @format.InvalidRfc2822 => ()
    _ => fail("expected InvalidRfc2822")
  } noraise {
    _ => fail("expected rejection of a long day name")
  }
}

///|
test "parse_rfc2822 rejects a long month name, since RFC 2822 month-name has short names only" {
  try
    @format.parse_rfc2822("Tue, 20 January 2015 17:35:20 -0800") |> ignore
  catch {
    @format.InvalidRfc2822 => ()
    _ => fail("expected InvalidRfc2822")
  } noraise {
    _ => fail("expected rejection of a long month name")
  }
}

///|
test "parse_rfc2822 matches day and month names case-sensitively" {
  for
    bad in [
      "tue, 20 Jan 2015 17:35:20 -0800", "TUE, 20 Jan 2015 17:35:20 -0800", "Tue, 20 jan 2015 17:35:20 -0800",
      "Tue, 20 JAN 2015 17:35:20 -0800",
    ] {
    try @format.parse_rfc2822(bad) |> ignore catch {
      @format.InvalidRfc2822 => ()
      _ => fail("expected InvalidRfc2822 for \{bad}")
    } noraise {
      _ => fail("expected rejection for \{bad}")
    }
  }
}
