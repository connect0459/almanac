///|
fn error_kind(f : () -> Unit raise @format.FormatError) -> String {
  try f() catch {
    @format.FieldOutOfRange => "FieldOutOfRange"
    @format.InconsistentFields => "InconsistentFields"
    @format.IncompleteFields => "IncompleteFields"
    _ => "other"
  } noraise {
    _ => "ok"
  }
}

///|
fn stamp_parsed(text : String) -> @format.Parsed raise @format.FormatError {
  @format.parse_items(text, @format.tokenize(@format.STAMP))
}

///|
fn naive_dt(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  minute : Int,
  second : Int,
) -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(year, month, day).unwrap(),
    @core.NaiveTime::from_hms(hour, minute, second).unwrap(),
  )
}

///|
test "a layout without a year cannot be resolved unless a default year is supplied" {
  let parsed = stamp_parsed("Mar  5 09:05:03")
  assert_eq(error_kind(() => parsed.to_date() |> ignore), "IncompleteFields")
  assert_eq(
    error_kind(() => parsed.to_date_time() |> ignore),
    "IncompleteFields",
  )
}

///|
test "a default year completes a syslog STAMP reading" {
  let parsed = stamp_parsed("Mar  5 09:05:03").with_default_year(2024)
  assert_eq(parsed.to_date_time(), naive_dt(2024, 3, 5, 9, 5, 3))
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "supplying a default year leaves the original reading unresolvable" {
  let parsed = stamp_parsed("Mar  5 09:05:03")
  let _ = parsed.with_default_year(2024)
  assert_eq(error_kind(() => parsed.to_date() |> ignore), "IncompleteFields")
}

///|
test "a default year completes the fractional STAMP layouts" {
  let parsed = @format.parse_items(
    "Dec 31 23:59:59.123",
    @format.tokenize(@format.STAMP_MILLI),
  ).with_default_year(2023)
  let dt = parsed.to_date_time()
  assert_eq(dt.date(), @core.NaiveDate::from_ymd(2023, 12, 31).unwrap())
  assert_eq(dt.timestamp_subsec_millis(), 123)
}

///|
test "a year written in the text takes precedence over the default year" {
  let four_digit = @format.parse_items(
    "1999-03-05",
    @format.tokenize("%Y-%m-%d"),
  ).with_default_year(2024)
  assert_eq(
    four_digit.to_date(),
    @core.NaiveDate::from_ymd(1999, 3, 5).unwrap(),
  )
  let two_digit = @format.parse_items("99-03-05", @format.tokenize("%y-%m-%d")).with_default_year(
    2024,
  )
  assert_eq(two_digit.to_date(), @core.NaiveDate::from_ymd(1999, 3, 5).unwrap())
  let century = @format.parse_items(
    "19 99-03-05",
    @format.tokenize("%C %y-%m-%d"),
  ).with_default_year(2024)
  assert_eq(century.to_date(), @core.NaiveDate::from_ymd(1999, 3, 5).unwrap())
}

///|
test "a leap day resolves only when the default year is a leap year" {
  let leap = stamp_parsed("Feb 29 00:00:00").with_default_year(2024)
  assert_eq(leap.to_date(), @core.NaiveDate::from_ymd(2024, 2, 29).unwrap())
  let common = stamp_parsed("Feb 29 00:00:00").with_default_year(2023)
  assert_eq(error_kind(() => common.to_date() |> ignore), "FieldOutOfRange")
}

///|
test "a weekday in the text is checked against the default year" {
  let items = @format.tokenize("%a %b %e")
  let matching = @format.parse_items("Tue Mar  5", items).with_default_year(
    2024,
  )
  assert_eq(matching.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
  let mismatching = @format.parse_items("Mon Mar  5", items).with_default_year(
    2024,
  )
  assert_eq(
    error_kind(() => mismatching.to_date() |> ignore),
    "InconsistentFields",
  )
}

///|
test "a default year places a day of the year" {
  let parsed = @format.parse_items("060", @format.tokenize("%j")).with_default_year(
    2024,
  )
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 2, 29).unwrap())
}

///|
test "a default year places a week number and weekday" {
  let parsed = @format.parse_items("09 Tue", @format.tokenize("%U %a")).with_default_year(
    2024,
  )
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "an ISO week date keeps its own year when a default year is supplied" {
  let parsed = @format.parse_items("2020-W53-5", @format.tokenize("%G-W%V-%u")).with_default_year(
    2024,
  )
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2021, 1, 1).unwrap())
}

///|
test "a Unix timestamp keeps its own instant when a default year is supplied" {
  let parsed = @format.parse_items("0", @format.tokenize("%s")).with_default_year(
    2024,
  )
  assert_eq(parsed.to_date_time(), naive_dt(1970, 1, 1, 0, 0, 0))
}

///|
test "a default year completes the zone-aware resolvers" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let zoneless = stamp_parsed("Mar  5 09:05:03").with_default_year(2024)
  assert_eq(
    zoneless.to_date_time_in(tokyo).unwrap().naive_local(),
    naive_dt(2024, 3, 5, 9, 5, 3),
  )
  let offset = @format.parse_items(
    "Mar  5 09:05:03 +0900",
    @format.tokenize("%b %e %H:%M:%S %z"),
  ).with_default_year(2024)
  assert_eq(
    offset.to_date_time_fixed_offset().naive_local(),
    naive_dt(2024, 3, 5, 9, 5, 3),
  )
  assert_eq(offset.to_date_time_fixed_offset().offset(), tokyo)
}

///|
test "a century alone is not completed by a default year" {
  let parsed = @format.parse_items("19-03-05", @format.tokenize("%C-%m-%d")).with_default_year(
    2024,
  )
  assert_eq(error_kind(() => parsed.to_date() |> ignore), "IncompleteFields")
}

///|
test "a two-digit ISO week year keeps its own year when a default year is supplied" {
  let parsed = @format.parse_items("20-W53-5", @format.tokenize("%g-W%V-%u")).with_default_year(
    2024,
  )
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2021, 1, 1).unwrap())
}

///|
test "a default year is not read as an ISO week year" {
  let parsed = @format.parse_items("W10-2", @format.tokenize("W%V-%u")).with_default_year(
    2024,
  )
  assert_eq(error_kind(() => parsed.to_date() |> ignore), "IncompleteFields")
}
