///|
test "the root package re-exports the everyday date and time types" {
  let date = @almanac.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @almanac.NaiveTime::from_hms(9, 5, 7).unwrap()
  let naive = @almanac.NaiveDateTime::new(date, time)
  assert_eq(naive.to_string(), "2024-03-05 09:05:07")
  assert_eq(date.weekday(), @almanac.Weekday::Tue)
  assert_eq(date.month(), @almanac.Month::Mar)
  let delta = @almanac.TimeDelta::hours(1L).unwrap()
  assert_eq(naive.add_signed(delta).hour(), 10)
}

///|
test "the root package re-exports the zone types so a zoned datetime needs no other import" {
  let tokyo = @almanac.FixedOffset::east(9 * 3600).unwrap()
  let dt = @almanac.DateTime::from_timestamp(0L, 0, tokyo).unwrap()
  assert_eq(dt.hour(), 9)
  let utc : @almanac.DateTime[@almanac.Utc] = @almanac.DateTime::unix_epoch()
  assert_eq(dt.with_timezone(@almanac.Utc::new()), utc)
  let ny = @almanac.Location::load("America/New_York").unwrap()
  let resolved : @almanac.MappedLocalTime[@almanac.DateTime[@almanac.Location]] = @almanac.DateTime::from_ymd_hms(
    2024, 7, 1, 12, 0, 0, ny,
  )
  assert_true(resolved.single() is Some(_))
}

///|
test "a calendar period built through the root package shifts a date by months" {
  let date = @almanac.NaiveDate::from_ymd(2024, 1, 31).unwrap()
  let period = @almanac.Period::new(months=1)
  assert_eq(date.add_period(period).to_string(), "2024-02-29")
}

///|
test "the difference between two dates can be received as a root package period" {
  let start = @almanac.NaiveDate::from_ymd(2024, 1, 15).unwrap()
  let end = @almanac.NaiveDate::from_ymd(2024, 3, 20).unwrap()
  let gap : @almanac.Period = start.until(end)
  assert_eq(start.add_period(gap), end)
}
