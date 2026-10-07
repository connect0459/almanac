///|
fn lenient_expected(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  minute : Int,
  second : Int,
  offset_hours : Int,
) -> @tz.DateTime[@tz.FixedOffset] {
  let offset = @tz.FixedOffset::east(offset_hours * 3600).unwrap()
  let local_reading = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(year, month, day).unwrap(),
    @core.NaiveTime::from_hms(hour, minute, second).unwrap(),
  )
  @tz.DateTime::from_utc(
    local_reading.sub_seconds((offset_hours * 3600).to_int64()),
    offset,
  )
}

///|
fn assert_lenient_reads(
  input : String,
  expected : @tz.DateTime[@tz.FixedOffset],
) -> Unit raise {
  assert_eq(@format.parse_rfc2822_lenient(input), expected)
}

///|
fn assert_lenient_rejects(input : String) -> Unit raise {
  try @format.parse_rfc2822_lenient(input) |> ignore catch {
    @format.InvalidRfc2822 => ()
    _ => fail("expected InvalidRfc2822 for \{input}")
  } noraise {
    _ => fail("expected rejection for \{input}")
  }
}

///|
test "parse_rfc2822_lenient reads back what to_rfc2822 renders" {
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
    assert_eq(@format.parse_rfc2822_lenient(@format.to_rfc2822(dt)), dt)
  }
}

///|
test "parse_rfc2822_lenient reads a conforming date the way the strict parser does" {
  for
    input in [
      "Tue, 20 Jan 2015 17:35:20 -0800", "Wed, 18 Feb 2015 23:16:09 +0000", "Tue, 1 Jul 2003 10:52:37 +0200",
      "Tue, 01 Jul 2003 10:52:37 +0200",
    ] {
    assert_eq(
      @format.parse_rfc2822_lenient(input),
      @format.parse_rfc2822(input),
    )
  }
}

///|
test "parse_rfc2822_lenient rejects a day of week that disagrees with the date, which the strict parser ignores" {
  let input = "Mon, 20 Jan 2015 17:35:20 -0800"
  @format.parse_rfc2822(input) |> ignore
  assert_lenient_rejects(input)
}

///|
test "parse_rfc2822_lenient rejects a long day name, which the strict parser reads" {
  let input = "Tuesday, 20 Jan 2015 17:35:20 -0800"
  @format.parse_rfc2822(input) |> ignore
  assert_lenient_rejects(input)
}

///|
test "parse_rfc2822_lenient accepts leading whitespace but not trailing whitespace" {
  let expected = lenient_expected(2015, 1, 20, 17, 35, 20, -8)
  assert_lenient_reads(" \t\r\n Tue, 20 Jan 2015 17:35:20 -0800", expected)
  assert_lenient_reads("  20 Jan 2015 17:35:20 -0800", expected)
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 -0800 ")
}

///|
test "parse_rfc2822_lenient treats the day of week as optional" {
  assert_lenient_reads(
    "20 Jan 2015 17:35:20 -0800",
    lenient_expected(2015, 1, 20, 17, 35, 20, -8),
  )
}

///|
test "parse_rfc2822_lenient rejects a day of week that is not followed by a comma" {
  assert_lenient_rejects("Tue 20 Jan 2015 17:35:20 -0800")
}

///|
test "parse_rfc2822_lenient treats the seconds as optional" {
  assert_lenient_reads(
    "Tue, 20 Jan 2015 17:35 -0800",
    lenient_expected(2015, 1, 20, 17, 35, 0, -8),
  )
}

///|
test "parse_rfc2822_lenient accepts folding whitespace between fields" {
  let expected = lenient_expected(2015, 1, 2, 17, 35, 20, -8)
  assert_lenient_reads("Fri,  2 Jan 2015 17:35:20 -0800", expected)
  assert_lenient_reads(
    "  Fri, 2   Jan\t2015 \r\n 17 : 35 : 20 \t-0800", expected,
  )
}

///|
test "parse_rfc2822_lenient requires whitespace between the date and time fields" {
  assert_lenient_rejects("Tue, 20Jan 2015 17:35:20 -0800")
  assert_lenient_rejects("Tue, 20 Jan2015 17:35:20 -0800")
  assert_lenient_rejects("Tue, 20 Jan 201517:35:20 -0800")
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20-0800")
}

///|
test "parse_rfc2822_lenient matches month and weekday names case-insensitively" {
  let expected = lenient_expected(2015, 1, 20, 17, 35, 20, -8)
  assert_lenient_reads("20 JAN 2015 17:35:20 -0800", expected)
  assert_lenient_reads("TUE, 20 jan 2015 17:35:20 -0800", expected)
}

///|
test "parse_rfc2822_lenient reads a two-digit year below 50 as 20xx" {
  assert_lenient_reads(
    "1 Jul 05 10:52:37 +0000",
    lenient_expected(2005, 7, 1, 10, 52, 37, 0),
  )
  assert_lenient_reads(
    "1 Jul 49 10:52:37 +0000",
    lenient_expected(2049, 7, 1, 10, 52, 37, 0),
  )
}

///|
test "parse_rfc2822_lenient reads a two-digit year from 50 as 19xx" {
  assert_lenient_reads(
    "1 Jul 50 10:52:37 +0000",
    lenient_expected(1950, 7, 1, 10, 52, 37, 0),
  )
  assert_lenient_reads(
    "1 Jul 79 10:52:37 +0000",
    lenient_expected(1979, 7, 1, 10, 52, 37, 0),
  )
}

///|
test "parse_rfc2822_lenient reads a three-digit year as 1900 plus the year" {
  assert_lenient_reads(
    "1 Jul 112 10:52:37 +0000",
    lenient_expected(2012, 7, 1, 10, 52, 37, 0),
  )
  assert_lenient_reads(
    "1 Jul 009 10:52:37 +0000",
    lenient_expected(1909, 7, 1, 10, 52, 37, 0),
  )
}

///|
test "parse_rfc2822_lenient leaves a four-digit year unwindowed" {
  assert_lenient_reads(
    "1 Jul 0654 10:52:37 +0000",
    lenient_expected(654, 7, 1, 10, 52, 37, 0),
  )
}

///|
test "parse_rfc2822_lenient rejects a one-digit year and a year of more than four digits" {
  assert_lenient_rejects("1 Jul 5 10:52:37 +0000")
  assert_lenient_rejects("1 Jul 12345 10:52:37 +0000")
}

///|
test "parse_rfc2822_lenient reads the legacy North American zone names" {
  for
    case in [
      ("GMT", 0),
      ("UT", 0),
      ("EDT", -4),
      ("EST", -5),
      ("CDT", -5),
      ("CST", -6),
      ("MDT", -6),
      ("MST", -7),
      ("PDT", -7),
      ("PST", -8),
    ] {
    let (name, hours) = case
    assert_lenient_reads(
      "Tue, 20 Jan 2015 17:35:20 \{name}",
      lenient_expected(2015, 1, 20, 17, 35, 20, hours),
    )
  }
}

///|
test "parse_rfc2822_lenient matches legacy zone names case-insensitively" {
  assert_lenient_reads(
    "Tue, 20 Jan 2015 17:35:20 ut",
    lenient_expected(2015, 1, 20, 17, 35, 20, 0),
  )
  assert_lenient_reads(
    "Tue, 20 Jan 2015 17:35:20 pst",
    lenient_expected(2015, 1, 20, 17, 35, 20, -8),
  )
}

///|
test "parse_rfc2822_lenient reads a single-letter military zone as UTC, as RFC 2822 recommends" {
  for zone in ["Z", "A", "a", "K", "k", "Y", "I", "M", "N"] {
    assert_lenient_reads(
      "Tue, 20 Jan 2015 17:35:20 \{zone}",
      lenient_expected(2015, 1, 20, 17, 35, 20, 0),
    )
  }
}

///|
test "parse_rfc2822_lenient rejects the unused military zone J and other unknown zone names" {
  for zone in ["J", "Zulu", "ZULU", "HAS", "EET", "CEST"] {
    assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 \{zone}")
  }
}

///|
test "parse_rfc2822_lenient rejects an offset without a sign or with minutes above 59" {
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 0800")
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 -0890")
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 −0800")
}

///|
test "parse_rfc2822_lenient ignores a trailing comment" {
  let expected = lenient_expected(2015, 1, 20, 17, 35, 20, -8)
  assert_lenient_reads("Tue, 20 Jan 2015 17:35:20 -0800 (UTC)", expected)
  assert_lenient_reads("Tue, 20 Jan 2015 17:35:20 -0800(UTC)", expected)
}

///|
test "parse_rfc2822_lenient ignores nested and escaped comments" {
  assert_lenient_reads(
    "Tue, 20 Jan 2015 17:35:20 -0800 ( (UTC ) (\\( (a)\\(( \t ) ) \\\\( \\) ))",
    lenient_expected(2015, 1, 20, 17, 35, 20, -8),
  )
}

///|
test "parse_rfc2822_lenient ignores several trailing comments separated by whitespace" {
  assert_lenient_reads(
    "Tue, 20 Jan 2015 17:35:20 -0800 (UTC)\t \r\n(Another comment)",
    lenient_expected(2015, 1, 20, 17, 35, 20, -8),
  )
}

///|
test "parse_rfc2822_lenient rejects an unterminated comment and trailing text" {
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 -0800 (UTC\\)")
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 -0800 (UTC")
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 -0800 (UTC) ")
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 -0800 ")
  assert_lenient_rejects("Tue, 20 Jan 2015 17:35:20 -0800 extra")
}

///|
test "parse_rfc2822_lenient rejects malformed fields" {
  for
    bad in [
      "", "Tue, 20 Jan 2015", "Tue, 20 Avr 2015 17:35:20 -0800", "Tue, 20 Jan 2015 7:35:20 -0800",
      "Tue, 20 Jan 2015 17:5:20 -0800", "Tue, 20 Jan 2015 17.35:20 -0800", "Tue, 20 Jan 2015😈17:35:20 -0800",
      "6 Jun 1944 04:00:00Z",
    ] {
    assert_lenient_rejects(bad)
  }
}

///|
test "parse_rfc2822_lenient rejects fields that are out of range" {
  for
    bad in [
      "30 Feb 2015 17:35:20 -0800", "20 Jan 2015 25:35:20 -0800", "20 Jan 2015 17:65:20 -0800",
      "20 Jan 2015 17:35:90 -0800", "20 Jan 2015 17:35:20 +9900",
    ] {
    assert_lenient_rejects(bad)
  }
}
