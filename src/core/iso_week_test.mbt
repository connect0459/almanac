///|
test "iso_week assigns dates near a year boundary to the ISO year owning that week" {
  let cases = [
    (1977, 1, 1, 1976, 53),
    (1978, 1, 1, 1977, 52),
    (1981, 1, 1, 1981, 1),
    (2014, 12, 28, 2014, 52),
    (2014, 12, 29, 2015, 1),
    (2015, 12, 31, 2015, 53),
    (2016, 1, 3, 2015, 53),
    (2016, 1, 4, 2016, 1),
    (2005, 1, 1, 2004, 53),
    (2000, 1, 1, 1999, 52),
  ]
  for case in cases {
    let (year, month, day, iso_year, iso_week) = case
    let week = @core.NaiveDate::from_ymd(year, month, day).unwrap().iso_week()
    assert_eq(week.year(), iso_year)
    assert_eq(week.week(), iso_week)
  }
}

///|
test "week0 is one less than the 1-based week number" {
  let week = @core.NaiveDate::from_ymd(2024, 1, 1).unwrap().iso_week()
  assert_eq(week.week(), 1)
  assert_eq(week.week0(), 0)
}
