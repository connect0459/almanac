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
