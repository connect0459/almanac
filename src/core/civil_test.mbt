///|
test "days_from_civil returns zero for the Unix epoch" {
  assert_eq(@core.days_from_civil(1970, 1, 1), 0)
}

///|
test "civil_from_days returns the Unix epoch for day zero" {
  assert_eq(@core.civil_from_days(0), (1970, 1, 1))
}

///|
test "days_from_civil counts forward across a known 30-year span" {
  assert_eq(@core.days_from_civil(2000, 1, 1), 10957)
}

///|
test "days_from_civil is negative for dates before the Unix epoch" {
  assert_eq(@core.days_from_civil(1969, 12, 31), -1)
}

///|
test "days_from_civil advances by one across a leap-day boundary" {
  let feb29 = @core.days_from_civil(2024, 2, 29)
  let mar1 = @core.days_from_civil(2024, 3, 1)
  assert_eq(mar1 - feb29, 1)
}

///|
test "days_from_civil advances by one across a non-leap-year February boundary" {
  let feb28 = @core.days_from_civil(2023, 2, 28)
  let mar1 = @core.days_from_civil(2023, 3, 1)
  assert_eq(mar1 - feb28, 1)
}

///|
test "civil_from_days round-trips through days_from_civil across a wide year range" {
  for year in [1, 1600, 1900, 1969, 1970, 2000, 2024, 2100, 9999] {
    for month in 1..<=12 {
      for day in [1, 15] {
        assert_eq(
          @core.civil_from_days(@core.days_from_civil(year, month, day)),
          (year, month, day),
        )
      }
    }
  }
}
