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
      ("%I", @format.Hour12),
      ("%l", @format.Hour12Blank),
      ("%s", @format.Timestamp),
      ("%G", @format.IsoYear),
      ("%g", @format.IsoYear2),
      ("%V", @format.IsoWeekNumber),
      ("%C", @format.Century),
      ("%y", @format.YearMod100),
      ("%q", @format.Quarter),
      ("%e", @format.DayBlank),
      ("%w", @format.WeekdayNumberSunday0),
      ("%u", @format.WeekdayNumberMonday1),
      ("%U", @format.WeekSunday),
      ("%W", @format.WeekMonday),
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
      ("%b", @format.ShortMonthName),
      ("%h", @format.ShortMonthName),
      ("%B", @format.LongMonthName),
      ("%P", @format.AmPmLower),
      ("%p", @format.AmPmUpper),
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
test "tokenize expands %D and %x into month-day-year (2-digit year) joined by literal slashes" {
  for spec in ["%D", "%x"] {
    assert_eq(@format.tokenize(spec), [
      @format.Numeric(@format.Month),
      @format.Literal("/"),
      @format.Numeric(@format.Day),
      @format.Literal("/"),
      @format.Numeric(@format.YearMod100),
    ])
  }
}

///|
test "tokenize expands %v into VMS-style day-month-year" {
  assert_eq(@format.tokenize("%v"), [
    @format.Numeric(@format.DayBlank),
    @format.Literal("-"),
    @format.Fixed(@format.ShortMonthName),
    @format.Literal("-"),
    @format.Numeric(@format.Year),
  ])
}

///|
test "tokenize expands %R into hour-minute joined by a literal colon" {
  assert_eq(@format.tokenize("%R"), [
    @format.Numeric(@format.Hour),
    @format.Literal(":"),
    @format.Numeric(@format.Minute),
  ])
}

///|
test "tokenize expands %X the same as %T (hour-minute-second)" {
  assert_eq(@format.tokenize("%X"), @format.tokenize("%T"))
}

///|
test "tokenize expands %r into the 12-hour clock with seconds and an am/pm marker" {
  assert_eq(@format.tokenize("%r"), [
    @format.Numeric(@format.Hour12),
    @format.Literal(":"),
    @format.Numeric(@format.Minute),
    @format.Literal(":"),
    @format.Numeric(@format.Second),
    @format.Literal(" "),
    @format.Fixed(@format.AmPmUpper),
  ])
}

///|
test "tokenize expands %c into a ctime-style weekday, month, day, time, and year sequence" {
  assert_eq(@format.tokenize("%c"), [
    @format.Fixed(@format.ShortWeekdayName),
    @format.Literal(" "),
    @format.Fixed(@format.ShortMonthName),
    @format.Literal(" "),
    @format.Numeric(@format.DayBlank),
    @format.Literal(" "),
    @format.Numeric(@format.Hour),
    @format.Literal(":"),
    @format.Numeric(@format.Minute),
    @format.Literal(":"),
    @format.Numeric(@format.Second),
    @format.Literal(" "),
    @format.Numeric(@format.Year),
  ])
}

///|
test "tokenize recognizes %+ as a dedicated RFC 3339 item" {
  assert_eq(@format.tokenize("%+"), [@format.Rfc3339])
}

///|
test "tokenize recognizes %.f, %3f, %6f, and %9f as fractional-second specifiers" {
  assert_eq(@format.tokenize("%.f"), [@format.Numeric(@format.DotFraction)])
  assert_eq(@format.tokenize("%3f"), [@format.Numeric(@format.Nanosecond3)])
  assert_eq(@format.tokenize("%6f"), [@format.Numeric(@format.Nanosecond6)])
  assert_eq(@format.tokenize("%9f"), @format.tokenize("%f"))
}

///|
test "tokenize raises UnknownSpecifier for %.x (an unsupported dot-prefixed specifier)" {
  try @format.tokenize("%.x") |> ignore catch {
    @format.UnknownSpecifier('.') => ()
    _ => fail("expected UnknownSpecifier('.')")
  } noraise {
    _ => fail("expected tokenize to reject %.x")
  }
}

///|
test "tokenize raises UnknownSpecifier for a bare %3, %6, or %9 not followed by f" {
  for case in [("%3x", '3'), ("%6x", '6'), ("%9x", '9')] {
    let (spec, expected_char) = case
    try @format.tokenize(spec) |> ignore catch {
      @format.UnknownSpecifier(c) => assert_eq(c, expected_char)
      _ => fail("expected UnknownSpecifier for \{spec}")
    } noraise {
      _ => fail("expected tokenize to reject \{spec}")
    }
  }
}

///|
test "tokenize recognizes %:z, %::z, %:::z, and %#z as timezone-offset variants" {
  for
    case in [
      ("%:z", @format.TimezoneOffsetColonMinutes),
      ("%::z", @format.TimezoneOffsetColonSeconds),
      ("%:::z", @format.TimezoneOffsetColonHours),
      ("%#z", @format.TimezoneOffsetPermissive),
    ] {
    let (spec, expected) = case
    assert_eq(@format.tokenize(spec), [@format.Fixed(expected)])
  }
}

///|
test "tokenize raises UnknownSpecifier for a colon count outside 1..=3 before z" {
  try @format.tokenize("%::::z") |> ignore catch {
    @format.UnknownSpecifier(':') => ()
    _ => fail("expected UnknownSpecifier(':')")
  } noraise {
    _ => fail("expected tokenize to reject %::::z")
  }
}

///|
test "tokenize raises UnknownSpecifier when a colon run or # isn't followed by z" {
  try @format.tokenize("%:x") |> ignore catch {
    @format.UnknownSpecifier(':') => ()
    _ => fail("expected UnknownSpecifier(':')")
  } noraise {
    _ => fail("expected tokenize to reject %:x")
  }
  try @format.tokenize("%#x") |> ignore catch {
    @format.UnknownSpecifier('#') => ()
    _ => fail("expected UnknownSpecifier('#')")
  } noraise {
    _ => fail("expected tokenize to reject %#x")
  }
}

///|
test "tokenize recognizes %-Y, %0e, and %_d as padding-flag overrides on a bare numeric specifier" {
  assert_eq(@format.tokenize("%-Y"), [
    @format.PaddedNumeric(@format.Year, @format.NoPad),
  ])
  assert_eq(@format.tokenize("%0e"), [
    @format.PaddedNumeric(@format.DayBlank, @format.ZeroPad),
  ])
  assert_eq(@format.tokenize("%_d"), [
    @format.PaddedNumeric(@format.Day, @format.SpacePad),
  ])
}

///|
test "tokenize applies a padding flag to a multi-character numeric specifier (%-3f is rejected, since %3f is Fixed in chrono's own model)" {
  assert_eq(@format.tokenize("%-C"), [
    @format.PaddedNumeric(@format.Century, @format.NoPad),
  ])
  try @format.tokenize("%-3f") |> ignore catch {
    @format.UnknownSpecifier('-') => ()
    _ => fail("expected UnknownSpecifier('-')")
  } noraise {
    _ => fail("expected tokenize to reject %-3f")
  }
}

///|
test "tokenize rejects a padding flag applied to a Fixed specifier or a compound expansion" {
  for case in [("%-A", '-'), ("%0F", '0'), ("%_z", '_'), ("%-f", '-')] {
    let (spec, expected_char) = case
    try @format.tokenize(spec) |> ignore catch {
      @format.UnknownSpecifier(c) => assert_eq(c, expected_char)
      _ => fail("expected UnknownSpecifier for \{spec}")
    } noraise {
      _ => fail("expected tokenize to reject \{spec}")
    }
  }
}

///|
test "tokenize raises TrailingPercent when a padding flag ends the format string" {
  try @format.tokenize("abc%-") |> ignore catch {
    @format.TrailingPercent => ()
    _ => fail("expected TrailingPercent")
  } noraise {
    _ => fail("expected tokenize to reject a trailing padding flag")
  }
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

///|
test "tokenize recognizes %k as the space-padded 24-hour numeric field" {
  assert_eq(@format.tokenize("%k"), [@format.Numeric(@format.HourBlank)])
}

///|
test "tokenize expands %n and %t to a literal newline and tab" {
  assert_eq(@format.tokenize("%n"), [@format.Literal("\n")])
  assert_eq(@format.tokenize("%t"), [@format.Literal("\t")])
  assert_eq(@format.tokenize("%H%t%M%n"), [
    @format.Numeric(@format.Hour),
    @format.Literal("\t"),
    @format.Numeric(@format.Minute),
    @format.Literal("\n"),
  ])
}

///|
test "tokenize recognizes %.3f, %.6f and %.9f as dot-prefixed fixed-width fractions" {
  assert_eq(@format.tokenize("%.3f"), [@format.Numeric(@format.DotNanosecond3)])
  assert_eq(@format.tokenize("%.6f"), [@format.Numeric(@format.DotNanosecond6)])
  assert_eq(@format.tokenize("%.9f"), [@format.Numeric(@format.DotNanosecond9)])
}

///|
test "tokenize rejects a dot-prefixed fraction width other than 3, 6 or 9 and an unfinished %.3" {
  for spec in ["%.4f", "%.3", "%.3x", "%.0f"] {
    try @format.tokenize(spec) |> ignore catch {
      @format.UnknownSpecifier('.') => ()
      _ => fail("expected UnknownSpecifier('.') for \{spec}")
    } noraise {
      _ => fail("expected tokenize to reject \{spec}")
    }
  }
}

///|
test "tokenize rejects a padding flag on the dot-prefixed fixed-width fractions" {
  for spec in ["%-.3f", "%0.6f", "%_.9f"] {
    try @format.tokenize(spec) |> ignore catch {
      @format.UnknownSpecifier(_) => ()
      _ => fail("expected UnknownSpecifier for \{spec}")
    } noraise {
      _ => fail("expected tokenize to reject \{spec}")
    }
  }
}
