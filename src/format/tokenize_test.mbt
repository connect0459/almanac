///|
test "tokenize parses a literal-only format string as a single Literal item" {
  assert_eq(@format.tokenize("hello"), [@format.Literal("hello")])
}

///|
test "tokenize recognizes each numeric specifier" {
  for
    case in [
      ("%Y", @format.Year),
      ("%m", @format.Month),
      ("%d", @format.Day),
      ("%j", @format.Ordinal),
      ("%H", @format.Hour),
      ("%M", @format.Minute),
      ("%S", @format.Second),
      ("%f", @format.Nanosecond),
    ] {
    let (spec, expected) = case
    assert_eq(@format.tokenize(spec), [@format.Numeric(expected)])
  }
}

///|
test "tokenize recognizes each fixed specifier" {
  for
    case in [
      ("%A", @format.LongWeekdayName),
      ("%a", @format.ShortWeekdayName),
      ("%Z", @format.TimezoneName),
      ("%z", @format.TimezoneOffset),
    ] {
    let (spec, expected) = case
    assert_eq(@format.tokenize(spec), [@format.Fixed(expected)])
  }
}

///|
test "tokenize expands %F into year-month-day numeric items joined by literal hyphens" {
  assert_eq(@format.tokenize("%F"), [
    @format.Numeric(@format.Year),
    @format.Literal("-"),
    @format.Numeric(@format.Month),
    @format.Literal("-"),
    @format.Numeric(@format.Day),
  ])
}

///|
test "tokenize expands %T into hour-minute-second numeric items joined by literal colons" {
  assert_eq(@format.tokenize("%T"), [
    @format.Numeric(@format.Hour),
    @format.Literal(":"),
    @format.Numeric(@format.Minute),
    @format.Literal(":"),
    @format.Numeric(@format.Second),
  ])
}

///|
test "tokenize interprets %% as a literal percent sign" {
  assert_eq(@format.tokenize("100%%"), [@format.Literal("100%")])
}

///|
test "tokenize mixes literal text and specifiers in sequence" {
  assert_eq(@format.tokenize("%Y-%m-%d"), [
    @format.Numeric(@format.Year),
    @format.Literal("-"),
    @format.Numeric(@format.Month),
    @format.Literal("-"),
    @format.Numeric(@format.Day),
  ])
}

///|
test "tokenize raises UnknownSpecifier for an unrecognized specifier character" {
  try @format.tokenize("%Q") |> ignore catch {
    @format.UnknownSpecifier('Q') => ()
    @format.UnknownSpecifier(_) =>
      fail("wrong char carried by UnknownSpecifier")
    _ => fail("expected UnknownSpecifier")
  } noraise {
    _ => fail("expected tokenize to raise UnknownSpecifier")
  }
}

///|
test "tokenize raises TrailingPercent when the format string ends with a lone percent" {
  try @format.tokenize("abc%") |> ignore catch {
    @format.TrailingPercent => ()
    _ => fail("expected TrailingPercent")
  } noraise {
    _ => fail("expected tokenize to raise TrailingPercent")
  }
}
