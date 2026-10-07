///|
fn iso_duration(input : String) -> @core.TimeDelta raise @format.FormatError {
  @format.parse_iso8601_duration(input)
}

///|
fn assert_invalid_iso_duration(input : String) -> Unit raise {
  try @format.parse_iso8601_duration(input) |> ignore catch {
    @format.InvalidDuration => ()
    _ => fail("expected InvalidDuration for \{input}")
  } noraise {
    _ => fail("expected InvalidDuration for \{input}")
  }
}

///|
test "to_iso8601_duration writes zero as P0D" {
  assert_eq(@format.to_iso8601_duration(@core.TimeDelta::zero()), "P0D")
}

///|
test "to_iso8601_duration writes whole seconds as a single seconds component" {
  assert_eq(
    @format.to_iso8601_duration(@core.TimeDelta::seconds(1L).unwrap()),
    "PT1S",
  )
  assert_eq(
    @format.to_iso8601_duration(@core.TimeDelta::hours(1L).unwrap()),
    "PT3600S",
  )
  assert_eq(
    @format.to_iso8601_duration(@core.TimeDelta::days(2L).unwrap()),
    "PT172800S",
  )
}

///|
test "to_iso8601_duration trims trailing zeros of the fractional second" {
  assert_eq(
    @format.to_iso8601_duration(@core.TimeDelta::milliseconds(1_500L).unwrap()),
    "PT1.5S",
  )
  assert_eq(
    @format.to_iso8601_duration(@core.TimeDelta::nanoseconds(1L).unwrap()),
    "PT0.000000001S",
  )
  assert_eq(
    @format.to_iso8601_duration(
      @core.TimeDelta::nanoseconds(123_456_000L).unwrap(),
    ),
    "PT0.123456S",
  )
  assert_eq(
    @format.to_iso8601_duration(
      @core.TimeDelta::nanoseconds(1_000_000_001L).unwrap(),
    ),
    "PT1.000000001S",
  )
}

///|
test "to_iso8601_duration prefixes a negative duration with a minus sign" {
  assert_eq(
    @format.to_iso8601_duration(@core.TimeDelta::milliseconds(-1_500L).unwrap()),
    "-PT1.5S",
  )
  assert_eq(
    @format.to_iso8601_duration(@core.TimeDelta::nanoseconds(-1L).unwrap()),
    "-PT0.000000001S",
  )
  assert_eq(
    @format.to_iso8601_duration(@core.TimeDelta::seconds(-60L).unwrap()),
    "-PT60S",
  )
}

///|
test "parse_iso8601_duration reads each time designator" {
  assert_eq(iso_duration("PT1H"), @core.TimeDelta::hours(1L).unwrap())
  assert_eq(iso_duration("PT1M"), @core.TimeDelta::minutes(1L).unwrap())
  assert_eq(iso_duration("PT1S"), @core.TimeDelta::seconds(1L).unwrap())
}

///|
test "parse_iso8601_duration sums hours, minutes and seconds" {
  assert_eq(iso_duration("PT1H2M3S"), @core.TimeDelta::seconds(3_723L).unwrap())
  assert_eq(iso_duration("PT90M"), @core.TimeDelta::minutes(90L).unwrap())
  assert_eq(iso_duration("PT3600S"), @core.TimeDelta::hours(1L).unwrap())
  assert_eq(iso_duration("PT100H"), @core.TimeDelta::hours(100L).unwrap())
}

///|
test "parse_iso8601_duration reads a day as exactly twenty-four hours" {
  assert_eq(iso_duration("P1D"), @core.TimeDelta::hours(24L).unwrap())
  assert_eq(iso_duration("P0D"), @core.TimeDelta::zero())
  assert_eq(iso_duration("P2DT3H"), @core.TimeDelta::hours(51L).unwrap())
  assert_eq(iso_duration("P1DT0S"), @core.TimeDelta::hours(24L).unwrap())
}

///|
test "parse_iso8601_duration reads a fractional last component" {
  assert_eq(
    iso_duration("PT1.5S"),
    @core.TimeDelta::milliseconds(1_500L).unwrap(),
  )
  assert_eq(iso_duration("PT0.5H"), @core.TimeDelta::minutes(30L).unwrap())
  assert_eq(iso_duration("PT1.5M"), @core.TimeDelta::seconds(90L).unwrap())
  assert_eq(
    iso_duration("PT1H30.25S"),
    @core.TimeDelta::milliseconds(3_630_250L).unwrap(),
  )
  assert_eq(
    iso_duration("PT0.000000001S"),
    @core.TimeDelta::nanoseconds(1L).unwrap(),
  )
}

///|
test "parse_iso8601_duration accepts a comma as the decimal mark" {
  assert_eq(
    iso_duration("PT1,5S"),
    @core.TimeDelta::milliseconds(1_500L).unwrap(),
  )
}

///|
test "parse_iso8601_duration drops fractional digits beyond the ninth before applying the unit" {
  assert_eq(
    iso_duration("PT0.3333333333H"),
    @core.TimeDelta::nanoseconds(1_199_999_998_800L).unwrap(),
  )
}

///|
test "parse_iso8601_duration truncates digits finer than a nanosecond" {
  assert_eq(
    iso_duration("PT0.0000000019S"),
    @core.TimeDelta::nanoseconds(1L).unwrap(),
  )
}

///|
test "parse_iso8601_duration applies a leading sign to the whole duration" {
  assert_eq(
    iso_duration("-PT1.5S"),
    @core.TimeDelta::milliseconds(-1_500L).unwrap(),
  )
  assert_eq(
    iso_duration("+PT1.5S"),
    @core.TimeDelta::milliseconds(1_500L).unwrap(),
  )
  assert_eq(iso_duration("-P1DT1H"), @core.TimeDelta::hours(-25L).unwrap())
  assert_eq(iso_duration("-P0D"), @core.TimeDelta::zero())
}

///|
test "parse_iso8601_duration rejects text without a P designator or any component" {
  for input in ["", "P", "PT", "T1S", "1S", "PT1S ", " PT1S", "PT1SX", "P1DT"] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects a number without a designator" {
  for input in ["P1", "PT1", "PT1H2", "P1DT1"] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects year, month and week designators" {
  for input in ["P1Y", "P1M", "P1W", "P1Y2M3DT4H", "P0Y", "P0W"] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects lower-case designators" {
  for input in ["pt1s", "PT1h", "P1d", "p1dt1h"] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects components out of order or repeated" {
  for
    input in [
      "PT1S1M", "PT1M1H", "PT1H1H", "P1DP1D", "PT1S1S", "PTT1S", "P1DT1D",
    ] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects a fraction anywhere but the last component" {
  for input in ["PT1.5M30S", "PT0.5H1M", "PT1.5H1S"] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects a fractional day" {
  for input in ["P1.5D", "P0.5DT1H"] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects malformed numbers" {
  for input in ["PT.5S", "PT1.S", "PT-1S", "PT+1S", "PT1..5S", "PT1e3S", "PTS"] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects a misplaced or doubled sign" {
  for input in ["--PT1S", "+-PT1S", "P-1D", "-", "+"] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "parse_iso8601_duration rejects a value outside the TimeDelta range" {
  for
    input in [
      "PT99999999999999999999S", "P99999999999999999999D", "PT9223372036854775807H",
      "P9223372036854775807D",
    ] {
    assert_invalid_iso_duration(input)
  }
}

///|
test "to_iso8601_duration output is read back unchanged" {
  let values = [
    @core.TimeDelta::zero(),
    @core.TimeDelta::nanoseconds(1L).unwrap(),
    @core.TimeDelta::nanoseconds(-1L).unwrap(),
    @core.TimeDelta::milliseconds(1_500L).unwrap(),
    @core.TimeDelta::milliseconds(-1_500L).unwrap(),
    @core.TimeDelta::hours(25L).unwrap(),
    @core.TimeDelta::new(86_400L, 999_999_999).unwrap(),
    @core.TimeDelta::max_value(),
    @core.TimeDelta::min_value(),
  ]
  for value in values {
    assert_eq(iso_duration(@format.to_iso8601_duration(value)), value)
  }
}
