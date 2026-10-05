///|
fn http_utc(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  minute : Int,
  second : Int,
) -> @tz.DateTime[@tz.Utc] {
  @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(year, month, day).unwrap(),
      @core.NaiveTime::from_hms(hour, minute, second).unwrap(),
    ),
    @tz.Utc::new(),
  )
}

///|
fn assert_invalid_http_date(
  input : String,
  reference_year? : Int,
) -> Unit raise {
  try @format.parse_http_date(input, reference_year?) |> ignore catch {
    @format.InvalidHttpDate => ()
    _ => fail("expected InvalidHttpDate for \{input}")
  } noraise {
    _ => fail("expected InvalidHttpDate for \{input}")
  }
}

///|
test "to_http_date writes IMF-fixdate with a zero-padded day and a GMT zone" {
  assert_eq(
    @format.to_http_date(http_utc(1994, 11, 6, 8, 49, 37)),
    "Sun, 06 Nov 1994 08:49:37 GMT",
  )
}

///|
test "to_http_date renders the UTC instant of a zoned value" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(23, 30, 0).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.to_http_date(dt), "Tue, 05 Mar 2024 23:30:00 GMT")
  assert_eq(
    @format.to_http_date(dt.with_timezone(@tz.Utc::new())),
    "Tue, 05 Mar 2024 23:30:00 GMT",
  )
}

///|
test "to_http_date drops a fractional second" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms_nano(9, 5, 7, 999_000_000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@format.to_http_date(dt), "Tue, 05 Mar 2024 09:05:07 GMT")
}

///|
test "to_http_date renders a leap second as :60" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2016, 12, 31).unwrap(),
      @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@format.to_http_date(dt), "Sat, 31 Dec 2016 23:59:60 GMT")
}

///|
test "to_http_date raises InvalidHttpDate for a year outside 0..=9999" {
  try @format.to_http_date(http_utc(-1, 1, 1, 0, 0, 0)) |> ignore catch {
    @format.InvalidHttpDate => ()
    _ => fail("expected InvalidHttpDate")
  } noraise {
    _ => fail("expected InvalidHttpDate")
  }
  try @format.to_http_date(http_utc(10000, 1, 1, 0, 0, 0)) |> ignore catch {
    @format.InvalidHttpDate => ()
    _ => fail("expected InvalidHttpDate")
  } noraise {
    _ => fail("expected InvalidHttpDate")
  }
}

///|
test "parse_http_date reads IMF-fixdate as a UTC instant" {
  assert_eq(
    @format.parse_http_date("Sun, 06 Nov 1994 08:49:37 GMT"),
    http_utc(1994, 11, 6, 8, 49, 37),
  )
}

///|
test "parse_http_date reads the obsolete RFC 850 form" {
  assert_eq(
    @format.parse_http_date("Sunday, 06-Nov-94 08:49:37 GMT"),
    http_utc(1994, 11, 6, 8, 49, 37),
  )
}

///|
test "parse_http_date reads the obsolete asctime form with a space-padded day" {
  assert_eq(
    @format.parse_http_date("Sun Nov  6 08:49:37 1994"),
    http_utc(1994, 11, 6, 8, 49, 37),
  )
  assert_eq(
    @format.parse_http_date("Tue Mar 12 09:05:07 2024"),
    http_utc(2024, 3, 12, 9, 5, 7),
  )
}

///|
test "parse_http_date inverts to_http_date" {
  let dt = http_utc(2024, 2, 29, 23, 59, 59)
  assert_eq(@format.parse_http_date(@format.to_http_date(dt)), dt)
}

///|
test "parse_http_date reads a two-digit year with the fixed pivot when no reference year is given" {
  assert_eq(
    @format.parse_http_date("Sunday, 06-Nov-94 08:49:37 GMT"),
    http_utc(1994, 11, 6, 8, 49, 37),
  )
  assert_eq(
    @format.parse_http_date("Tuesday, 05-Mar-24 09:05:07 GMT"),
    http_utc(2024, 3, 5, 9, 5, 7),
  )
}

///|
test "parse_http_date reads a two-digit year in the reference year's century when it is at most 50 years ahead" {
  assert_eq(
    @format.parse_http_date(
      "Tuesday, 05-Mar-24 09:05:07 GMT",
      reference_year=2090,
    ),
    http_utc(2024, 3, 5, 9, 5, 7),
  )
  assert_eq(
    @format.parse_http_date(
      "Monday, 05-Mar-40 09:05:07 GMT",
      reference_year=2090,
    ),
    http_utc(2040, 3, 5, 9, 5, 7),
  )
}

///|
test "parse_http_date reads a two-digit year more than 50 years ahead as the latest past year" {
  assert_eq(
    @format.parse_http_date(
      "Wednesday, 05-Mar-80 09:05:07 GMT",
      reference_year=2000,
    ),
    http_utc(1980, 3, 5, 9, 5, 7),
  )
  assert_eq(
    @format.parse_http_date(
      "Saturday, 05-Mar-50 09:05:07 GMT",
      reference_year=2000,
    ),
    http_utc(2050, 3, 5, 9, 5, 7),
  )
  assert_eq(
    @format.parse_http_date(
      "Monday, 05-Mar-51 09:05:07 GMT",
      reference_year=2000,
    ),
    http_utc(1951, 3, 5, 9, 5, 7),
  )
}

///|
test "parse_http_date ignores the reference year for a four-digit year" {
  assert_eq(
    @format.parse_http_date(
      "Sun, 06 Nov 1994 08:49:37 GMT",
      reference_year=2090,
    ),
    http_utc(1994, 11, 6, 8, 49, 37),
  )
}

///|
test "parse_http_date rejects a zone other than GMT" {
  assert_invalid_http_date("Sun, 06 Nov 1994 08:49:37 UTC")
  assert_invalid_http_date("Sun, 06 Nov 1994 08:49:37 +0000")
  assert_invalid_http_date("Sunday, 06-Nov-94 08:49:37 UTC")
}

///|
test "parse_http_date rejects a weekday that does not match the date" {
  assert_invalid_http_date("Mon, 06 Nov 1994 08:49:37 GMT")
  assert_invalid_http_date("Monday, 06-Nov-94 08:49:37 GMT")
  assert_invalid_http_date("Mon Nov  6 08:49:37 1994")
}

///|
test "parse_http_date rejects a date or time that does not exist" {
  assert_invalid_http_date("Thu, 30 Feb 2023 08:49:37 GMT")
  assert_invalid_http_date("Sun, 06 Nov 1994 24:00:00 GMT")
  assert_invalid_http_date("Sun, 06 Nov 1994 08:60:00 GMT")
}

///|
test "parse_http_date rejects text that is not one of the three shapes" {
  assert_invalid_http_date("")
  assert_invalid_http_date("Sun, 6 Nov 1994 08:49:37 GMT")
  assert_invalid_http_date("Sun, 06 Nov 94 08:49:37 GMT")
  assert_invalid_http_date("Sunday, 06 Nov 1994 08:49:37 GMT")
  assert_invalid_http_date("Sun, 06-Nov-94 08:49:37 GMT")
  assert_invalid_http_date("Sunday, 06-Nov-94 08:49:37 GMT ")
  assert_invalid_http_date("Sun, 06 Nov 1994 08:49:37 GMT extra")
  assert_invalid_http_date("Sun Nov 6 08:49:37 1994")
  assert_invalid_http_date("Sun Nov  6 08:49:37 94")
  assert_invalid_http_date("Sun Nov  x 08:49:37 1994")
  assert_invalid_http_date("Sun Nov  6 08:49:37 1994 ")
  assert_invalid_http_date("sun, 06 nov 1994 08:49:37 gmt")
  assert_invalid_http_date("2024-03-05T09:05:07Z")
}

///|
test "parse_http_date does not read a leap second back" {
  assert_invalid_http_date("Sat, 31 Dec 2016 23:59:60 GMT")
}
