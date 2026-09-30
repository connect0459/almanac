///|
test "parse_date_default reads back every date's Show rendering" {
  for year in [-10000, -1, 0, 1, 2024, 9999, 10000, 123456] {
    let date = @core.NaiveDate::from_ymd(year, 3, 5).unwrap()
    assert_eq(@format.parse_date_default(date.to_string()), date)
  }
}

///|
test "parse_time_default reads back every time's Show rendering, fractions and leap second included" {
  for nanos in [0, 500_000_000, 123_456_000, 789, 1_500_000_000] {
    let time = @core.NaiveTime::from_hms_nano(23, 59, 59, nanos).unwrap()
    assert_eq(@format.parse_time_default(time.to_string()), time)
  }
  let midnight = @core.NaiveTime::midnight()
  assert_eq(@format.parse_time_default(midnight.to_string()), midnight)
}

///|
test "parse_date_time_default reads back every date-time's Show rendering" {
  for
    dt in [
      @core.NaiveDateTime::unix_epoch(),
      @core.NaiveDateTime::new(
        @core.NaiveDate::from_ymd(10000, 12, 31).unwrap(),
        @core.NaiveTime::from_hms_nano(23, 59, 59, 999_000_000).unwrap(),
      ),
      @core.NaiveDateTime::new(
        @core.NaiveDate::from_ymd(-1, 1, 1).unwrap(),
        @core.NaiveTime::from_hms_nano(0, 0, 0, 123_456_789).unwrap(),
      ),
    ] {
    assert_eq(@format.parse_date_time_default(dt.to_string()), dt)
  }
}

///|
test "parse_date_time_utc_default reads back a UTC DateTime's Show rendering" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms_nano(12, 30, 0, 500_000_000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(dt.to_string(), "2024-06-15 12:30:00.500 UTC")
  assert_eq(@format.parse_date_time_utc_default(dt.to_string()), dt)
}

///|
test "parse_date_time_fixed_offset_default reads back a fixed-offset DateTime's Show rendering, for east, west, zero and sub-minute offsets" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms_nano(12, 30, 0, 123_000_000).unwrap(),
  )
  for secs in [9 * 3600, -(5 * 3600 + 30 * 60), 0, 9 * 3600 + 30, -86399] {
    let offset = @tz.FixedOffset::east(secs).unwrap()
    let dt = @tz.DateTime::from_utc(naive, offset)
    assert_eq(@format.parse_date_time_fixed_offset_default(dt.to_string()), dt)
  }
}

///|
test "parse_date_time_fixed_offset_default treats the written clock as local time in the written offset" {
  let dt = @format.parse_date_time_fixed_offset_default(
    "2024-06-15 21:00:00 +09:00",
  )
  assert_eq(dt.offset(), @tz.FixedOffset::east(9 * 3600).unwrap())
  assert_eq(dt.naive_utc().time(), @core.NaiveTime::from_hms(12, 0, 0).unwrap())
}

///|
fn default_layout_kind(f : () -> Unit raise @format.ParseError) -> String {
  try f() catch {
    @format.InputTooShort => "InputTooShort"
    @format.TrailingInput => "TrailingInput"
    @format.InputMismatch => "InputMismatch"
    @format.FieldOutOfRange => "FieldOutOfRange"
    @format.IncompleteFields => "IncompleteFields"
    _ => "other"
  } noraise {
    _ => "ok"
  }
}

///|
test "the default-layout parsers reject text that is not the Show layout" {
  assert_eq(
    default_layout_kind(() => @format.parse_date_default("2024-3-5") |> ignore),
    "InputMismatch",
  )
  assert_eq(
    default_layout_kind(() => @format.parse_time_default("9:05:07") |> ignore),
    "InputMismatch",
  )
  assert_eq(
    default_layout_kind(() => {
      @format.parse_date_time_default("2024-03-05T09:05:07") |> ignore
    }),
    "InputMismatch",
  )
  assert_eq(
    default_layout_kind(() => {
      @format.parse_date_time_utc_default("2024-03-05 09:05:07") |> ignore
    }),
    "InputTooShort",
  )
  assert_eq(
    default_layout_kind(() => {
      @format.parse_date_time_utc_default("2024-03-05 09:05:07 +00:00")
      |> ignore
    }),
    "InputMismatch",
  )
}

///|
test "the default-layout parsers reject trailing text and out-of-range fields" {
  assert_eq(
    default_layout_kind(() => {
      @format.parse_date_default("2024-03-05 x") |> ignore
    }),
    "TrailingInput",
  )
  assert_eq(
    default_layout_kind(() => {
      @format.parse_time_default("09:05:07.5 x") |> ignore
    }),
    "TrailingInput",
  )
  assert_eq(
    default_layout_kind(() => @format.parse_date_default("2024-02-30") |> ignore),
    "FieldOutOfRange",
  )
  assert_eq(
    default_layout_kind(() => @format.parse_time_default("24:00:00") |> ignore),
    "FieldOutOfRange",
  )
}

///|
test "parse_date_time_fixed_offset_default rejects a missing or malformed offset" {
  assert_eq(
    default_layout_kind(() => {
      @format.parse_date_time_fixed_offset_default("2024-03-05 09:05:07")
      |> ignore
    }),
    "InputTooShort",
  )
  assert_eq(
    default_layout_kind(() => {
      @format.parse_date_time_fixed_offset_default("2024-03-05 09:05:07 UTC")
      |> ignore
    }),
    "InputMismatch",
  )
  assert_eq(
    default_layout_kind(() => {
      @format.parse_date_time_fixed_offset_default("2024-03-05 09:05:07 +24:00")
      |> ignore
    }),
    "FieldOutOfRange",
  )
}
