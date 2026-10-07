///|
fn edge_kind_of(f : () -> Unit raise @format.FormatError) -> String {
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
fn offset_kind_of(spec : String, offset : String) -> String {
  edge_kind_of(() => {
    @format.parse_date_time_fixed_offset(
      "2024-03-05 09:30:00 \{offset}",
      "%F %T \{spec}",
    )
    |> ignore
  })
}

///|
test "parsing %j rejects an ordinal one day off from the day it accompanies" {
  for input in ["2024-02-04 (034)", "2024-02-04 (036)"] {
    assert_eq(
      edge_kind_of(() => @format.parse_date(input, "%Y-%m-%d (%j)") |> ignore),
      "InconsistentFields",
    )
  }
}

///|
test "parsing %j rejects an ordinal one day off in a leap year's last days" {
  for input in ["2024-12-30 (364)", "2024-12-30 (366)", "2024-12-31 (365)"] {
    assert_eq(
      edge_kind_of(() => @format.parse_date(input, "%Y-%m-%d (%j)") |> ignore),
      "InconsistentFields",
    )
  }
  assert_eq(
    @format.parse_date("2024-12-30 (365)", "%Y-%m-%d (%j)"),
    @core.NaiveDate::from_ymd(2024, 12, 30).unwrap(),
  )
}

///|
test "parsing %j rejects an ordinal that falls in a different month than the date it accompanies" {
  assert_eq(
    edge_kind_of(() => {
      @format.parse_date("2024-02-04 (004)", "%Y-%m-%d (%j)") |> ignore
    }),
    "InconsistentFields",
  )
}

///|
test "parsing %j accepts ordinal 366 for the last day of a leap year and rejects it for a common year" {
  assert_eq(
    @format.parse_date("2024-12-31 (366)", "%Y-%m-%d (%j)"),
    @core.NaiveDate::from_ymd(2024, 12, 31).unwrap(),
  )
  assert_eq(
    edge_kind_of(() => {
      @format.parse_date("2023-12-31 (366)", "%Y-%m-%d (%j)") |> ignore
    }),
    "InconsistentFields",
  )
}

///|
test "parsing a numeric offset rejects an hour beyond 23 in every offset form" {
  for
    case in [
      ("%z", "-2500"),
      ("%z", "+2500"),
      ("%:z", "+25:00"),
      ("%:z", "-24:00"),
      ("%::z", "+25:00:00"),
      ("%:::z", "-25"),
      ("%:::z", "+24"),
      ("%#z", "+25:00"),
    ] {
    let (spec, offset) = case
    assert_eq(offset_kind_of(spec, offset), "FieldOutOfRange")
  }
}

///|
test "parsing a numeric offset reads minutes and seconds as 00 to 59, so a larger value is a mismatch even when the hour is valid" {
  for
    case in [
      ("%z", "-2361"),
      ("%z", "+0960"),
      ("%:z", "-23:61"),
      ("%:z", "+09:60"),
      ("%::z", "-23:61:00"),
      ("%::z", "+23:59:61"),
      ("%::z", "+09:00:60"),
    ] {
    let (spec, offset) = case
    assert_eq(offset_kind_of(spec, offset), "InputMismatch")
  }
}

///|
test "parsing a numeric offset accepts the largest representable magnitude with either sign" {
  for
    case in [
      ("+23:59:59", 23 * 3600 + 59 * 60 + 59),
      ("-23:59:59", -(23 * 3600 + 59 * 60 + 59)),
    ] {
    let (offset, seconds) = case
    assert_eq(
      @format.parse_date_time_fixed_offset(
        "2024-03-05 09:30:00 \{offset}",
        "%F %T %::z",
      ).offset(),
      @tz.FixedOffset::east(seconds).unwrap(),
    )
  }
}

///|
test "parsing %Z discards zone names containing digits, signs and colons" {
  for name in ["GMT+3", "GMT-03", "ChST", "-03", "+0330", "UTC+05:30"] {
    assert_eq(
      @format.parse_date_time("2024-03-05 09:30:00 \{name}", "%F %T %Z"),
      @core.NaiveDateTime::from_ymd_hms(2024, 3, 5, 9, 30, 0).unwrap(),
    )
  }
}
