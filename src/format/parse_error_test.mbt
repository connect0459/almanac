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
    message_of(() => @format.parse_from_rfc2822("nope") |> ignore),
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
    "parsed fields are inconsistent or out of range",
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
