///|
test "next is strictly after the given instant" {
  let cron = @cron.Cron::parse("0 12 * * *")
  assert_eq(
    cron.next(utc_at(2024, 3, 5, 12, 0, 0)),
    Some(utc_at(2024, 3, 6, 12, 0, 0)),
  )
  assert_eq(
    cron.next(utc_at(2024, 3, 5, 11, 59, 59)),
    Some(utc_at(2024, 3, 5, 12, 0, 0)),
  )
}

///|
test "next finds the following step within the hour" {
  assert_eq(
    @cron.Cron::parse("*/15 * * * *").next(utc_at(2024, 3, 5, 10, 7, 30)),
    Some(utc_at(2024, 3, 5, 10, 15, 0)),
  )
}

///|
test "next steps seconds in a six-field expression" {
  assert_eq(
    @cron.Cron::parse("*/20 * * * * *").next(utc_at(2024, 3, 5, 10, 0, 50)),
    Some(utc_at(2024, 3, 5, 10, 1, 0)),
  )
}

///|
test "next skips a fractional second of the given instant" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms_nano(12, 0, 0, 500_000_000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(
    @cron.Cron::parse("* * * * * *").next(dt),
    Some(utc_at(2024, 3, 5, 12, 0, 1)),
  )
}

///|
test "next rolls over month and year boundaries" {
  assert_eq(
    @cron.Cron::parse("0 0 1 1 *").next(utc_at(2024, 3, 5, 0, 0, 0)),
    Some(utc_at(2025, 1, 1, 0, 0, 0)),
  )
  assert_eq(
    @cron.Cron::parse("0 0 1 * *").next(utc_at(2024, 12, 31, 23, 59, 59)),
    Some(utc_at(2025, 1, 1, 0, 0, 0)),
  )
}

///|
test "next lands on a leap day, skipping a century year that is not leap" {
  let cron = @cron.Cron::parse("0 0 29 2 *")
  assert_eq(
    cron.next(utc_at(2025, 1, 1, 0, 0, 0)),
    Some(utc_at(2028, 2, 29, 0, 0, 0)),
  )
  assert_eq(
    cron.next(utc_at(2096, 3, 1, 0, 0, 0)),
    Some(utc_at(2104, 2, 29, 0, 0, 0)),
  )
}

///|
test "next finds a rare combination decades away" {
  assert_eq(
    @cron.Cron::parse("0 0 29 2 */7").next(utc_at(2089, 1, 1, 0, 0, 0)),
    Some(utc_at(2128, 2, 29, 0, 0, 0)),
  )
}

///|
test "next returns None for a day that never exists" {
  assert_eq(
    @cron.Cron::parse("0 0 30 2 *").next(utc_at(2024, 1, 1, 0, 0, 0)),
    None,
  )
  assert_eq(
    @cron.Cron::parse("0 0 31 4 *").next(utc_at(2024, 1, 1, 0, 0, 0)),
    None,
  )
}

///|
test "next returns None when the search leaves the representable dates" {
  let far = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(5_000_000, 1, 1).unwrap(),
      @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@cron.Cron::parse("0 0 30 2 *").next(far), None)
}

///|
test "next keeps the zone of the given value" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let next = @cron.Cron::parse("0 12 * * *")
    .next(utc_at(2024, 3, 5, 4, 0, 0).with_timezone(tokyo))
    .unwrap()
  assert_eq(next.offset(), tokyo)
  assert_eq(next.with_timezone(@tz.Utc::new()), utc_at(2024, 3, 6, 3, 0, 0))
}

///|
test "a fire time inside a spring-forward gap is skipped" {
  let cron = @cron.Cron::parse("30 2 * * *")
  assert_eq(
    cron.next(new_york_at(2024, 3, 9, 12, 0, 0)).unwrap(),
    new_york_at(2024, 3, 11, 2, 30, 0),
  )
}

///|
test "an hourly fire time inside a gap is skipped to the next valid hour" {
  assert_eq(
    @cron.Cron::parse("0 * * * *")
    .next(new_york_at(2024, 3, 10, 1, 30, 0))
    .unwrap(),
    new_york_at(2024, 3, 10, 3, 0, 0),
  )
}

///|
test "a fire time inside a fall-back fold fires once, at the earlier occurrence" {
  let cron = @cron.Cron::parse("30 1 * * *")
  let first = cron.next(new_york_at(2024, 11, 2, 12, 0, 0)).unwrap()
  assert_eq(first, new_york_utc(2024, 11, 3, 5, 30, 0))
  assert_eq(cron.next(first).unwrap(), new_york_at(2024, 11, 4, 1, 30, 0))
}

///|
test "next never returns an instant at or before the given one inside a fold" {
  let cron = @cron.Cron::parse("30 1 * * *")
  let second_pass = new_york_utc(2024, 11, 3, 6, 10, 0)
  assert_eq(cron.next(second_pass).unwrap(), new_york_at(2024, 11, 4, 1, 30, 0))
}

///|
test "an hourly expression skips the repeated hour of a fold" {
  let cron = @cron.Cron::parse("0 * * * *")
  assert_eq(
    cron.next(new_york_utc(2024, 11, 3, 5, 10, 0)).unwrap(),
    new_york_utc(2024, 11, 3, 7, 0, 0),
  )
}

///|
fn last_representable_day() -> @tz.DateTime[@tz.Utc] {
  @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_epoch_days(2146764179).unwrap(),
      @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
}

///|
test "next returns None when the next matching month lies past the last representable date" {
  assert_eq(@cron.Cron::parse("0 0 1 1 *").next(last_representable_day()), None)
}

///|
test "next returns None when the next matching day lies past the last representable date" {
  assert_eq(@cron.Cron::parse("0 0 * * *").next(last_representable_day()), None)
}
