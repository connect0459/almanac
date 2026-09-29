///|
test "seconds constructs a duration whose num_seconds reports back the value" {
  let delta = @core.TimeDelta::seconds(90L).unwrap()
  assert_eq(delta.num_seconds(), 90L)
}

///|
test "weeks, days, hours, and minutes construct durations equivalent to their second counts" {
  assert_eq(
    @core.TimeDelta::weeks(1L).unwrap(),
    @core.TimeDelta::seconds(604800L).unwrap(),
  )
  assert_eq(
    @core.TimeDelta::days(1L).unwrap(),
    @core.TimeDelta::seconds(86400L).unwrap(),
  )
  assert_eq(
    @core.TimeDelta::hours(1L).unwrap(),
    @core.TimeDelta::seconds(3600L).unwrap(),
  )
  assert_eq(
    @core.TimeDelta::minutes(1L).unwrap(),
    @core.TimeDelta::seconds(60L).unwrap(),
  )
}

///|
test "milliseconds, microseconds, and nanoseconds normalize a positive sub-second count" {
  assert_eq(@core.TimeDelta::milliseconds(1500L).unwrap().num_seconds(), 1L)
  assert_eq(
    @core.TimeDelta::milliseconds(1500L).unwrap().subsec_nanoseconds(),
    500_000_000,
  )
  assert_eq(
    @core.TimeDelta::microseconds(2_500_000L).unwrap().num_seconds(),
    2L,
  )
  assert_eq(
    @core.TimeDelta::nanoseconds(3_000_000_001L).unwrap().num_seconds(),
    3L,
  )
}

///|
test "nanoseconds normalizes a negative count that crosses a second boundary, truncating toward zero" {
  let delta = @core.TimeDelta::nanoseconds(-1_700_000_000L).unwrap()
  assert_eq(delta.num_seconds(), -1L)
  assert_eq(delta.subsec_nanoseconds(), -700_000_000)
}

///|
test "subsec_milliseconds and subsec_microseconds derive from subsec_nanoseconds" {
  let delta = @core.TimeDelta::nanoseconds(-1_700_000_000L).unwrap()
  assert_eq(delta.subsec_milliseconds(), -700)
  assert_eq(delta.subsec_microseconds(), -700_000)
}

///|
test "constructors reject a total duration exceeding the representable range" {
  assert_eq(@core.TimeDelta::weeks(9_223_372_036_854_775_807L), None)
  assert_eq(@core.TimeDelta::days(9_223_372_036_854_775_807L), None)
  assert_eq(@core.TimeDelta::hours(9_223_372_036_854_775_807L), None)
  assert_eq(@core.TimeDelta::minutes(9_223_372_036_854_775_807L), None)
}

///|
test "mul reports None when combining an overflowing seconds product with the carried nanosecond remainder" {
  // seconds=4_294_967_298, nanoseconds=999_999_999: seconds * scalar alone
  // fits in Int64, but adding the nanosecond remainder's carried seconds
  // overflows past Int64::max_value.
  let delta = @core.TimeDelta::nanoseconds(4_294_967_298_999_999_999L).unwrap()
  assert_eq(delta.mul(2_147_483_647), None)
}

///|
test "mul reports None when the seconds component alone overflows Int64" {
  assert_eq(@core.TimeDelta::max_value().mul(1001), None)
}

///|
test "num_weeks, num_days, num_hours, and num_minutes truncate toward zero" {
  let delta = @core.TimeDelta::seconds(-1_000_000L).unwrap()
  assert_eq(delta.num_weeks(), -1L)
  assert_eq(delta.num_days(), -11L)
  assert_eq(delta.num_hours(), -277L)
  assert_eq(delta.num_minutes(), -16666L)
}

///|
test "num_milliseconds stays total across the full representable range while num_microseconds and num_nanoseconds report None on overflow" {
  let max = @core.TimeDelta::max_value()
  assert_true(max.num_microseconds() is None)
  assert_true(max.num_nanoseconds() is None)
  let one_second = @core.TimeDelta::seconds(1L).unwrap()
  assert_eq(one_second.num_milliseconds(), one_second.num_seconds() * 1000L)
}

///|
test "num_microseconds and num_nanoseconds round-trip within their representable range" {
  let delta = @core.TimeDelta::microseconds(1_234_567L).unwrap()
  assert_eq(delta.num_microseconds(), Some(1_234_567L))
  let delta_nanos = @core.TimeDelta::nanoseconds(1_234_567_891L).unwrap()
  assert_eq(delta_nanos.num_nanoseconds(), Some(1_234_567_891L))
}

///|
test "add and sub perform checked arithmetic, reporting None on overflow past max_value or min_value" {
  let max = @core.TimeDelta::max_value()
  let one_second = @core.TimeDelta::seconds(1L).unwrap()
  assert_eq(max.add(one_second), None)
  let min = @core.TimeDelta::min_value()
  assert_eq(min.sub(one_second), None)
}

///|
test "add and sub are inverse operations for representable durations" {
  let a = @core.TimeDelta::seconds(100L).unwrap()
  let b = @core.TimeDelta::milliseconds(250L).unwrap()
  assert_eq(a.add(b).unwrap().sub(b), Some(a))
}

///|
test "mul and div are inverse operations for exact multiples" {
  let delta = @core.TimeDelta::milliseconds(1500L).unwrap()
  assert_eq(delta.mul(3).unwrap().div(3), Some(delta))
}

///|
test "div rejects division by zero" {
  let delta = @core.TimeDelta::seconds(1L).unwrap()
  assert_eq(delta.div(0), None)
}

///|
test "abs returns a non-negative duration with the same magnitude for positive, negative, and fractional-negative durations" {
  let positive = @core.TimeDelta::seconds(5L).unwrap()
  assert_eq(positive.abs(), positive)
  let negative = @core.TimeDelta::seconds(-5L).unwrap()
  assert_eq(negative.abs(), positive)
  let fractional = @core.TimeDelta::nanoseconds(-1_700_000_000L).unwrap()
  assert_eq(
    fractional.abs(),
    @core.TimeDelta::nanoseconds(1_700_000_000L).unwrap(),
  )
}

///|
test "is_zero reports true only for the zero duration" {
  assert_true(@core.TimeDelta::zero().is_zero())
  assert_true(@core.TimeDelta::seconds(0L).unwrap().is_zero())
  assert_true(@core.TimeDelta::weeks(0L).unwrap().is_zero())
  assert_false(@core.TimeDelta::seconds(1L).unwrap().is_zero())
}

///|
test "min_value and max_value sit exactly one second away from overflow in each direction" {
  let one_second = @core.TimeDelta::seconds(1L).unwrap()
  assert_true(@core.TimeDelta::max_value().add(one_second) is None)
  assert_true(@core.TimeDelta::max_value().sub(one_second) is Some(_))
  assert_true(@core.TimeDelta::min_value().sub(one_second) is None)
  assert_true(@core.TimeDelta::min_value().add(one_second) is Some(_))
}

///|
test "truncate discards a remainder shorter than a whole-second granularity, rounding toward zero" {
  let delta = @core.TimeDelta::seconds(3661L).unwrap()
  let hour = @core.TimeDelta::hours(1L).unwrap()
  assert_eq(delta.truncate(hour), Some(@core.TimeDelta::hours(1L).unwrap()))
}

///|
test "truncate on a negative duration rounds toward zero rather than toward negative infinity" {
  let delta = @core.TimeDelta::seconds(-3661L).unwrap()
  let hour = @core.TimeDelta::hours(1L).unwrap()
  assert_eq(delta.truncate(hour), Some(@core.TimeDelta::hours(-1L).unwrap()))
}

///|
test "truncate discards a sub-second remainder for a sub-second granularity" {
  let delta = @core.TimeDelta::milliseconds(1750L).unwrap()
  let half_second = @core.TimeDelta::milliseconds(500L).unwrap()
  assert_eq(
    delta.truncate(half_second),
    Some(@core.TimeDelta::milliseconds(1500L).unwrap()),
  )
}

///|
test "round breaks an exact half-value tie by moving away from zero, for both positive and negative durations" {
  let hour = @core.TimeDelta::hours(1L).unwrap()
  let half_hour = @core.TimeDelta::minutes(30L).unwrap()
  assert_eq(half_hour.round(hour), Some(hour))
  assert_eq(half_hour.neg().round(hour), Some(hour.neg()))
}

///|
test "round rounds away from zero when a sub-second remainder alone pushes the duration past the half-way point" {
  let hour = @core.TimeDelta::hours(1L).unwrap()
  let just_past_half_hour = @core.TimeDelta::minutes(30L)
    .unwrap()
    .add(@core.TimeDelta::milliseconds(700L).unwrap())
    .unwrap()
  assert_eq(just_past_half_hour.round(hour), Some(hour))
}

///|
test "round truncates toward zero when a sub-second remainder is less than half the granularity" {
  let delta = @core.TimeDelta::milliseconds(1200L).unwrap()
  let half_second = @core.TimeDelta::milliseconds(500L).unwrap()
  assert_eq(
    delta.round(half_second),
    Some(@core.TimeDelta::milliseconds(1000L).unwrap()),
  )
}

///|
test "round rounds away from zero when a sub-second remainder is more than half the granularity" {
  let delta = @core.TimeDelta::milliseconds(1400L).unwrap()
  let half_second = @core.TimeDelta::milliseconds(500L).unwrap()
  assert_eq(
    delta.round(half_second),
    Some(@core.TimeDelta::milliseconds(1500L).unwrap()),
  )
}

///|
test "round breaks an exact sub-second granularity tie by moving away from zero" {
  let delta = @core.TimeDelta::milliseconds(1750L).unwrap()
  let half_second = @core.TimeDelta::milliseconds(500L).unwrap()
  assert_eq(
    delta.round(half_second),
    Some(@core.TimeDelta::milliseconds(2000L).unwrap()),
  )
}

///|
test "round and truncate collapse to zero when the granularity exceeds the duration's own magnitude" {
  let delta = @core.TimeDelta::seconds(30L).unwrap()
  let hour = @core.TimeDelta::hours(1L).unwrap()
  assert_eq(delta.truncate(hour), Some(@core.TimeDelta::zero()))
  assert_eq(delta.round(hour), Some(@core.TimeDelta::zero()))
}

///|
test "round and truncate reject a granularity that mixes a whole-second part with a sub-second remainder" {
  let delta = @core.TimeDelta::seconds(10L).unwrap()
  let mixed = @core.TimeDelta::milliseconds(1500L).unwrap()
  assert_eq(delta.round(mixed), None)
  assert_eq(delta.truncate(mixed), None)
}

///|
test "round and truncate reject a zero or negative granularity" {
  let delta = @core.TimeDelta::seconds(10L).unwrap()
  assert_eq(delta.round(@core.TimeDelta::zero()), None)
  assert_eq(delta.truncate(@core.TimeDelta::zero()), None)
  assert_eq(delta.round(@core.TimeDelta::seconds(-1L).unwrap()), None)
  assert_eq(delta.truncate(@core.TimeDelta::seconds(-1L).unwrap()), None)
}

///|
test "as_seconds_double reports a whole-second duration exactly" {
  assert_eq(@core.TimeDelta::seconds(90L).unwrap().as_seconds_double(), 90.0)
}

///|
test "as_seconds_double reports the fractional part of a positive duration" {
  assert_eq(
    @core.TimeDelta::milliseconds(1500L).unwrap().as_seconds_double(),
    1.5,
  )
}

///|
test "as_seconds_double reports the fractional part of a negative duration" {
  assert_eq(
    @core.TimeDelta::milliseconds(-1750L).unwrap().as_seconds_double(),
    -1.75,
  )
}

///|
test "as_seconds_double is zero for the zero duration" {
  assert_eq(@core.TimeDelta::zero().as_seconds_double(), 0.0)
}

///|
test "as_seconds_float reports a whole-second duration exactly" {
  assert_eq(@core.TimeDelta::seconds(90L).unwrap().as_seconds_float(), 90.0)
}

///|
test "as_seconds_float reports the fractional part of a positive duration" {
  assert_eq(
    @core.TimeDelta::milliseconds(1500L).unwrap().as_seconds_float(),
    1.5,
  )
}

///|
test "as_seconds_float reports the fractional part of a negative duration" {
  assert_eq(
    @core.TimeDelta::milliseconds(-1250L).unwrap().as_seconds_float(),
    -1.25,
  )
}

///|
test "as_seconds_float is zero for the zero duration" {
  assert_eq(@core.TimeDelta::zero().as_seconds_float(), 0.0)
}

///|
test "a longer duration compares greater than a shorter one" {
  let d1 = @core.TimeDelta::seconds(5L).unwrap()
  let d2 = @core.TimeDelta::seconds(10L).unwrap()
  assert_true(d1 < d2)
  assert_true(d2 > d1)
  assert_true(d1.compare(d2) < 0)
}

///|
test "a negative duration compares less than a positive one" {
  let neg = @core.TimeDelta::seconds(-5L).unwrap()
  let pos = @core.TimeDelta::seconds(5L).unwrap()
  assert_true(neg < pos)
}

///|
test "sub-second precision is reflected in ordering for negative durations" {
  let more_negative = @core.TimeDelta::milliseconds(-900L).unwrap()
  let less_negative = @core.TimeDelta::milliseconds(-100L).unwrap()
  assert_true(more_negative < less_negative)
}

///|
test "equal durations compare as neither less nor greater" {
  let d1 = @core.TimeDelta::seconds(5L).unwrap()
  let d2 = @core.TimeDelta::seconds(5L).unwrap()
  assert_true(d1 <= d2)
  assert_true(d1 >= d2)
  assert_eq(d1.compare(d2), 0)
}

///|
test "to_string renders a zero duration as 0s" {
  assert_eq(@core.TimeDelta::zero().to_string(), "0s")
}

///|
test "to_string renders sub-second durations in the largest unit that keeps the integer part nonzero" {
  assert_eq(@core.TimeDelta::nanoseconds(1L).unwrap().to_string(), "1ns")
  assert_eq(@core.TimeDelta::nanoseconds(999L).unwrap().to_string(), "999ns")
  assert_eq(@core.TimeDelta::microseconds(1L).unwrap().to_string(), "1us")
  assert_eq(@core.TimeDelta::nanoseconds(1_500L).unwrap().to_string(), "1.5us")
  assert_eq(@core.TimeDelta::milliseconds(1L).unwrap().to_string(), "1ms")
  assert_eq(@core.TimeDelta::microseconds(1_500L).unwrap().to_string(), "1.5ms")
  assert_eq(
    @core.TimeDelta::nanoseconds(999_999_999L).unwrap().to_string(),
    "999.999999ms",
  )
  assert_eq(@core.TimeDelta::milliseconds(300L).unwrap().to_string(), "300ms")
}

///|
test "to_string renders durations of a second or more with an s suffix and a trimmed fraction" {
  assert_eq(@core.TimeDelta::seconds(1L).unwrap().to_string(), "1s")
  assert_eq(@core.TimeDelta::milliseconds(1_500L).unwrap().to_string(), "1.5s")
  assert_eq(@core.TimeDelta::seconds(59L).unwrap().to_string(), "59s")
  assert_eq(
    @core.TimeDelta::nanoseconds(59_999_999_999L).unwrap().to_string(),
    "59.999999999s",
  )
  assert_eq(
    @core.TimeDelta::nanoseconds(1_000_000_001L).unwrap().to_string(),
    "1.000000001s",
  )
}

///|
test "to_string includes minutes and hours, keeping zero components between them" {
  assert_eq(@core.TimeDelta::minutes(1L).unwrap().to_string(), "1m0s")
  assert_eq(@core.TimeDelta::seconds(61L).unwrap().to_string(), "1m1s")
  assert_eq(@core.TimeDelta::hours(1L).unwrap().to_string(), "1h0m0s")
  assert_eq(@core.TimeDelta::seconds(3_723L).unwrap().to_string(), "1h2m3s")
  assert_eq(
    @core.TimeDelta::milliseconds(3_723_500L).unwrap().to_string(),
    "1h2m3.5s",
  )
  assert_eq(@core.TimeDelta::seconds(3_601L).unwrap().to_string(), "1h0m1s")
}

///|
test "to_string uses hours as the largest unit without introducing days" {
  assert_eq(@core.TimeDelta::hours(100L).unwrap().to_string(), "100h0m0s")
  assert_eq(@core.TimeDelta::days(2L).unwrap().to_string(), "48h0m0s")
}

///|
test "to_string prefixes a negative duration with a minus sign" {
  assert_eq(
    @core.TimeDelta::milliseconds(-1_500L).unwrap().to_string(),
    "-1.5s",
  )
  assert_eq(@core.TimeDelta::hours(-1L).unwrap().to_string(), "-1h0m0s")
  assert_eq(@core.TimeDelta::milliseconds(-300L).unwrap().to_string(), "-300ms")
  assert_eq(@core.TimeDelta::nanoseconds(-1L).unwrap().to_string(), "-1ns")
}

///|
test "to_string renders the extreme representable durations" {
  assert_eq(
    @core.TimeDelta::max_value().to_string(),
    "2562047788015h12m54.999999999s",
  )
  assert_eq(@core.TimeDelta::min_value().to_string(), "-2562047788015h12m54s")
}

///|
test "milliseconds represents a duration far beyond what a nanosecond count could hold" {
  assert_eq(
    @core.TimeDelta::milliseconds(10_000_000_000_000L),
    @core.TimeDelta::seconds(10_000_000_000L),
  )
  assert_eq(
    @core.TimeDelta::milliseconds(-10_000_000_000_000L),
    @core.TimeDelta::seconds(-10_000_000_000L),
  )
}

///|
test "milliseconds round-trips through num_milliseconds across the representable range" {
  for
    n in [
      0L, 1L, -1L, 1_500L, -1_500L, 10_000_000_000_000L, -10_000_000_000_000L, 9_223_372_036_854_774_999L,
      -9_223_372_036_854_774_000L,
    ] {
    assert_eq(
      @core.TimeDelta::milliseconds(n).map(fn(d) { d.num_milliseconds() }),
      Some(n),
    )
  }
}

///|
test "milliseconds rejects a count whose seconds exceed the representable range" {
  assert_eq(@core.TimeDelta::milliseconds(9_223_372_036_854_775_807L), None)
  assert_eq(@core.TimeDelta::milliseconds(9_223_372_036_854_775_000L), None)
  assert_eq(@core.TimeDelta::milliseconds(-9_223_372_036_854_775_807L), None)
  assert_eq(
    @core.TimeDelta::milliseconds(-9_223_372_036_854_775_807L - 1L),
    None,
  )
}

///|
test "microseconds represents a duration beyond a nanosecond count's range" {
  assert_eq(
    @core.TimeDelta::microseconds(10_000_000_000_000_000L),
    @core.TimeDelta::seconds(10_000_000_000L),
  )
  assert_eq(
    @core.TimeDelta::microseconds(-10_000_000_000_000_000L),
    @core.TimeDelta::seconds(-10_000_000_000L),
  )
}

///|
test "microseconds accepts every Int64 count and preserves its value" {
  for
    n in [
      0L,
      1L,
      -1L,
      1_500L,
      -1_500L,
      9_223_372_036_854_775_807L,
      -9_223_372_036_854_775_807L - 1L,
    ] {
    assert_eq(
      @core.TimeDelta::microseconds(n).map(fn(d) { d.num_microseconds() }),
      Some(Some(n)),
    )
  }
}

///|
test "new builds a duration from whole seconds and a nanosecond remainder" {
  let delta = @core.TimeDelta::new(3L, 500_000_000).unwrap()
  assert_eq(delta, @core.TimeDelta::milliseconds(3_500L).unwrap())
  assert_eq(@core.TimeDelta::new(0L, 0), Some(@core.TimeDelta::zero()))
}

///|
test "new carries the sign entirely in the seconds component" {
  assert_eq(
    @core.TimeDelta::new(-1L, 500_000_000),
    @core.TimeDelta::milliseconds(-500L),
  )
  assert_eq(@core.TimeDelta::new(-2L, 0), @core.TimeDelta::seconds(-2L))
}

///|
test "new rejects a nanosecond count outside 0..=999_999_999" {
  assert_eq(@core.TimeDelta::new(0L, 1_000_000_000), None)
  assert_eq(@core.TimeDelta::new(1L, 2_000_000_000), None)
  assert_eq(@core.TimeDelta::new(0L, -1), None)
  assert_eq(@core.TimeDelta::new(1L, -1_000_000_000), None)
  assert_true(@core.TimeDelta::new(0L, 999_999_999) is Some(_))
}

///|
test "new accepts the extreme representable durations and rejects seconds beyond them" {
  assert_eq(
    @core.TimeDelta::new(9_223_372_036_854_774L, 999_999_999),
    Some(@core.TimeDelta::max_value()),
  )
  assert_eq(
    @core.TimeDelta::new(-9_223_372_036_854_774L, 0),
    Some(@core.TimeDelta::min_value()),
  )
  assert_eq(@core.TimeDelta::new(9_223_372_036_854_775L, 0), None)
  assert_eq(@core.TimeDelta::new(-9_223_372_036_854_775L, 0), None)
}

///|
test "new round-trips through num_seconds and subsec_nanoseconds for a positive duration" {
  let delta = @core.TimeDelta::new(12L, 345_678_901).unwrap()
  assert_eq(delta.num_seconds(), 12L)
  assert_eq(delta.subsec_nanoseconds(), 345_678_901)
}

///|
test "as_hours_double reports fractional hours" {
  assert_eq(@core.TimeDelta::seconds(5_400L).unwrap().as_hours_double(), 1.5)
  assert_eq(@core.TimeDelta::hours(2L).unwrap().as_hours_double(), 2.0)
  assert_eq(@core.TimeDelta::seconds(-5_400L).unwrap().as_hours_double(), -1.5)
  assert_eq(@core.TimeDelta::zero().as_hours_double(), 0.0)
}

///|
test "as_minutes_double reports fractional minutes" {
  assert_eq(@core.TimeDelta::seconds(90L).unwrap().as_minutes_double(), 1.5)
  assert_eq(@core.TimeDelta::minutes(3L).unwrap().as_minutes_double(), 3.0)
  assert_eq(@core.TimeDelta::seconds(-90L).unwrap().as_minutes_double(), -1.5)
  assert_eq(@core.TimeDelta::zero().as_minutes_double(), 0.0)
}

///|
test "as_hours_double and as_minutes_double include the sub-second part" {
  let delta = @core.TimeDelta::milliseconds(1_800_000L + 500L).unwrap()
  assert_true((delta.as_minutes_double() - 30.008333333333333).abs() < 1.0e-9)
  assert_true((delta.as_hours_double() - 0.5001388888888889).abs() < 1.0e-12)
}

///|
test "as_hours_double and as_minutes_double stay finite for the extreme durations" {
  assert_true(@core.TimeDelta::max_value().as_hours_double() > 2.5e12)
  assert_true(@core.TimeDelta::min_value().as_hours_double() < -2.5e12)
  assert_true(@core.TimeDelta::max_value().as_minutes_double() > 1.5e14)
}

///|
test "as_hours_float and as_minutes_float report fractional values" {
  assert_eq(@core.TimeDelta::seconds(5_400L).unwrap().as_hours_float(), 1.5)
  assert_eq(@core.TimeDelta::seconds(-5_400L).unwrap().as_hours_float(), -1.5)
  assert_eq(@core.TimeDelta::seconds(90L).unwrap().as_minutes_float(), 1.5)
  assert_eq(@core.TimeDelta::seconds(-90L).unwrap().as_minutes_float(), -1.5)
  assert_eq(@core.TimeDelta::zero().as_hours_float(), 0.0)
  assert_eq(@core.TimeDelta::zero().as_minutes_float(), 0.0)
}

///|
test "equal durations hash equally and work as map keys" {
  let a = @core.TimeDelta::milliseconds(1_500L).unwrap()
  let b = @core.TimeDelta::new(1L, 500_000_000).unwrap()
  assert_eq(a, b)
  assert_eq(a.hash(), b.hash())
  let seen : Map[@core.TimeDelta, Int] = Map([])
  seen[a] = 1
  seen[@core.TimeDelta::milliseconds(-1_500L).unwrap()] = 2
  assert_eq(seen.length(), 2)
  assert_eq(seen.get(b), Some(1))
}
