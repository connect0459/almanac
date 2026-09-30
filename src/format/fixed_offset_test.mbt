///|
fn offset_secs(input : String) -> Int raise @format.ParseError {
  @format.parse_fixed_offset(input).local_minus_utc()
}

///|
test "parse_fixed_offset reads the colon-separated, compact and hour-only forms" {
  assert_eq(offset_secs("+09:00"), 9 * 3600)
  assert_eq(offset_secs("-05:30"), -(5 * 3600 + 30 * 60))
  assert_eq(offset_secs("+0900"), 9 * 3600)
  assert_eq(offset_secs("-0530"), -(5 * 3600 + 30 * 60))
  assert_eq(offset_secs("+09"), 9 * 3600)
  assert_eq(offset_secs("-05"), -5 * 3600)
}

///|
test "parse_fixed_offset reads a seconds component for a non-whole-minute offset" {
  assert_eq(offset_secs("+09:00:30"), 9 * 3600 + 30)
  assert_eq(offset_secs("-04:56:02"), -(4 * 3600 + 56 * 60 + 2))
}

///|
test "parse_fixed_offset reads Z and z as a zero offset" {
  assert_eq(offset_secs("Z"), 0)
  assert_eq(offset_secs("z"), 0)
  assert_eq(offset_secs("+00:00"), 0)
}

///|
test "parse_fixed_offset round-trips every offset through its Show rendering" {
  for
    secs in [
      0,
      3600,
      -3600,
      9 * 3600 + 1800,
      -(4 * 3600 + 56 * 60 + 2),
      86399,
      -86399,
    ] {
    let offset = @tz.FixedOffset::east(secs).unwrap()
    assert_eq(@format.parse_fixed_offset(offset.to_string()), offset)
  }
}

///|
test "parse_fixed_offset rejects text that is not a whole offset" {
  for
    input in [
      "", "+", "09:00", "+9:00", "+09:0", "+09:00:", "+09:00:3", "+09000", "+09:00 ",
      " +09:00", "+09:0a", "UTC", "ZZ", "+09:00:30:00", "+0900:30",
    ] {
    try @format.parse_fixed_offset(input) |> ignore catch {
      @format.InputMismatch => ()
      _ => fail("expected InputMismatch for \{input}")
    } noraise {
      _ => fail("expected parse_fixed_offset to reject \{input}")
    }
  }
}

///|
test "parse_fixed_offset rejects an offset beyond 23:59:59 or with minutes or seconds above 59" {
  for input in ["+24:00", "-24:00", "+99", "+09:60", "+09:00:60", "+0960"] {
    try @format.parse_fixed_offset(input) |> ignore catch {
      @format.InputMismatch | @format.FieldOutOfRange => ()
      _ => fail("expected a rejection for \{input}")
    } noraise {
      _ => fail("expected parse_fixed_offset to reject \{input}")
    }
  }
}

///|
test "parse_fixed_offset reports a well-shaped but out-of-range offset as FieldOutOfRange" {
  for input in ["+24:00", "-24:00", "+99"] {
    try @format.parse_fixed_offset(input) |> ignore catch {
      @format.FieldOutOfRange => ()
      _ => fail("expected FieldOutOfRange for \{input}")
    } noraise {
      _ => fail("expected parse_fixed_offset to reject \{input}")
    }
  }
}
