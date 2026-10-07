///|
fn builder_error_kind(f : () -> Unit raise @format.FormatError) -> String {
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
test "a new Parsed has no fields to resolve" {
  let empty = @format.Parsed::new()
  assert_eq(
    builder_error_kind(() => empty.to_date() |> ignore),
    "IncompleteFields",
  )
  assert_eq(
    builder_error_kind(() => empty.to_time() |> ignore),
    "IncompleteFields",
  )
  assert_eq(empty.utc_offset(), None)
  assert_eq(empty.zone_name(), None)
}

///|
test "a new Parsed equals one that parsed nothing" {
  assert_eq(@format.Parsed::new(), @format.parse_items("", []))
}

///|
test "year, month and day set one by one resolve to that date" {
  let parsed = @format.Parsed::new().set_year(2024).set_month(3).set_day(5)
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "a builder-made Parsed equals the one parsed from the same fields" {
  let built = @format.Parsed::new().set_year(2024).set_month(3).set_day(5)
  let parsed = @format.parse_items("2024-03-05", @format.tokenize("%F"))
  assert_eq(built, parsed)
}

///|
test "setting a field leaves the original Parsed unchanged" {
  let base = @format.Parsed::new().set_year(2024)
  let _ = base.set_month(3)
  assert_eq(base, @format.Parsed::new().set_year(2024))
}

///|
test "year and ordinal resolve to the day of that year" {
  let parsed = @format.Parsed::new().set_year(2024).set_ordinal(65)
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "century and two-digit year resolve to the full year" {
  let parsed = @format.Parsed::new()
    .set_year_div_100(20)
    .set_year_mod_100(24)
    .set_month(3)
    .set_day(5)
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "ISO week year, week and weekday resolve to that date" {
  let parsed = @format.Parsed::new()
    .set_iso_year(2024)
    .set_iso_week(10)
    .set_weekday(@core.Weekday::Tue)
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "ISO two-digit year, week and weekday resolve to that date" {
  let parsed = @format.Parsed::new()
    .set_iso_year_mod_100(24)
    .set_iso_week(10)
    .set_weekday(@core.Weekday::Tue)
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "Sunday-based week number and weekday resolve to that date" {
  let parsed = @format.Parsed::new()
    .set_year(2024)
    .set_week_from_sunday(9)
    .set_weekday(@core.Weekday::Tue)
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "Monday-based week number and weekday resolve to that date" {
  let parsed = @format.Parsed::new()
    .set_year(2024)
    .set_week_from_monday(10)
    .set_weekday(@core.Weekday::Tue)
  assert_eq(parsed.to_date(), @core.NaiveDate::from_ymd(2024, 3, 5).unwrap())
}

///|
test "a quarter that disagrees with the date is rejected" {
  let date_fields = @format.Parsed::new().set_year(2024).set_month(3).set_day(5)
  assert_eq(
    date_fields.set_quarter(1).to_date(),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
  assert_eq(
    builder_error_kind(() => date_fields.set_quarter(2).to_date() |> ignore),
    "InconsistentFields",
  )
}

///|
test "a weekday that disagrees with the date is rejected" {
  let parsed = @format.Parsed::new()
    .set_year(2024)
    .set_month(3)
    .set_day(5)
    .set_weekday(@core.Weekday::Wed)
  assert_eq(
    builder_error_kind(() => parsed.to_date() |> ignore),
    "InconsistentFields",
  )
}

///|
test "hour, minute, second and nanosecond resolve to that time" {
  let parsed = @format.Parsed::new()
    .set_hour(9)
    .set_minute(5)
    .set_second(3)
    .set_nanosecond(250_000_000)
  assert_eq(
    parsed.to_time(),
    @core.NaiveTime::from_hms_nano(9, 5, 3, 250_000_000).unwrap(),
  )
}

///|
test "a 12-hour clock reading with AM/PM resolves to the 24-hour time" {
  let pm = @format.Parsed::new().set_hour12(9).set_pm(true).set_minute(5)
  assert_eq(pm.to_time(), @core.NaiveTime::from_hms(21, 5, 0).unwrap())
  let noon = @format.Parsed::new().set_hour12(12).set_pm(true).set_minute(0)
  assert_eq(noon.to_time(), @core.NaiveTime::from_hms(12, 0, 0).unwrap())
  let midnight = @format.Parsed::new()
    .set_hour12(12)
    .set_pm(false)
    .set_minute(0)
  assert_eq(midnight.to_time(), @core.NaiveTime::from_hms(0, 0, 0).unwrap())
}

///|
test "a 24-hour reading that disagrees with the 12-hour reading is rejected" {
  let parsed = @format.Parsed::new()
    .set_hour(21)
    .set_hour12(8)
    .set_pm(true)
    .set_minute(0)
  assert_eq(
    builder_error_kind(() => parsed.to_time() |> ignore),
    "InconsistentFields",
  )
}

///|
test "an offset set on the builder is reported and used for resolution" {
  let parsed = @format.Parsed::new()
    .set_year(2024)
    .set_month(3)
    .set_day(5)
    .set_hour(9)
    .set_minute(0)
    .set_offset(32_400)
  assert_eq(parsed.utc_offset(), Some(32_400))
  let resolved = parsed.to_date_time_fixed_offset()
  assert_eq(resolved.offset().local_minus_utc(), 32_400)
  assert_eq(resolved.naive_local().hour(), 9)
}

///|
test "a timestamp resolves to the UTC instant it names" {
  let parsed = @format.Parsed::new().set_timestamp(1_709_629_503L).set_offset(0)
  assert_eq(
    parsed.to_date_time_fixed_offset().naive_utc(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(9, 5, 3).unwrap(),
    ),
  )
}

///|
test "a zone name set on the builder is reported as written" {
  let parsed = @format.Parsed::new().set_zone_name("JST")
  assert_eq(parsed.zone_name(), Some("JST"))
}

///|
test "setting a field again to the same value is accepted" {
  let parsed = @format.Parsed::new().set_month(3).set_month(3)
  assert_eq(parsed, @format.Parsed::new().set_month(3))
}

///|
test "setting a field again to a different value is rejected for every field" {
  let cases : Array[(String, () -> Unit raise @format.FormatError)] = [
    ("year", () => @format.Parsed::new().set_year(1).set_year(2) |> ignore),
    (
      "year_div_100",
      () => {
        @format.Parsed::new().set_year_div_100(1).set_year_div_100(2) |> ignore
      },
    ),
    (
      "year_mod_100",
      () => {
        @format.Parsed::new().set_year_mod_100(1).set_year_mod_100(2) |> ignore
      },
    ),
    (
      "iso_year",
      () => @format.Parsed::new().set_iso_year(1).set_iso_year(2) |> ignore,
    ),
    (
      "iso_year_mod_100",
      () => {
        @format.Parsed::new().set_iso_year_mod_100(1).set_iso_year_mod_100(2)
        |> ignore
      },
    ),
    (
      "iso_week",
      () => @format.Parsed::new().set_iso_week(1).set_iso_week(2) |> ignore,
    ),
    (
      "quarter",
      () => @format.Parsed::new().set_quarter(1).set_quarter(2) |> ignore,
    ),
    ("month", () => @format.Parsed::new().set_month(1).set_month(2) |> ignore),
    (
      "week_from_sunday",
      () => {
        @format.Parsed::new().set_week_from_sunday(1).set_week_from_sunday(2)
        |> ignore
      },
    ),
    (
      "week_from_monday",
      () => {
        @format.Parsed::new().set_week_from_monday(1).set_week_from_monday(2)
        |> ignore
      },
    ),
    (
      "weekday",
      () => {
        @format.Parsed::new()
        .set_weekday(@core.Weekday::Mon)
        .set_weekday(@core.Weekday::Tue)
        |> ignore
      },
    ),
    (
      "ordinal",
      () => @format.Parsed::new().set_ordinal(1).set_ordinal(2) |> ignore,
    ),
    ("day", () => @format.Parsed::new().set_day(1).set_day(2) |> ignore),
    ("pm", () => @format.Parsed::new().set_pm(true).set_pm(false) |> ignore),
    (
      "hour12",
      () => @format.Parsed::new().set_hour12(1).set_hour12(2) |> ignore,
    ),
    ("hour", () => @format.Parsed::new().set_hour(1).set_hour(2) |> ignore),
    (
      "minute",
      () => @format.Parsed::new().set_minute(1).set_minute(2) |> ignore,
    ),
    (
      "second",
      () => @format.Parsed::new().set_second(1).set_second(2) |> ignore,
    ),
    (
      "nanosecond",
      () => @format.Parsed::new().set_nanosecond(1).set_nanosecond(2) |> ignore,
    ),
    (
      "timestamp",
      () => @format.Parsed::new().set_timestamp(1L).set_timestamp(2L) |> ignore,
    ),
    (
      "offset",
      () => @format.Parsed::new().set_offset(1).set_offset(2) |> ignore,
    ),
    (
      "zone_name",
      () => {
        @format.Parsed::new().set_zone_name("A").set_zone_name("B") |> ignore
      },
    ),
  ]
  for case in cases {
    assert_eq(
      (case.0, builder_error_kind(case.1)),
      (case.0, "InconsistentFields"),
    )
  }
}

///|
test "a value outside a field's range is rejected" {
  let cases : Array[(String, () -> Unit raise @format.FormatError)] = [
    (
      "year_div_100 negative",
      () => @format.Parsed::new().set_year_div_100(-1) |> ignore,
    ),
    (
      "year_mod_100 100",
      () => @format.Parsed::new().set_year_mod_100(100) |> ignore,
    ),
    (
      "year_mod_100 negative",
      () => @format.Parsed::new().set_year_mod_100(-1) |> ignore,
    ),
    (
      "iso_year_mod_100 100",
      () => @format.Parsed::new().set_iso_year_mod_100(100) |> ignore,
    ),
    (
      "iso_year_mod_100 negative",
      () => @format.Parsed::new().set_iso_year_mod_100(-1) |> ignore,
    ),
    ("iso_week 0", () => @format.Parsed::new().set_iso_week(0) |> ignore),
    ("iso_week 54", () => @format.Parsed::new().set_iso_week(54) |> ignore),
    ("quarter 0", () => @format.Parsed::new().set_quarter(0) |> ignore),
    ("quarter 5", () => @format.Parsed::new().set_quarter(5) |> ignore),
    ("month 0", () => @format.Parsed::new().set_month(0) |> ignore),
    ("month 13", () => @format.Parsed::new().set_month(13) |> ignore),
    (
      "week_from_sunday negative",
      () => @format.Parsed::new().set_week_from_sunday(-1) |> ignore,
    ),
    (
      "week_from_sunday 54",
      () => @format.Parsed::new().set_week_from_sunday(54) |> ignore,
    ),
    (
      "week_from_monday negative",
      () => @format.Parsed::new().set_week_from_monday(-1) |> ignore,
    ),
    (
      "week_from_monday 54",
      () => @format.Parsed::new().set_week_from_monday(54) |> ignore,
    ),
    ("ordinal 0", () => @format.Parsed::new().set_ordinal(0) |> ignore),
    ("ordinal 367", () => @format.Parsed::new().set_ordinal(367) |> ignore),
    ("day 0", () => @format.Parsed::new().set_day(0) |> ignore),
    ("day 32", () => @format.Parsed::new().set_day(32) |> ignore),
    (
      "offset beyond 23:59:59",
      () => @format.Parsed::new().set_offset(86_400) |> ignore,
    ),
    (
      "offset before -23:59:59",
      () => @format.Parsed::new().set_offset(-86_400) |> ignore,
    ),
    ("hour12 0", () => @format.Parsed::new().set_hour12(0) |> ignore),
    ("hour12 13", () => @format.Parsed::new().set_hour12(13) |> ignore),
    ("hour negative", () => @format.Parsed::new().set_hour(-1) |> ignore),
    ("hour 24", () => @format.Parsed::new().set_hour(24) |> ignore),
    ("minute negative", () => @format.Parsed::new().set_minute(-1) |> ignore),
    ("minute 60", () => @format.Parsed::new().set_minute(60) |> ignore),
    ("second negative", () => @format.Parsed::new().set_second(-1) |> ignore),
    ("second 61", () => @format.Parsed::new().set_second(61) |> ignore),
    (
      "nanosecond negative",
      () => @format.Parsed::new().set_nanosecond(-1) |> ignore,
    ),
    (
      "nanosecond 1e9",
      () => @format.Parsed::new().set_nanosecond(1_000_000_000) |> ignore,
    ),
  ]
  for case in cases {
    assert_eq((case.0, builder_error_kind(case.1)), (case.0, "FieldOutOfRange"))
  }
}

///|
test "values at the edge of each field's range are accepted" {
  let edges = @format.Parsed::new()
    .set_year_div_100(0)
    .set_year_mod_100(99)
    .set_iso_year_mod_100(0)
    .set_iso_week(53)
    .set_quarter(4)
    .set_month(12)
    .set_week_from_sunday(0)
    .set_week_from_monday(53)
    .set_ordinal(366)
    .set_day(31)
    .set_hour12(12)
    .set_hour(23)
    .set_minute(59)
    .set_second(60)
    .set_nanosecond(999_999_999)
    .set_offset(-86_399)
  assert_eq(edges.utc_offset(), Some(-86_399))
  assert_eq(@format.Parsed::new().set_offset(86_399).utc_offset(), Some(86_399))
}

///|
test "a negative century is rejected while a negative year is accepted" {
  assert_eq(
    builder_error_kind(() => {
      @format.Parsed::new().set_year_div_100(-1) |> ignore
    }),
    "FieldOutOfRange",
  )
  assert_eq(
    @format.Parsed::new().set_year(-7).set_month(1).set_day(1).to_date(),
    @core.NaiveDate::from_ymd(-7, 1, 1).unwrap(),
  )
}
