///|
fn iso_period(input : String) -> @core.Period raise @format.FormatError {
  @format.parse_iso8601_period(input)
}

///|
fn assert_invalid_iso_period(input : String) -> Unit raise {
  try @format.parse_iso8601_period(input) |> ignore catch {
    @format.InvalidDuration => ()
    _ => fail("expected InvalidDuration for \{input}")
  } noraise {
    _ => fail("expected InvalidDuration for \{input}")
  }
}

///|
test "to_iso8601_period writes zero as P0D" {
  assert_eq(@format.to_iso8601_period(@core.Period::zero()), "P0D")
}

///|
test "to_iso8601_period omits zero components" {
  assert_eq(
    @format.to_iso8601_period(@core.Period::new(years=1, months=2, days=3)),
    "P1Y2M3D",
  )
  assert_eq(@format.to_iso8601_period(@core.Period::new(years=1)), "P1Y")
  assert_eq(@format.to_iso8601_period(@core.Period::new(months=2)), "P2M")
  assert_eq(@format.to_iso8601_period(@core.Period::new(days=3)), "P3D")
  assert_eq(
    @format.to_iso8601_period(@core.Period::new(years=1, days=3)),
    "P1Y3D",
  )
}

///|
test "to_iso8601_period keeps components as given without normalizing" {
  assert_eq(@format.to_iso8601_period(@core.Period::new(months=14)), "P14M")
  assert_eq(@format.to_iso8601_period(@core.Period::new(days=400)), "P400D")
}

///|
test "to_iso8601_period writes a period of only non-positive components with one leading sign" {
  assert_eq(
    @format.to_iso8601_period(@core.Period::new(years=-1, months=-2, days=-3)),
    "-P1Y2M3D",
  )
  assert_eq(@format.to_iso8601_period(@core.Period::new(days=-3)), "-P3D")
  assert_eq(
    @format.to_iso8601_period(@core.Period::new(years=-1, days=-3)),
    "-P1Y3D",
  )
}

///|
test "to_iso8601_period gives each component its own sign when signs are mixed" {
  assert_eq(
    @format.to_iso8601_period(@core.Period::new(years=-1, days=3)),
    "P-1Y3D",
  )
  assert_eq(
    @format.to_iso8601_period(@core.Period::new(years=1, months=-2, days=3)),
    "P1Y-2M3D",
  )
}

///|
test "to_iso8601_period writes the most negative component without overflow" {
  assert_eq(
    @format.to_iso8601_period(@core.Period::new(years=-2147483648)),
    "-P2147483648Y",
  )
}

///|
test "parse_iso8601_period reads each calendar designator" {
  assert_eq(iso_period("P1Y2M3D"), @core.Period::new(years=1, months=2, days=3))
  assert_eq(iso_period("P1Y"), @core.Period::new(years=1))
  assert_eq(iso_period("P2M"), @core.Period::new(months=2))
  assert_eq(iso_period("P3D"), @core.Period::new(days=3))
  assert_eq(iso_period("P1Y3D"), @core.Period::new(years=1, days=3))
  assert_eq(iso_period("P1M3D"), @core.Period::new(months=1, days=3))
}

///|
test "parse_iso8601_period reads zero components as the zero period" {
  assert_eq(iso_period("P0D"), @core.Period::zero())
  assert_eq(iso_period("P0Y0M0D"), @core.Period::zero())
  assert_eq(iso_period("-P0D"), @core.Period::zero())
}

///|
test "parse_iso8601_period keeps components as given without normalizing" {
  assert_eq(iso_period("P14M"), @core.Period::new(months=14))
  assert_eq(iso_period("P400D"), @core.Period::new(days=400))
}

///|
test "parse_iso8601_period reads a leading sign as applying to every component" {
  assert_eq(
    iso_period("-P1Y2M3D"),
    @core.Period::new(years=-1, months=-2, days=-3),
  )
  assert_eq(
    iso_period("+P1Y2M3D"),
    @core.Period::new(years=1, months=2, days=3),
  )
}

///|
test "parse_iso8601_period reads a sign written on a single component" {
  assert_eq(iso_period("P-1Y3D"), @core.Period::new(years=-1, days=3))
  assert_eq(
    iso_period("P1Y-2M3D"),
    @core.Period::new(years=1, months=-2, days=3),
  )
}

///|
test "parse_iso8601_period rejects a plus sign written on a component" {
  assert_invalid_iso_period("P+1Y")
  assert_invalid_iso_period("P1Y+2M")
  assert_invalid_iso_period("+P+1Y")
}

///|
test "parse_iso8601_period reads back every combination of component extremes" {
  let values = [0, 1, -1, 2147483647, -2147483648]
  for years in values {
    for months in values {
      for days in values {
        let period = @core.Period::new(years~, months~, days~)
        assert_eq(iso_period(@format.to_iso8601_period(period)), period)
        assert_eq(iso_period(period.to_string()), period)
      }
    }
  }
}

///|
test "parse_iso8601_period reads the output of to_iso8601_period back unchanged" {
  let samples = [
    @core.Period::zero(),
    @core.Period::new(years=1, months=2, days=3),
    @core.Period::new(years=-1, months=-2, days=-3),
    @core.Period::new(years=-1, days=3),
    @core.Period::new(years=1, months=-2, days=3),
    @core.Period::new(months=14),
    @core.Period::new(years=2147483647, months=2147483647, days=2147483647),
    @core.Period::new(years=-2147483648, months=-2147483648, days=-2147483648),
    @core.Period::new(years=-2147483648, days=2147483647),
  ]
  for period in samples {
    assert_eq(iso_period(@format.to_iso8601_period(period)), period)
  }
}

///|
test "parse_iso8601_period reads the Show output of a period back unchanged" {
  let samples = [
    @core.Period::zero(),
    @core.Period::new(years=1, months=2, days=3),
    @core.Period::new(years=-1, days=3),
    @core.Period::new(years=-1, months=-2, days=-3),
    @core.Period::new(years=1, months=-2, days=3),
  ]
  for period in samples {
    assert_eq(iso_period(period.to_string()), period)
  }
}

///|
test "parse_iso8601_period accepts the extreme Int32 components" {
  assert_eq(iso_period("P2147483647Y"), @core.Period::new(years=2147483647))
  assert_eq(iso_period("P-2147483648M"), @core.Period::new(months=-2147483648))
  assert_eq(iso_period("-P2147483648D"), @core.Period::new(days=-2147483648))
}

///|
test "parse_iso8601_period rejects a component outside the Int32 range" {
  assert_invalid_iso_period("P2147483648Y")
  assert_invalid_iso_period("P-2147483649M")
  assert_invalid_iso_period("-P2147483649D")
  assert_invalid_iso_period("+P2147483648D")
  assert_invalid_iso_period("P99999999999999999999D")
}

///|
test "parse_iso8601_period rejects text without the P designator" {
  assert_invalid_iso_period("")
  assert_invalid_iso_period("1Y")
  assert_invalid_iso_period("p1Y")
  assert_invalid_iso_period("-")
  assert_invalid_iso_period("+")
}

///|
test "parse_iso8601_period rejects a period with no component" {
  assert_invalid_iso_period("P")
  assert_invalid_iso_period("-P")
  assert_invalid_iso_period("+P")
}

///|
test "parse_iso8601_period rejects designators out of order or repeated" {
  assert_invalid_iso_period("P3D1Y")
  assert_invalid_iso_period("P1M1Y")
  assert_invalid_iso_period("P1D2M")
  assert_invalid_iso_period("P1Y1Y")
  assert_invalid_iso_period("P1D1D")
}

///|
test "parse_iso8601_period rejects lower-case designators and unknown units" {
  assert_invalid_iso_period("P1y")
  assert_invalid_iso_period("P1m")
  assert_invalid_iso_period("P1d")
  assert_invalid_iso_period("P1H")
  assert_invalid_iso_period("P1S")
}

///|
test "parse_iso8601_period rejects a number without a designator" {
  assert_invalid_iso_period("P1")
  assert_invalid_iso_period("P1Y2")
  assert_invalid_iso_period("PY")
  assert_invalid_iso_period("P1YM")
}

///|
test "parse_iso8601_period rejects the time part, which belongs to TimeDelta" {
  assert_invalid_iso_period("PT1H")
  assert_invalid_iso_period("P1Y2M3DT4H")
  assert_invalid_iso_period("P1DT")
  assert_invalid_iso_period("PT")
}

///|
test "parse_iso8601_period rejects week designators and fractions" {
  assert_invalid_iso_period("P2W")
  assert_invalid_iso_period("P1.5Y")
  assert_invalid_iso_period("P1,5M")
  assert_invalid_iso_period("P0.5D")
}

///|
test "parse_iso8601_period rejects a leading sign combined with a component sign" {
  assert_invalid_iso_period("-P-1Y")
  assert_invalid_iso_period("+P-1Y")
  assert_invalid_iso_period("-P1Y-2M")
}

///|
test "parse_iso8601_period rejects misplaced signs and stray characters" {
  assert_invalid_iso_period("P--1Y")
  assert_invalid_iso_period("P-Y")
  assert_invalid_iso_period("P1Y-")
  assert_invalid_iso_period("--P1Y")
  assert_invalid_iso_period(" P1Y")
  assert_invalid_iso_period("P1Y ")
  assert_invalid_iso_period("P1Y2M3Dx")
  assert_invalid_iso_period("P 1Y")
}

///|
test "parse_iso8601_duration still rejects calendar designators" {
  try @format.parse_iso8601_duration("P1Y2M3D") |> ignore catch {
    @format.InvalidDuration => ()
    _ => fail("expected InvalidDuration")
  } noraise {
    _ => fail("expected InvalidDuration")
  }
}
