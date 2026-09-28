///|
test "from_hms constructs a time whose accessors report back hour, minute, and second" {
  let time = @core.NaiveTime::from_hms(13, 45, 30).unwrap()
  assert_eq(time.hour(), 13)
  assert_eq(time.minute(), 45)
  assert_eq(time.second(), 30)
  assert_eq(time.nanosecond(), 0)
}

///|
test "from_hms rejects an hour, minute, or second outside its valid range" {
  assert_eq(@core.NaiveTime::from_hms(24, 0, 0), None)
  assert_eq(@core.NaiveTime::from_hms(-1, 0, 0), None)
  assert_eq(@core.NaiveTime::from_hms(0, 60, 0), None)
  assert_eq(@core.NaiveTime::from_hms(0, 0, 60), None)
}

///|
test "from_hms_nano accepts a leap-second nanosecond value at second 59" {
  let time = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_200_000_000).unwrap()
  assert_eq(time.second(), 59)
  assert_eq(time.nanosecond(), 1_200_000_000)
}

///|
test "from_hms_nano rejects a nanosecond value at or beyond twice a second" {
  assert_eq(@core.NaiveTime::from_hms_nano(23, 59, 59, 2_000_000_000), None)
  assert_eq(@core.NaiveTime::from_hms_nano(0, 0, 0, -1), None)
}

///|
test "from_hms_milli and from_hms_micro construct the same time as an equivalent nanosecond count" {
  assert_eq(
    @core.NaiveTime::from_hms_milli(8, 0, 0, 250),
    @core.NaiveTime::from_hms_nano(8, 0, 0, 250_000_000),
  )
  assert_eq(
    @core.NaiveTime::from_hms_micro(8, 0, 0, 250_500),
    @core.NaiveTime::from_hms_nano(8, 0, 0, 250_500_000),
  )
}

///|
test "from_num_seconds_from_midnight round-trips through num_seconds_from_midnight" {
  let time = @core.NaiveTime::from_hms(6, 30, 15).unwrap()
  assert_eq(
    @core.NaiveTime::from_num_seconds_from_midnight(
      time.num_seconds_from_midnight(),
      0,
    ),
    Some(time),
  )
}

///|
test "from_num_seconds_from_midnight rejects a second count outside a single day" {
  assert_eq(@core.NaiveTime::from_num_seconds_from_midnight(86400, 0), None)
  assert_eq(@core.NaiveTime::from_num_seconds_from_midnight(-1, 0), None)
}

///|
test "from_num_seconds_from_midnight rejects a nanosecond value at or beyond twice a second" {
  assert_eq(@core.NaiveTime::from_num_seconds_from_midnight(0, -1), None)
  assert_eq(
    @core.NaiveTime::from_num_seconds_from_midnight(0, 2_000_000_000),
    None,
  )
}

///|
test "hour12 reports the 12-hour clock hour and AM/PM flag, wrapping midnight and noon to 12" {
  assert_eq(@core.NaiveTime::from_hms(0, 0, 0).unwrap().hour12(), (false, 12))
  assert_eq(@core.NaiveTime::from_hms(12, 0, 0).unwrap().hour12(), (true, 12))
  assert_eq(@core.NaiveTime::from_hms(13, 0, 0).unwrap().hour12(), (true, 1))
  assert_eq(@core.NaiveTime::from_hms(23, 0, 0).unwrap().hour12(), (true, 11))
}

///|
test "overflowing_add_signed with a zero duration returns the time unchanged, even for a leap second" {
  let time = @core.NaiveTime::from_hms(10, 15, 20).unwrap()
  assert_eq(time.overflowing_add_signed(@core.TimeDelta::zero()), (time, 0L))
  let leap = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  assert_eq(leap.overflowing_add_signed(@core.TimeDelta::zero()), (leap, 0L))
}

///|
test "overflowing_add_signed wraps forward past midnight and reports one day of overflow" {
  let time = @core.NaiveTime::from_hms(23, 0, 0).unwrap()
  let delta = @core.TimeDelta::hours(2L).unwrap()
  let (result, days) = time.overflowing_add_signed(delta)
  assert_eq(result, @core.NaiveTime::from_hms(1, 0, 0).unwrap())
  assert_eq(days, 1L)
}

///|
test "overflowing_sub_signed wraps backward past midnight and reports one day of underflow" {
  let time = @core.NaiveTime::from_hms(1, 0, 0).unwrap()
  let delta = @core.TimeDelta::hours(2L).unwrap()
  let (result, days) = time.overflowing_sub_signed(delta)
  assert_eq(result, @core.NaiveTime::from_hms(23, 0, 0).unwrap())
  assert_eq(days, -1L)
}

///|
test "overflowing_add_signed and overflowing_sub_signed by the same duration are inverse for ordinary times" {
  let time = @core.NaiveTime::from_hms(10, 15, 20).unwrap()
  let delta = @core.TimeDelta::hours(5L).unwrap()
  let (forward, _) = time.overflowing_add_signed(delta)
  let (back, _) = forward.overflowing_sub_signed(delta)
  assert_eq(back, time)
}

///|
test "overflowing_add_signed treats a leap second as one elapsed second once a nonzero duration is applied" {
  let leap = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_200_000_000).unwrap()
  let (result, days) = leap.overflowing_add_signed(
    @core.TimeDelta::milliseconds(100L).unwrap(),
  )
  assert_eq(result, @core.NaiveTime::from_hms_milli(0, 0, 0, 300).unwrap())
  assert_eq(days, 1L)
}

///|
test "overflowing_add_signed carries a multi-day duration into the returned day count" {
  let time = @core.NaiveTime::from_hms(6, 0, 0).unwrap()
  let delta = @core.TimeDelta::days(3L)
    .unwrap()
    .add(@core.TimeDelta::hours(1L).unwrap())
    .unwrap()
  let (result, days) = time.overflowing_add_signed(delta)
  assert_eq(result, @core.NaiveTime::from_hms(7, 0, 0).unwrap())
  assert_eq(days, 3L)
}

///|
test "a later time of day compares greater than an earlier one" {
  let t1 = @core.NaiveTime::from_hms(9, 0, 0).unwrap()
  let t2 = @core.NaiveTime::from_hms(17, 30, 0).unwrap()
  assert_true(t1 < t2)
  assert_true(t2 > t1)
  assert_true(t1.compare(t2) < 0)
}

///|
test "nanosecond precision is reflected in ordering" {
  let t1 = @core.NaiveTime::from_hms_nano(9, 0, 0, 500).unwrap()
  let t2 = @core.NaiveTime::from_hms_nano(9, 0, 0, 501).unwrap()
  assert_true(t1 < t2)
}

///|
test "a leap second orders after the same second's maximum ordinary reading" {
  let ordinary = @core.NaiveTime::from_hms_nano(23, 59, 59, 999_999_999).unwrap()
  let leap = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  assert_true(ordinary < leap)
}

///|
test "equal times of day compare as neither less nor greater" {
  let t1 = @core.NaiveTime::from_hms(9, 0, 0).unwrap()
  let t2 = @core.NaiveTime::from_hms(9, 0, 0).unwrap()
  assert_true(t1 <= t2)
  assert_true(t1 >= t2)
  assert_eq(t1.compare(t2), 0)
}
