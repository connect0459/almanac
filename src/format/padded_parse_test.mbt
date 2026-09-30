///|
fn padded_kind(f : () -> Unit raise @format.ParseError) -> String {
  try f() catch {
    @format.InputTooShort => "InputTooShort"
    @format.TrailingInput => "TrailingInput"
    @format.InputMismatch => "InputMismatch"
    @format.FieldOutOfRange => "FieldOutOfRange"
    @format.InconsistentFields => "InconsistentFields"
    @format.IncompleteFields => "IncompleteFields"
    _ => "other"
  } noraise {
    _ => "ok"
  }
}

///|
fn march_fifth_padded() -> @core.NaiveDate {
  @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
}

///|
test "a no-padding flag makes a numeric field read one or two digits" {
  assert_eq(@format.parse_date("2024-03-5", "%Y-%m-%-d"), march_fifth_padded())
  assert_eq(@format.parse_date("2024-03-05", "%Y-%m-%-d"), march_fifth_padded())
  assert_eq(@format.parse_date("2024-3-5", "%Y-%-m-%-d"), march_fifth_padded())
  assert_eq(
    @format.parse_date("2024-3-15", "%Y-%-m-%-d"),
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
  )
}

///|
test "a no-padding flag reads the time fields and the ordinal without leading zeros" {
  assert_eq(
    @format.parse_time("9:5:7", "%-H:%-M:%-S"),
    @core.NaiveTime::from_hms(9, 5, 7).unwrap(),
  )
  assert_eq(
    @format.parse_time("9:05:00 AM", "%-I:%M:%S %p"),
    @core.NaiveTime::from_hms(9, 5, 0).unwrap(),
  )
  assert_eq(
    @format.parse_date("2024-65", "%Y-%-j"),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
  assert_eq(
    @format.parse_date("2024-5", "%Y-%-j"),
    @core.NaiveDate::from_ymd(2024, 1, 5).unwrap(),
  )
}

///|
test "a no-padding flag on a blank-padded specifier reads an unpadded value" {
  assert_eq(@format.parse_date("2024-03-5", "%Y-%m-%-e"), march_fifth_padded())
  assert_eq(
    @format.parse_time("9:05:07", "%-k:%M:%S"),
    @core.NaiveTime::from_hms(9, 5, 7).unwrap(),
  )
  assert_eq(
    @format.parse_time("9:05:00 PM", "%-l:%M:%S %p"),
    @core.NaiveTime::from_hms(21, 5, 0).unwrap(),
  )
}

///|
test "a no-padding field is greedy up to its width, so adjacent fields split by position" {
  assert_eq(
    @format.parse_time("09:123", "%H:%-M%-S"),
    @core.NaiveTime::from_hms(9, 12, 3).unwrap(),
  )
  assert_eq(
    padded_kind(() => @format.parse_time("905:00", "%-H%-M:%S") |> ignore),
    "FieldOutOfRange",
  )
}

///|
test "a no-padding field still needs at least one digit and stops at two" {
  assert_eq(
    padded_kind(() => @format.parse_date("2024-03-", "%Y-%m-%-d") |> ignore),
    "InputTooShort",
  )
  assert_eq(
    padded_kind(() => @format.parse_date("2024-03-x", "%Y-%m-%-d") |> ignore),
    "InputMismatch",
  )
  assert_eq(
    padded_kind(() => @format.parse_date("2024-03-123", "%Y-%m-%-d") |> ignore),
    "TrailingInput",
  )
}

///|
test "a space-padding flag reads a blank-or-zero padded field" {
  assert_eq(@format.parse_date("2024-03- 5", "%Y-%m-%_d"), march_fifth_padded())
  assert_eq(@format.parse_date("2024-03-05", "%Y-%m-%_d"), march_fifth_padded())
  assert_eq(
    @format.parse_date("2024- 3- 5", "%Y-%_m-%_d"),
    march_fifth_padded(),
  )
  assert_eq(
    @format.parse_time(" 9: 5: 7", "%_H:%_M:%_S"),
    @core.NaiveTime::from_hms(9, 5, 7).unwrap(),
  )
}

///|
test "a space-padding flag on a one-digit field reads it as plain digits" {
  assert_eq(
    @format.parse_date("2024-03-05 2", "%Y-%m-%d %_u"),
    march_fifth_padded(),
  )
}

///|
test "a zero-padding flag and no flag keep the fixed-width reading" {
  for fmt in ["%Y-%m-%d", "%Y-%m-%0d"] {
    assert_eq(@format.parse_date("2024-03-05", fmt), march_fifth_padded())
    assert_eq(
      padded_kind(() => @format.parse_date("2024-03-5", fmt) |> ignore),
      "InputMismatch",
    )
  }
  assert_eq(@format.parse_date("2024-03- 5", "%Y-%m-%0e"), march_fifth_padded())
}

///|
test "every padding flag round-trips through format for one- and two-digit values" {
  for day in [1, 5, 9, 10, 15, 31] {
    for
      fmt in ["%Y-%m-%-d", "%Y-%m-%_d", "%Y-%m-%0d", "%Y-%-m-%-d", "%Y-%_m-%_d"] {
      let date = @core.NaiveDate::from_ymd(2024, 3, day).unwrap()
      assert_eq(@format.parse_date(@format.format_date(date, fmt), fmt), date)
    }
  }
  for hour in [0, 1, 9, 10, 23] {
    for fmt in ["%-H:%-M:%-S", "%_H:%_M:%_S", "%0H:%0M:%0S"] {
      let time = @core.NaiveTime::from_hms(hour, 5, 7).unwrap()
      assert_eq(@format.parse_time(@format.format_time(time, fmt), fmt), time)
    }
  }
}

///|
test "a padding flag does not change the year, which is already variable-width" {
  assert_eq(
    @format.parse_date("12-03-05", "%-Y-%m-%d"),
    @core.NaiveDate::from_ymd(12, 3, 5).unwrap(),
  )
  assert_eq(@format.parse_date("2024-03-05", "%_Y-%m-%d"), march_fifth_padded())
}
