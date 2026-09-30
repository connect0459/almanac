///|
fn message_of(f : () -> Unit raise @format.ParseError) -> String {
  try f() catch {
    e => e.to_string()
  } noraise {
    _ => "no error"
  }
}

///|
test "ParseError renders a one-line human-readable message for each variant a real failure can raise" {
  assert_eq(
    message_of(() => @format.tokenize("%Q") |> ignore),
    "unknown format specifier '%Q'",
  )
  assert_eq(
    message_of(() => @format.tokenize("%") |> ignore),
    "format string ends with a dangling '%'",
  )
  assert_eq(
    message_of(() => @format.parse_rfc3339("nope") |> ignore),
    "invalid RFC 3339 date-time",
  )
  assert_eq(
    message_of(() => @format.parse_rfc2822("nope") |> ignore),
    "invalid RFC 2822 date-time",
  )
  assert_eq(
    message_of(() => @format.parse_duration("nope") |> ignore),
    "invalid duration",
  )
  assert_eq(
    message_of(() => @format.parse_date_time("2024-03-05", "%F") |> ignore),
    "not enough fields to build the requested value",
  )
  assert_eq(
    message_of(() => @format.parse_date("2024-02-30", "%F") |> ignore),
    "a parsed field is out of range",
  )
  assert_eq(
    message_of(() => @format.parse_date_time("garbage", "%F %T") |> ignore),
    "input does not match the format",
  )
}

///|
test "ParseError MissingField names the item that could not be rendered" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(
    message_of(() => @format.format_date(date, "%Z") |> ignore),
    "format item requires a field the value does not have: Fixed(TimezoneName)",
  )
}

///|
fn kind_of(f : () -> Unit raise @format.ParseError) -> String {
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
test "parsing reports input that ends before the format does as InputTooShort" {
  for
    case in [
      ("2024-03", "%F"),
      ("2024-03-", "%F"),
      ("", "%F"),
      ("2024", "%Y-%m"),
    ] {
    let (input, fmt) = case
    assert_eq(
      kind_of(() => @format.parse_date(input, fmt) |> ignore),
      "InputTooShort",
    )
  }
}

///|
test "parsing reports text after a fully matched format as TrailingInput" {
  assert_eq(
    kind_of(() => @format.parse_date("2024-03-05 rest", "%F") |> ignore),
    "TrailingInput",
  )
  assert_eq(
    kind_of(() => @format.parse_time("09:05:07Z", "%T") |> ignore),
    "TrailingInput",
  )
}

///|
test "parsing still reports text that contradicts a literal or specifier as InputMismatch" {
  for case in [("2024-XX-05", "%F"), ("2024/03/05", "%F"), ("XX:05:07", "%T")] {
    let (input, fmt) = case
    assert_eq(
      kind_of(() => @format.parse_date_time(input, fmt) |> ignore),
      "InputMismatch",
    )
  }
}

///|
test "parsing reports a value outside its field's range as FieldOutOfRange" {
  for
    case in [
      ("2024-13-05", "%F"),
      ("2024-02-30", "%F"),
      ("2023-02-29", "%F"),
      ("2024-000", "%Y-%j"),
      ("2024-367", "%Y-%j"),
      ("2024 54 2", "%G %V %u"),
    ] {
    let (input, fmt) = case
    assert_eq(
      kind_of(() => @format.parse_date(input, fmt) |> ignore),
      "FieldOutOfRange",
    )
  }
  for case in [("24:00:00", "%T"), ("09:60:00", "%T"), ("09:05:61", "%T")] {
    let (input, fmt) = case
    assert_eq(
      kind_of(() => @format.parse_time(input, fmt) |> ignore),
      "FieldOutOfRange",
    )
  }
  assert_eq(
    kind_of(() => @format.parse_time("13 PM", "%I %p") |> ignore),
    "FieldOutOfRange",
  )
  assert_eq(
    kind_of(() => @format.parse_date("2024 7 1", "%Y %w %U") |> ignore),
    "FieldOutOfRange",
  )
}

///|
test "parsing reports an offset beyond the representable range as FieldOutOfRange" {
  assert_eq(
    kind_of(() => @format.parse_fixed_offset("+24:00") |> ignore),
    "FieldOutOfRange",
  )
  assert_eq(
    kind_of(() => {
      @format.parse_date_time_fixed_offset(
        "2024-03-05 09:05:07 +2500", "%F %T %z",
      )
      |> ignore
    }),
    "FieldOutOfRange",
  )
}

///|
test "parsing still reports fields that contradict each other as InconsistentFields" {
  assert_eq(
    kind_of(() => @format.parse_date("2024-03-05 Wednesday", "%F %A") |> ignore),
    "InconsistentFields",
  )
  assert_eq(
    kind_of(() => @format.parse_time(" 9 10", "%k %H") |> ignore),
    "InconsistentFields",
  )
}

///|
test "FieldOutOfRange, InputTooShort and TrailingInput render one-line messages" {
  assert_eq(
    message_of(() => @format.parse_date("2024-13-05", "%F") |> ignore),
    "a parsed field is out of range",
  )
  assert_eq(
    message_of(() => @format.parse_date("2024-03", "%F") |> ignore),
    "input ended before the format did",
  )
  assert_eq(
    message_of(() => @format.parse_date("2024-03-05 x", "%F") |> ignore),
    "input has unparsed text after the format",
  )
  assert_eq(
    message_of(() => {
      @format.parse_date("2024-03-05 Wednesday", "%F %A") |> ignore
    }),
    "parsed fields contradict each other",
  )
}

///|
test "ParseError ParseOnly names the item that can only be parsed" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::unix_epoch(),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(
    message_of(() => @format.format_date_time_tz(dt, "%#z") |> ignore),
    "format item can only be parsed, not rendered: Fixed(TimezoneOffsetPermissive)",
  )
}
