///|
test "new composes a date and time whose accessors report them back" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 15).unwrap()
  let time = @core.NaiveTime::from_hms(9, 30, 0).unwrap()
  let dt = @core.NaiveDateTime::new(date, time)
  assert_eq(dt.date(), date)
  assert_eq(dt.time(), time)
}

///|
test "from_timestamp at the Unix epoch round-trips through timestamp" {
  let dt = @core.NaiveDateTime::from_timestamp(0L, 0).unwrap()
  assert_eq(dt.date(), @core.NaiveDate::from_ymd(1970, 1, 1).unwrap())
  assert_eq(dt.time(), @core.NaiveTime::from_hms(0, 0, 0).unwrap())
  assert_eq(dt.timestamp(), 0L)
}

///|
test "from_timestamp round-trips through timestamp for positive and negative instants" {
  for secs in [1_700_000_000L, -1_700_000_000L, 86399L, -86400L] {
    let dt = @core.NaiveDateTime::from_timestamp(secs, 0).unwrap()
    assert_eq(dt.timestamp(), secs)
  }
}

///|
test "from_timestamp with a nanosecond component round-trips through timestamp_subsec_nanos" {
  let dt = @core.NaiveDateTime::from_timestamp(1_700_000_000L, 123_456_789).unwrap()
  assert_eq(dt.timestamp_subsec_nanos(), 123_456_789)
  assert_eq(dt.timestamp_subsec_millis(), 123)
  assert_eq(dt.timestamp_subsec_micros(), 123_456)
}

///|
test "from_timestamp rejects a nanosecond value outside 0..=1_999_999_999" {
  assert_eq(@core.NaiveDateTime::from_timestamp(0L, -1), None)
  assert_eq(@core.NaiveDateTime::from_timestamp(0L, 2_000_000_000), None)
}

///|
test "from_timestamp_millis, from_timestamp_micros, and from_timestamp_nanos agree on the same instant" {
  let from_millis = @core.NaiveDateTime::from_timestamp_millis(
    1_700_000_000_123L,
  ).unwrap()
  let from_micros = @core.NaiveDateTime::from_timestamp_micros(
    1_700_000_000_123_000L,
  ).unwrap()
  let from_nanos = @core.NaiveDateTime::from_timestamp_nanos(
    1_700_000_000_123_000_000L,
  ).unwrap()
  assert_eq(from_millis, from_micros)
  assert_eq(from_millis, from_nanos)
  assert_eq(from_millis.timestamp_subsec_millis(), 123)
}

///|
test "from_timestamp_millis, micros, and nanos round-trip a negative sub-second instant" {
  let dt = @core.NaiveDateTime::from_timestamp_millis(-500L).unwrap()
  assert_eq(dt.timestamp(), -1L)
  assert_eq(dt.timestamp_subsec_millis(), 500)
}

///|
test "timestamp_millis stays total for a date far from the epoch, while timestamp_micros and timestamp_nanos report None" {
  let far_date = @core.NaiveDate::from_ymd(1970, 1, 1)
    .unwrap()
    .add_days(2_000_000_000)
  let dt = @core.NaiveDateTime::new(
    far_date,
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  assert_eq(dt.timestamp_millis(), dt.timestamp() * 1000L)
  assert_true(dt.timestamp_micros() is None)
  assert_true(dt.timestamp_nanos() is None)
}

///|
test "timestamp_micros and timestamp_nanos round-trip for a date near the epoch" {
  let dt = @core.NaiveDateTime::from_timestamp(1_700_000_000L, 123_456_789).unwrap()
  assert_eq(dt.timestamp_micros(), Some(1_700_000_000_123_456L))
  assert_eq(dt.timestamp_nanos(), Some(1_700_000_000_123_456_789L))
}

///|
test "add_signed crosses a day boundary forward and reports the wrapped time" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(23, 0, 0).unwrap(),
  )
  let result = dt.add_signed(@core.TimeDelta::hours(2L).unwrap())
  assert_eq(result.date(), @core.NaiveDate::from_ymd(2024, 3, 16).unwrap())
  assert_eq(result.time(), @core.NaiveTime::from_hms(1, 0, 0).unwrap())
}

///|
test "sub_signed crosses a day boundary backward and reports the wrapped time" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(1, 0, 0).unwrap(),
  )
  let result = dt.sub_signed(@core.TimeDelta::hours(2L).unwrap())
  assert_eq(result.date(), @core.NaiveDate::from_ymd(2024, 3, 14).unwrap())
  assert_eq(result.time(), @core.NaiveTime::from_hms(23, 0, 0).unwrap())
}

///|
test "add_signed crosses a year boundary when the day rollover lands on January 1st" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2023, 12, 31).unwrap(),
    @core.NaiveTime::from_hms(23, 0, 0).unwrap(),
  )
  let result = dt.add_signed(@core.TimeDelta::hours(2L).unwrap())
  assert_eq(result.date(), @core.NaiveDate::from_ymd(2024, 1, 1).unwrap())
  assert_eq(result.time(), @core.NaiveTime::from_hms(1, 0, 0).unwrap())
}

///|
test "add_months and sub_months shift the date while keeping the time of day" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 31).unwrap(),
    @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
  )
  let forward = dt.add_months(1)
  assert_eq(forward.date(), @core.NaiveDate::from_ymd(2024, 2, 29).unwrap())
  assert_eq(forward.time(), dt.time())
  let back = forward.sub_months(1)
  assert_eq(back.date(), @core.NaiveDate::from_ymd(2024, 1, 29).unwrap())
  assert_eq(back.time(), dt.time())
}

///|
test "add_days and sub_days shift the date while keeping the time of day" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
  )
  let forward = dt.add_days(10)
  assert_eq(forward.date(), @core.NaiveDate::from_ymd(2024, 3, 25).unwrap())
  assert_eq(forward.time(), dt.time())
  assert_eq(forward.sub_days(10), dt)
}

///|
test "signed_duration_since reports zero for a datetime against itself" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
  )
  assert_true(dt.signed_duration_since(dt).is_zero())
}

///|
test "signed_duration_since measures the elapsed duration between two datetimes" {
  let earlier = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
  )
  let later = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 16).unwrap(),
    @core.NaiveTime::from_hms(10, 30, 0).unwrap(),
  )
  assert_eq(
    later.signed_duration_since(earlier),
    @core.TimeDelta::hours(25L)
    .unwrap()
    .add(@core.TimeDelta::minutes(30L).unwrap())
    .unwrap(),
  )
}

///|
test "signed_duration_since is antisymmetric: a since b is the negation of b since a" {
  let a = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
  )
  let b = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 1).unwrap(),
    @core.NaiveTime::from_hms(3, 15, 45).unwrap(),
  )
  assert_eq(a.signed_duration_since(b), b.signed_duration_since(a).neg())
}

///|
test "truncate rounds a datetime after the Unix epoch down to a whole-hour granularity" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 45, 30).unwrap(),
  )
  let truncated = dt.truncate(@core.TimeDelta::hours(1L).unwrap()).unwrap()
  assert_eq(truncated.date(), dt.date())
  assert_eq(truncated.time(), @core.NaiveTime::from_hms(9, 0, 0).unwrap())
}

///|
test "truncate rounds a datetime before the Unix epoch forward, toward the epoch rather than toward negative infinity" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(1969, 12, 31).unwrap(),
    @core.NaiveTime::from_hms(14, 45, 30).unwrap(),
  )
  let truncated = dt.truncate(@core.TimeDelta::hours(1L).unwrap()).unwrap()
  assert_eq(truncated.date(), dt.date())
  assert_eq(truncated.time(), @core.NaiveTime::from_hms(15, 0, 0).unwrap())
}

///|
test "round breaks an exact tie by moving away from the Unix epoch" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  let rounded = dt.round(@core.TimeDelta::hours(1L).unwrap()).unwrap()
  assert_eq(rounded.date(), dt.date())
  assert_eq(rounded.time(), @core.NaiveTime::from_hms(10, 0, 0).unwrap())
}

///|
test "round and truncate collapse to the Unix epoch when the granularity exceeds the datetime's distance from it" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(1970, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 30).unwrap(),
  )
  let day = @core.TimeDelta::days(1L).unwrap()
  let epoch = @core.NaiveDateTime::from_timestamp(0L, 0).unwrap()
  assert_eq(dt.truncate(day), Some(epoch))
  assert_eq(dt.round(day), Some(epoch))
}

///|
test "round and truncate reject an unsupported granularity that mixes whole seconds with a sub-second remainder" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
  let mixed = @core.TimeDelta::milliseconds(1500L).unwrap()
  assert_eq(dt.round(mixed), None)
  assert_eq(dt.truncate(mixed), None)
}

///|
test "a datetime on a later date compares greater regardless of time of day" {
  let d1 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(23, 0, 0).unwrap(),
  )
  let d2 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 2).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  assert_true(d1 < d2)
  assert_true(d2 > d1)
  assert_true(d1.compare(d2) < 0)
}

///|
test "a datetime on the same date compares by time of day" {
  let d1 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
  )
  let d2 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(17, 0, 0).unwrap(),
  )
  assert_true(d1 < d2)
}

///|
test "equal datetimes compare as neither less nor greater" {
  let d1 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
  )
  let d2 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
  )
  assert_true(d1 <= d2)
  assert_true(d1 >= d2)
  assert_eq(d1.compare(d2), 0)
}

///|
test "signed_duration_since spans the full representable date range without overflow" {
  let limit = 2_147_483_647 - 719_468
  let upper = @core.NaiveDate::from_epoch_days(limit)
    .unwrap()
    .and_hms(0, 0, 0)
    .unwrap()
  let lower = @core.NaiveDate::from_epoch_days(-limit)
    .unwrap()
    .and_hms(0, 0, 0)
    .unwrap()
  assert_eq(
    upper.signed_duration_since(lower),
    @core.TimeDelta::days(2L * limit.to_int64()).unwrap(),
  )
}

///|
fn max_datetime() -> @core.NaiveDateTime {
  @core.NaiveDate::from_epoch_days(2_147_483_647 - 719_468)
  .unwrap()
  .and_hms(23, 59, 59)
  .unwrap()
}

///|
fn min_datetime() -> @core.NaiveDateTime {
  @core.NaiveDate::from_epoch_days(-(2_147_483_647 - 719_468))
  .unwrap()
  .and_hms(0, 0, 0)
  .unwrap()
}

///|
test "checked_add_signed and checked_sub_signed agree with the total versions within range" {
  let dt = @core.NaiveDate::from_ymd(2024, 2, 28)
    .unwrap()
    .and_hms(23, 0, 0)
    .unwrap()
  let delta = @core.TimeDelta::hours(2L).unwrap()
  assert_eq(dt.checked_add_signed(delta), Some(dt.add_signed(delta)))
  assert_eq(dt.checked_sub_signed(delta), Some(dt.sub_signed(delta)))
  assert_eq(
    dt.checked_add_signed(delta),
    @core.NaiveDate::from_ymd(2024, 2, 29).unwrap().and_hms(1, 0, 0),
  )
}

///|
test "checked_add_signed and checked_sub_signed reject a result outside the representable range" {
  let one_second = @core.TimeDelta::seconds(1L).unwrap()
  assert_eq(max_datetime().checked_add_signed(one_second), None)
  assert_eq(min_datetime().checked_sub_signed(one_second), None)
  assert_eq(
    max_datetime().checked_add_signed(@core.TimeDelta::zero()),
    Some(max_datetime()),
  )
}

///|
test "checked_add_signed and checked_sub_signed reject a duration whose day count exceeds the range" {
  let dt = @core.NaiveDate::from_ymd(2024, 2, 28)
    .unwrap()
    .and_hms(0, 0, 0)
    .unwrap()
  assert_eq(dt.checked_add_signed(@core.TimeDelta::max_value()), None)
  assert_eq(dt.checked_add_signed(@core.TimeDelta::min_value()), None)
  assert_eq(dt.checked_sub_signed(@core.TimeDelta::max_value()), None)
  assert_eq(dt.checked_sub_signed(@core.TimeDelta::min_value()), None)
}

///|
test "datetime checked day and month arithmetic keeps the time of day and rejects out-of-range results" {
  let dt = @core.NaiveDate::from_ymd(2024, 1, 31)
    .unwrap()
    .and_hms(8, 30, 0)
    .unwrap()
  assert_eq(
    dt.checked_add_days(1),
    @core.NaiveDate::from_ymd(2024, 2, 1).unwrap().and_hms(8, 30, 0),
  )
  assert_eq(
    dt.checked_sub_days(31),
    @core.NaiveDate::from_ymd(2023, 12, 31).unwrap().and_hms(8, 30, 0),
  )
  assert_eq(
    dt.checked_add_months(1),
    @core.NaiveDate::from_ymd(2024, 2, 29).unwrap().and_hms(8, 30, 0),
  )
  assert_eq(
    dt.checked_sub_months(2),
    @core.NaiveDate::from_ymd(2023, 11, 30).unwrap().and_hms(8, 30, 0),
  )
  assert_eq(max_datetime().checked_add_days(1), None)
  assert_eq(min_datetime().checked_sub_days(1), None)
  assert_eq(max_datetime().checked_add_months(1), None)
  assert_eq(min_datetime().checked_sub_months(1), None)
}

///|
test "from_timestamp rejects a timestamp whose day count is outside the representable range" {
  assert_eq(
    @core.NaiveDateTime::from_timestamp(9_223_372_036_854_775_807L, 0),
    None,
  )
  assert_eq(
    @core.NaiveDateTime::from_timestamp(-9_223_372_036_854_775_807L, 0),
    None,
  )
  let limit = 2_147_483_647L - 719_468L
  assert_true(@core.NaiveDateTime::from_timestamp(limit * 86400L, 0) is Some(_))
  assert_eq(@core.NaiveDateTime::from_timestamp((limit + 1L) * 86400L, 0), None)
  assert_eq(
    @core.NaiveDateTime::from_timestamp((-limit - 1L) * 86400L, 0),
    None,
  )
}

///|
test "panic add_signed aborts when the result leaves the representable range" {
  ignore(max_datetime().add_signed(@core.TimeDelta::seconds(1L).unwrap()))
}

///|
test "panic add_signed aborts on a duration exceeding the day range instead of truncating" {
  ignore(min_datetime().add_signed(@core.TimeDelta::max_value()))
}

///|
test "panic sub_signed aborts when the result leaves the representable range" {
  ignore(min_datetime().sub_signed(@core.TimeDelta::seconds(1L).unwrap()))
}

///|
test "panic datetime add_days aborts when the result leaves the representable range" {
  ignore(max_datetime().add_days(1))
}

///|
test "panic datetime sub_days aborts when the result leaves the representable range" {
  ignore(min_datetime().sub_days(1))
}

///|
test "panic datetime add_months aborts when the result leaves the representable range" {
  ignore(max_datetime().add_months(1))
}

///|
test "panic datetime sub_months aborts when the result leaves the representable range" {
  ignore(min_datetime().sub_months(1))
}

///|
fn sample_datetime() -> @core.NaiveDateTime {
  @core.NaiveDate::from_ymd(2024, 2, 29)
  .unwrap()
  .and_hms_nano(13, 45, 6, 789)
  .unwrap()
}

///|
test "date component accessors report the local calendar fields" {
  let dt = sample_datetime()
  assert_eq(dt.year(), 2024)
  assert_eq(dt.month(), @core.Feb)
  assert_eq(dt.day(), 29)
  assert_eq(dt.ordinal(), 60)
  assert_eq(dt.weekday(), @core.Thu)
  assert_eq(dt.iso_week(), dt.date().iso_week())
  assert_true(dt.leap_year())
}

///|
test "leap_year is false for a common year" {
  let dt = @core.NaiveDate::from_ymd(2023, 6, 1)
    .unwrap()
    .and_hms(0, 0, 0)
    .unwrap()
  assert_false(dt.leap_year())
}

///|
test "time component accessors report the time-of-day fields" {
  let dt = sample_datetime()
  assert_eq(dt.hour(), 13)
  assert_eq(dt.minute(), 45)
  assert_eq(dt.second(), 6)
  assert_eq(dt.nanosecond(), 789)
}

///|
test "with_year replaces the year and keeps every other field" {
  let dt = sample_datetime()
  assert_eq(dt.with_year(2023), None)
  assert_eq(
    dt.with_year(2028),
    @core.NaiveDate::from_ymd(2028, 2, 29).unwrap().and_hms_nano(13, 45, 6, 789),
  )
}

///|
test "with_month and with_day replace one date field and reject impossible dates" {
  let dt = sample_datetime()
  assert_eq(
    dt.with_month(3).map(fn(d) { d.date() }),
    @core.NaiveDate::from_ymd(2024, 3, 29),
  )
  assert_eq(dt.with_month(3).map(fn(d) { d.time() }), Some(dt.time()))
  assert_eq(dt.with_month(13), None)
  assert_eq(
    dt.with_day(1).map(fn(d) { d.date() }),
    @core.NaiveDate::from_ymd(2024, 2, 1),
  )
  assert_eq(dt.with_day(1).map(fn(d) { d.time() }), Some(dt.time()))
  assert_eq(dt.with_day(30), None)
}

///|
test "with_ordinal replaces the day of year and keeps the time of day" {
  let dt = sample_datetime()
  assert_eq(
    dt.with_ordinal(366),
    @core.NaiveDate::from_ymd(2024, 12, 31)
    .unwrap()
    .and_hms_nano(13, 45, 6, 789),
  )
  assert_eq(dt.with_ordinal(367), None)
}

///|
test "with_hour, with_minute and with_second replace one time field and keep the date" {
  let dt = sample_datetime()
  assert_eq(
    dt.with_hour(0).map(fn(d) { d.time() }),
    @core.NaiveTime::from_hms_nano(0, 45, 6, 789),
  )
  assert_eq(
    dt.with_minute(0).map(fn(d) { d.time() }),
    @core.NaiveTime::from_hms_nano(13, 0, 6, 789),
  )
  assert_eq(
    dt.with_second(0).map(fn(d) { d.time() }),
    @core.NaiveTime::from_hms_nano(13, 45, 0, 789),
  )
  assert_eq(dt.with_hour(0).map(fn(d) { d.date() }), Some(dt.date()))
  assert_eq(dt.with_hour(24), None)
  assert_eq(dt.with_minute(60), None)
  assert_eq(dt.with_second(60), None)
}

///|
test "with_nanosecond replaces the sub-second field, including a leap-second value" {
  let dt = sample_datetime()
  assert_eq(dt.with_nanosecond(5).map(fn(d) { d.nanosecond() }), Some(5))
  assert_eq(
    dt.with_nanosecond(1_500_000_000).map(fn(d) { d.nanosecond() }),
    Some(1_500_000_000),
  )
  assert_eq(dt.with_nanosecond(2_000_000_000), None)
  assert_eq(dt.with_nanosecond(5).map(fn(d) { d.date() }), Some(dt.date()))
}

///|
test "with_hour preserves an existing leap-second nanosecond component" {
  let dt = @core.NaiveDate::from_ymd(2016, 12, 31)
    .unwrap()
    .and_hms_nano(23, 59, 59, 1_500_000_000)
    .unwrap()
  assert_eq(dt.with_hour(12).map(fn(d) { d.nanosecond() }), Some(1_500_000_000))
}

///|
test "to_string joins the date and time with a space" {
  assert_eq(
    @core.NaiveDate::from_ymd(2024, 1, 2)
    .unwrap()
    .and_hms(13, 45, 6)
    .unwrap()
    .to_string(),
    "2024-01-02 13:45:06",
  )
  assert_eq(
    @core.NaiveDate::from_ymd(2024, 1, 2)
    .unwrap()
    .and_hms_milli(13, 45, 6, 500)
    .unwrap()
    .to_string(),
    "2024-01-02 13:45:06.500",
  )
  assert_eq(
    @core.NaiveDate::from_ymd(-1, 12, 31)
    .unwrap()
    .and_hms(0, 0, 0)
    .unwrap()
    .to_string(),
    "-0001-12-31 00:00:00",
  )
}

///|
test "equal datetimes hash equally and work as map keys" {
  let a = @core.NaiveDate::from_ymd(2024, 2, 29)
    .unwrap()
    .and_hms(13, 45, 6)
    .unwrap()
  let b = @core.NaiveDate::from_ymd(2024, 2, 28)
    .unwrap()
    .and_hms(13, 45, 6)
    .unwrap()
    .add_days(1)
  assert_eq(a, b)
  assert_eq(a.hash(), b.hash())
  let seen : Map[@core.NaiveDateTime, Int] = Map([])
  seen[a] = 1
  seen[a.add_days(1)] = 2
  assert_eq(seen.length(), 2)
  assert_eq(seen.get(b), Some(1))
}

///|
test "round_up moves a datetime up to the next multiple of the granularity since the epoch" {
  let dt = @core.NaiveDate::from_ymd(2024, 1, 2)
    .unwrap()
    .and_hms_milli(13, 45, 6, 500)
    .unwrap()
  assert_eq(
    dt.round_up(@core.TimeDelta::seconds(1L).unwrap()),
    @core.NaiveDate::from_ymd(2024, 1, 2).unwrap().and_hms(13, 45, 7),
  )
  assert_eq(
    dt.round_up(@core.TimeDelta::hours(1L).unwrap()),
    @core.NaiveDate::from_ymd(2024, 1, 2).unwrap().and_hms(14, 0, 0),
  )
  assert_eq(
    dt.round_up(@core.TimeDelta::days(1L).unwrap()),
    @core.NaiveDate::from_ymd(2024, 1, 3).unwrap().and_hms(0, 0, 0),
  )
}

///|
test "round_up leaves a datetime that already sits on a multiple unchanged" {
  let dt = @core.NaiveDate::from_ymd(2024, 1, 2)
    .unwrap()
    .and_hms(13, 0, 0)
    .unwrap()
  assert_eq(dt.round_up(@core.TimeDelta::hours(1L).unwrap()), Some(dt))
}

///|
test "round_up before the epoch still moves toward positive infinity" {
  let before = @core.NaiveDate::from_ymd(1969, 12, 31)
    .unwrap()
    .and_hms_milli(23, 59, 59, 500)
    .unwrap()
  assert_eq(
    before.round_up(@core.TimeDelta::seconds(1L).unwrap()),
    @core.NaiveDate::from_ymd(1970, 1, 1).unwrap().and_hms(0, 0, 0),
  )
  let earlier = @core.NaiveDate::from_ymd(1969, 12, 31)
    .unwrap()
    .and_hms_milli(23, 0, 0, 100)
    .unwrap()
  assert_eq(
    earlier.round_up(@core.TimeDelta::hours(1L).unwrap()),
    @core.NaiveDate::from_ymd(1970, 1, 1).unwrap().and_hms(0, 0, 0),
  )
}

///|
test "round_up rejects a zero, negative or mixed granularity" {
  let dt = @core.NaiveDate::from_ymd(2024, 1, 2)
    .unwrap()
    .and_hms(13, 45, 6)
    .unwrap()
  assert_eq(dt.round_up(@core.TimeDelta::zero()), None)
  assert_eq(dt.round_up(@core.TimeDelta::seconds(-1L).unwrap()), None)
  assert_eq(dt.round_up(@core.TimeDelta::milliseconds(1_500L).unwrap()), None)
}

///|
test "round_up returns None instead of aborting when the result leaves the representable date range" {
  assert_eq(max_datetime().round_up(@core.TimeDelta::days(1L).unwrap()), None)
  assert_eq(
    max_datetime().round_up(@core.TimeDelta::seconds(1L).unwrap()),
    Some(max_datetime()),
  )
}
