///|
test "the root package re-exports the everyday date and time types" {
  let date = @chrono.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @chrono.NaiveTime::from_hms(9, 5, 7).unwrap()
  let naive = @chrono.NaiveDateTime::new(date, time)
  assert_eq(naive.to_string(), "2024-03-05 09:05:07")
  assert_eq(date.weekday(), @chrono.Weekday::Tue)
  assert_eq(date.month(), @chrono.Month::Mar)
  let delta = @chrono.TimeDelta::hours(1L).unwrap()
  assert_eq(naive.add_signed(delta).hour(), 10)
}

///|
test "the root package re-exports the zone types so a zoned datetime needs no other import" {
  let tokyo = @chrono.FixedOffset::east(9 * 3600).unwrap()
  let dt = @chrono.DateTime::from_timestamp(0L, 0, tokyo).unwrap()
  assert_eq(dt.hour(), 9)
  let utc : @chrono.DateTime[@chrono.Utc] = @chrono.DateTime::unix_epoch()
  assert_eq(dt.with_timezone(@chrono.Utc::new()), utc)
  let ny = @chrono.Location::load("America/New_York").unwrap()
  let resolved : @chrono.MappedLocalTime[@chrono.DateTime[@chrono.Location]] = @chrono.DateTime::from_ymd_hms(
    2024, 7, 1, 12, 0, 0, ny,
  )
  assert_true(resolved.single() is Some(_))
}
