///|
fn parsed(input : String) -> @core.TimeDelta raise @format.ParseError {
  @format.parse_duration(input)
}

///|
test "parse_duration reads a bare zero without a unit" {
  for input in ["0", "+0", "-0", "0s", "0h0m0s"] {
    assert_eq(parsed(input), @core.TimeDelta::zero())
  }
}

///|
test "parse_duration reads each supported unit" {
  assert_eq(parsed("1ns"), @core.TimeDelta::nanoseconds(1L).unwrap())
  assert_eq(parsed("1us"), @core.TimeDelta::microseconds(1L).unwrap())
  assert_eq(parsed("1\u{B5}s"), @core.TimeDelta::microseconds(1L).unwrap())
  assert_eq(parsed("1\u{3BC}s"), @core.TimeDelta::microseconds(1L).unwrap())
  assert_eq(parsed("1ms"), @core.TimeDelta::milliseconds(1L).unwrap())
  assert_eq(parsed("1s"), @core.TimeDelta::seconds(1L).unwrap())
  assert_eq(parsed("1m"), @core.TimeDelta::minutes(1L).unwrap())
  assert_eq(parsed("1h"), @core.TimeDelta::hours(1L).unwrap())
}

///|
test "parse_duration sums consecutive number-unit components" {
  assert_eq(parsed("1h30m"), @core.TimeDelta::minutes(90L).unwrap())
  assert_eq(
    parsed("1h2m3.5s"),
    @core.TimeDelta::milliseconds(3_723_500L).unwrap(),
  )
  assert_eq(parsed("300ms"), @core.TimeDelta::milliseconds(300L).unwrap())
  assert_eq(parsed("1h1h"), @core.TimeDelta::hours(2L).unwrap())
  assert_eq(parsed("100h"), @core.TimeDelta::hours(100L).unwrap())
}

///|
test "parse_duration applies a leading sign to the whole duration" {
  assert_eq(parsed("-1.5s"), @core.TimeDelta::milliseconds(-1_500L).unwrap())
  assert_eq(parsed("+1.5s"), @core.TimeDelta::milliseconds(1_500L).unwrap())
  assert_eq(parsed("-1h30m"), @core.TimeDelta::minutes(-90L).unwrap())
}

///|
test "parse_duration accepts fractional components" {
  assert_eq(parsed(".5s"), @core.TimeDelta::milliseconds(500L).unwrap())
  assert_eq(parsed("1.s"), @core.TimeDelta::seconds(1L).unwrap())
  assert_eq(parsed("1.5h"), @core.TimeDelta::minutes(90L).unwrap())
  assert_eq(parsed("1.5us"), @core.TimeDelta::nanoseconds(1_500L).unwrap())
  assert_eq(parsed("0.000000001s"), @core.TimeDelta::nanoseconds(1L).unwrap())
}

///|
test "parse_duration truncates precision finer than a nanosecond toward zero" {
  assert_eq(parsed("1.5ns"), @core.TimeDelta::nanoseconds(1L).unwrap())
  assert_eq(parsed("-1.5ns"), @core.TimeDelta::nanoseconds(-1L).unwrap())
  assert_eq(
    parsed("1.0000000019s"),
    @core.TimeDelta::nanoseconds(1_000_000_001L).unwrap(),
  )
}

///|
test "parse_duration round-trips the string form of a duration" {
  for
    delta in [
      @core.TimeDelta::zero(),
      @core.TimeDelta::nanoseconds(1L).unwrap(),
      @core.TimeDelta::nanoseconds(1_500L).unwrap(),
      @core.TimeDelta::milliseconds(-1_500L).unwrap(),
      @core.TimeDelta::milliseconds(3_723_500L).unwrap(),
      @core.TimeDelta::hours(-100L).unwrap(),
      @core.TimeDelta::max_value(),
      @core.TimeDelta::min_value(),
    ] {
    assert_eq(parsed(delta.to_string()), delta)
  }
}

///|
test "parse_duration rejects malformed input" {
  for
    bad in [
      "", "s", ".", ".s", "+", "-", "1", "1x", "1 s", " 1s", "1s ", "--1s", "1h-1m",
      "1S", "1d", "abc", "1.5.5s", "1hh", "h1", "1\u{B5}", "1m1",
    ] {
    try parsed(bad) |> ignore catch {
      @format.InvalidDuration => ()
      _ => fail("expected InvalidDuration for \{bad}")
    } noraise {
      _ => fail("expected InvalidDuration for \{bad}")
    }
  }
}

///|
test "parse_duration rejects a value beyond the representable range" {
  for
    bad in [
      "9223372036854775808s", "9223372036854775s", "2562047788016h", "2562047788015h13m",
      "99999999999999999999ns",
    ] {
    try parsed(bad) |> ignore catch {
      @format.InvalidDuration => ()
      _ => fail("expected InvalidDuration for \{bad}")
    } noraise {
      _ => fail("expected InvalidDuration for \{bad}")
    }
  }
}

///|
test "parse_duration accepts the largest representable duration" {
  assert_eq(parsed("9223372036854774.999999999s"), @core.TimeDelta::max_value())
}
