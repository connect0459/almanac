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
