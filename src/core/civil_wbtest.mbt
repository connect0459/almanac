///|
test "days_from_civil returns zero for the Unix epoch" {
  assert_eq(days_from_civil(1970, 1, 1), 0)
}

///|
test "civil_from_days returns the Unix epoch for day zero" {
  assert_eq(civil_from_days(0), (1970, 1, 1))
}

///|
test "days_from_civil counts forward across a known 30-year span" {
  assert_eq(days_from_civil(2000, 1, 1), 10957)
}

///|
test "days_from_civil is negative for dates before the Unix epoch" {
  assert_eq(days_from_civil(1969, 12, 31), -1)
}

///|
test "days_from_civil advances by one across a leap-day boundary" {
  let feb29 = days_from_civil(2024, 2, 29)
  let mar1 = days_from_civil(2024, 3, 1)
  assert_eq(mar1 - feb29, 1)
}

///|
test "days_from_civil advances by one across a non-leap-year February boundary" {
  let feb28 = days_from_civil(2023, 2, 28)
  let mar1 = days_from_civil(2023, 3, 1)
  assert_eq(mar1 - feb28, 1)
}

///|
test "civil_from_days round-trips through days_from_civil across a wide year range" {
  for year in [1, 1600, 1900, 1969, 1970, 2000, 2024, 2100, 9999] {
    for month in 1..<=12 {
      for day in [1, 15] {
        assert_eq(
          civil_from_days(days_from_civil(year, month, day)),
          (year, month, day),
        )
      }
    }
  }
}

///|
test "epoch_days agrees with days_from_civil" {
  for ymd in [(1, 1, 1), (1900, 2, 28), (2000, 2, 29), (2024, 12, 31)] {
    let (y, m, d) = ymd
    assert_eq(
      NaiveDate::from_ymd(y, m, d).unwrap().epoch_days(),
      days_from_civil(y, m, d),
    )
  }
}

///|
test "from_epoch_days agrees with civil_from_days" {
  let (y, m, d) = civil_from_days(19000)
  assert_eq(NaiveDate::from_epoch_days(19000), NaiveDate::from_ymd(y, m, d))
}
