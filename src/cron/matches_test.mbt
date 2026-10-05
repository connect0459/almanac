///|
test "day-of-month and day-of-week are OR-ed when both are restricted" {
  let cron = @cron.Cron::parse("0 0 13 * 5")
  assert_true(cron.matches(utc_at(2024, 9, 6, 0, 0, 0)))
  assert_true(cron.matches(utc_at(2024, 10, 13, 0, 0, 0)))
  assert_false(cron.matches(utc_at(2024, 10, 7, 0, 0, 0)))
}

///|
test "only the day of month applies when the day of week is a star" {
  let cron = @cron.Cron::parse("0 0 13 * *")
  assert_true(cron.matches(utc_at(2024, 10, 13, 0, 0, 0)))
  assert_false(cron.matches(utc_at(2024, 9, 6, 0, 0, 0)))
}

///|
test "only the day of week applies when the day of month is a star" {
  let cron = @cron.Cron::parse("0 0 * * 5")
  assert_true(cron.matches(utc_at(2024, 9, 6, 0, 0, 0)))
  assert_false(cron.matches(utc_at(2024, 10, 13, 0, 0, 0)))
}

///|
test "a stepped star counts as a star, so both day fields must match" {
  let cron = @cron.Cron::parse("0 0 */2 * 5")
  assert_false(cron.matches(utc_at(2024, 9, 6, 0, 0, 0)))
  assert_true(cron.matches(utc_at(2024, 9, 13, 0, 0, 0)))
}

///|
test "a fractional second does not stop a fire time from matching" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms_nano(12, 0, 0, 500_000_000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_true(@cron.Cron::parse("0 0 12 * * *").matches(dt))
}

///|
test "matches reads the wall clock of the value's own zone" {
  let cron = @cron.Cron::parse("0 12 * * *")
  let tokyo = utc_at(2024, 3, 5, 3, 0, 0).with_timezone(
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_true(cron.matches(tokyo))
  assert_false(cron.matches(utc_at(2024, 3, 5, 3, 0, 0)))
}

///|
test "in a fall-back fold only the earlier occurrence matches" {
  let cron = @cron.Cron::parse("30 1 * * *")
  assert_true(cron.matches(new_york_utc(2024, 11, 3, 5, 30, 0)))
  assert_false(cron.matches(new_york_utc(2024, 11, 3, 6, 30, 0)))
}
