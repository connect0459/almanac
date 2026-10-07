///|
test "a five-field expression fires at second zero" {
  let cron = @cron.Cron::parse("*/15 * * * *")
  assert_true(cron.matches(utc_at(2024, 3, 5, 10, 0, 0)))
  assert_true(cron.matches(utc_at(2024, 3, 5, 10, 45, 0)))
  assert_false(cron.matches(utc_at(2024, 3, 5, 10, 10, 0)))
  assert_false(cron.matches(utc_at(2024, 3, 5, 10, 15, 5)))
}

///|
test "a six-field expression puts the seconds field first" {
  let cron = @cron.Cron::parse("30 0 12 * * *")
  assert_true(cron.matches(utc_at(2024, 3, 5, 12, 0, 30)))
  assert_false(cron.matches(utc_at(2024, 3, 5, 12, 0, 0)))
}

///|
test "lists, ranges and stepped ranges combine within one field" {
  let cron = @cron.Cron::parse("1,10-20/5,59 * * * *")
  for minute in [1, 10, 15, 20, 59] {
    assert_true(cron.matches(utc_at(2024, 3, 5, 7, minute, 0)))
  }
  for minute in [0, 2, 11, 25, 58] {
    assert_false(cron.matches(utc_at(2024, 3, 5, 7, minute, 0)))
  }
}

///|
test "month and weekday names are case-insensitive and may form ranges" {
  let cron = @cron.Cron::parse("0 9 * jan-MAR Mon-Fri")
  assert_true(cron.matches(utc_at(2024, 3, 5, 9, 0, 0)))
  assert_false(cron.matches(utc_at(2024, 3, 9, 9, 0, 0)))
  assert_false(cron.matches(utc_at(2024, 4, 5, 9, 0, 0)))
}

///|
test "both 0 and 7 mean Sunday" {
  assert_eq(@cron.Cron::parse("0 0 * * 0"), @cron.Cron::parse("0 0 * * 7"))
  assert_eq(@cron.Cron::parse("0 0 * * 0"), @cron.Cron::parse("0 0 * * SUN"))
  assert_true(
    @cron.Cron::parse("0 0 * * 7").matches(utc_at(2024, 10, 13, 0, 0, 0)),
  )
  assert_eq(
    @cron.Cron::parse("0 0 * * 5-7"),
    @cron.Cron::parse("0 0 * * 5,6,0"),
  )
}

///|
test "a question mark in the day fields means any value" {
  assert_eq(@cron.Cron::parse("0 0 ? * 1"), @cron.Cron::parse("0 0 * * 1"))
  assert_eq(@cron.Cron::parse("0 0 13 * ?"), @cron.Cron::parse("0 0 13 * *"))
}

///|
test "each shorthand equals its five-field expansion" {
  assert_eq(@cron.Cron::parse("@yearly"), @cron.Cron::parse("0 0 1 1 *"))
  assert_eq(@cron.Cron::parse("@monthly"), @cron.Cron::parse("0 0 1 * *"))
  assert_eq(@cron.Cron::parse("@weekly"), @cron.Cron::parse("0 0 * * 0"))
  assert_eq(@cron.Cron::parse("@daily"), @cron.Cron::parse("0 0 * * *"))
  assert_eq(@cron.Cron::parse("@hourly"), @cron.Cron::parse("0 * * * *"))
}

///|
test "fields may be separated by runs of spaces and tabs" {
  assert_eq(
    @cron.Cron::parse("  0 \t 12   * * *  "),
    @cron.Cron::parse("0 12 * * *"),
  )
}

///|
test "a field count other than five or six names FieldCount" {
  assert_invalid_field("", FieldCount)
  assert_invalid_field("* * * *", FieldCount)
  assert_invalid_field("* * * * * * *", FieldCount)
  assert_invalid_field("@daily extra", FieldCount)
}

///|
test "@annually is a synonym of @yearly" {
  assert_eq(@cron.Cron::parse("@annually"), @cron.Cron::parse("@yearly"))
}

///|
test "@midnight is a synonym of @daily" {
  assert_eq(@cron.Cron::parse("@midnight"), @cron.Cron::parse("@daily"))
}

///|
test "an upper-case shorthand is read like its lower-case form" {
  assert_eq(@cron.Cron::parse("@DAILY"), @cron.Cron::parse("@daily"))
}

///|
test "a mixed-case shorthand is read like its lower-case form" {
  assert_eq(@cron.Cron::parse("@AnNuAlLy"), @cron.Cron::parse("@yearly"))
}

///|
test "a synonym is matched without regard to case" {
  assert_eq(@cron.Cron::parse("@MIDNIGHT"), @cron.Cron::parse("@daily"))
}

///|
test "a shorthand spelled with non-ASCII look-alike letters names Shorthand" {
  assert_invalid_field("@DA\u{130}LY", Shorthand)
  assert_invalid_field("@wee\u{212A}ly", Shorthand)
}

///|
test "an unknown shorthand names Shorthand" {
  assert_invalid_field("@reboot", Shorthand)
  assert_invalid_field("@REBOOT", Shorthand)
  assert_invalid_field("@", Shorthand)
}

///|
test "an out-of-range value names the field it is in" {
  assert_invalid_field("60 0 0 * * *", Second)
  assert_invalid_field("60 * * * *", Minute)
  assert_invalid_field("0 61 0 * * *", Minute)
  assert_invalid_field("* 24 * * *", Hour)
  assert_invalid_field("* * 0 * *", DayOfMonth)
  assert_invalid_field("* * 32 * *", DayOfMonth)
  assert_invalid_field("* * * 0 *", Month)
  assert_invalid_field("* * * 13 *", Month)
  assert_invalid_field("* * * * 8", DayOfWeek)
}

///|
test "malformed items name the field they are in" {
  assert_invalid_field("5-1 * * * *", Minute)
  assert_invalid_field("*/0 * * * *", Minute)
  assert_invalid_field("1,,2 * * * *", Minute)
  assert_invalid_field("1- * * * *", Minute)
  assert_invalid_field("1/5 * * * *", Minute)
  assert_invalid_field("-1 * * * *", Minute)
  assert_invalid_field("+1 * * * *", Minute)
  assert_invalid_field("a * * * *", Minute)
  assert_invalid_field("* * * foo *", Month)
  assert_invalid_field("* * * * foo", DayOfWeek)
  assert_invalid_field("* * * * 1-foo", DayOfWeek)
  assert_invalid_field("*/5/2 * * * *", Minute)
  assert_invalid_field("1-2-3 * * * *", Minute)
}

///|
test "a question mark outside the day fields is rejected" {
  assert_invalid_field("? * * * *", Minute)
  assert_invalid_field("* ? * * *", Hour)
  assert_invalid_field("* * * ? *", Month)
  assert_invalid_field("*/5 * ?/2 * *", DayOfMonth)
}

///|
test "the error message names the offending field" {
  let cases : Array[(String, String)] = [
    ("60 0 0 * * *", "second"),
    ("60 * * * *", "minute"),
    ("* 24 * * *", "hour"),
    ("* * 0 * *", "day of month"),
    ("* * * 13 *", "month"),
    ("* * * * 8", "day of week"),
    ("* * *", "number of fields"),
    ("@never", "shorthand"),
  ]
  for case in cases {
    let (expression, label) = case
    let msg = try @cron.Cron::parse(expression) |> ignore catch {
      e => e.to_string()
    } noraise {
      _ => ""
    }
    assert_eq(msg, "invalid cron expression: " + label)
  }
}
