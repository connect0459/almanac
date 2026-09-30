///|
test "rounding a duration reports a zero or negative granularity as InvalidGranularity" {
  let delta = @core.TimeDelta::minutes(90L).unwrap()
  assert_eq(delta.round(@core.TimeDelta::zero()), Err(InvalidGranularity))
  assert_eq(delta.truncate(@core.TimeDelta::zero()), Err(InvalidGranularity))
  assert_eq(delta.round_up(@core.TimeDelta::zero()), Err(InvalidGranularity))
  assert_eq(
    delta.round(@core.TimeDelta::seconds(-1L).unwrap()),
    Err(InvalidGranularity),
  )
}

///|
test "rounding a duration reports a granularity mixing seconds and a sub-second part as MixedGranularity" {
  let delta = @core.TimeDelta::minutes(90L).unwrap()
  let mixed = @core.TimeDelta::milliseconds(1_500L).unwrap()
  assert_eq(delta.round(mixed), Err(MixedGranularity))
  assert_eq(delta.truncate(mixed), Err(MixedGranularity))
  assert_eq(delta.round_up(mixed), Err(MixedGranularity))
}

///|
test "rounding a duration reports a result beyond the representable range as OutOfRange" {
  let day = @core.TimeDelta::days(1L).unwrap()
  assert_eq(@core.TimeDelta::max_value().round_up(day), Err(OutOfRange))
}

///|
test "rounding a datetime reports each failure reason distinctly" {
  let dt = @core.NaiveDateTime::unix_epoch()
  assert_eq(
    dt.round(@core.TimeDelta::zero()).map(_ => ()),
    Err(InvalidGranularity),
  )
  assert_eq(
    dt.truncate(@core.TimeDelta::milliseconds(1_500L).unwrap()).map(_ => ()),
    Err(MixedGranularity),
  )
}

///|
test "RoundingError renders a one-line human-readable message for each variant" {
  assert_eq(
    @core.InvalidGranularity.to_string(),
    "rounding granularity must be positive",
  )
  assert_eq(
    @core.MixedGranularity.to_string(),
    "rounding granularity must be either sub-second or a whole number of seconds",
  )
  assert_eq(@core.OutOfRange.to_string(), "rounded value is out of range")
}
