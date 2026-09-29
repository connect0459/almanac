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

///|
test "with_hour changes only the hour, keeping minute, second, and nanosecond" {
  let t = @core.NaiveTime::from_hms_nano(23, 56, 4, 12_345_678).unwrap()
  assert_eq(
    t.with_hour(6),
    Some(@core.NaiveTime::from_hms_nano(6, 56, 4, 12_345_678).unwrap()),
  )
}

///|
test "with_hour rejects an hour outside 0..=23" {
  let t = @core.NaiveTime::from_hms(12, 0, 0).unwrap()
  assert_eq(t.with_hour(-1), None)
  assert_eq(t.with_hour(24), None)
}

///|
test "with_minute changes only the minute, keeping hour, second, and nanosecond" {
  let t = @core.NaiveTime::from_hms_nano(23, 56, 4, 12_345_678).unwrap()
  assert_eq(
    t.with_minute(45),
    Some(@core.NaiveTime::from_hms_nano(23, 45, 4, 12_345_678).unwrap()),
  )
}

///|
test "with_minute rejects a minute outside 0..=59" {
  let t = @core.NaiveTime::from_hms(12, 0, 0).unwrap()
  assert_eq(t.with_minute(-1), None)
  assert_eq(t.with_minute(60), None)
}

///|
test "with_second changes only the second, keeping hour, minute, and nanosecond" {
  let t = @core.NaiveTime::from_hms_nano(23, 56, 4, 12_345_678).unwrap()
  assert_eq(
    t.with_second(17),
    Some(@core.NaiveTime::from_hms_nano(23, 56, 17, 12_345_678).unwrap()),
  )
}

///|
test "with_second rejects a second outside 0..=59" {
  let t = @core.NaiveTime::from_hms(12, 0, 0).unwrap()
  assert_eq(t.with_second(-1), None)
  assert_eq(t.with_second(60), None)
}

///|
test "with_nanosecond changes only the nanosecond, keeping hour, minute, and second" {
  let t = @core.NaiveTime::from_hms_nano(23, 56, 4, 12_345_678).unwrap()
  assert_eq(
    t.with_nanosecond(333_333_333),
    Some(@core.NaiveTime::from_hms_nano(23, 56, 4, 333_333_333).unwrap()),
  )
}

///|
test "with_nanosecond accepts a leap-second value regardless of the current second" {
  let t = @core.NaiveTime::from_hms_nano(23, 56, 4, 12_345_678).unwrap()
  let leap = t.with_nanosecond(1_333_333_333).unwrap()
  assert_eq(leap.nanosecond(), 1_333_333_333)
}

///|
test "with_nanosecond rejects a value at or beyond twice a second" {
  let t = @core.NaiveTime::from_hms(12, 0, 0).unwrap()
  assert_eq(t.with_nanosecond(-1), None)
  assert_eq(t.with_nanosecond(2_000_000_000), None)
}

///|
test "signed_duration_since is zero for the same time of day" {
  let t = @core.NaiveTime::from_hms(9, 30, 0).unwrap()
  assert_true(t.signed_duration_since(t).is_zero())
}

///|
test "signed_duration_since measures the elapsed time between two ordinary times" {
  let earlier = @core.NaiveTime::from_hms(9, 0, 0).unwrap()
  let later = @core.NaiveTime::from_hms(10, 30, 0).unwrap()
  assert_eq(
    later.signed_duration_since(earlier),
    @core.TimeDelta::hours(1L)
    .unwrap()
    .add(@core.TimeDelta::minutes(30L).unwrap())
    .unwrap(),
  )
}

///|
test "signed_duration_since is antisymmetric" {
  let a = @core.NaiveTime::from_hms_nano(9, 0, 0, 250_000_000).unwrap()
  let b = @core.NaiveTime::from_hms(10, 30, 15).unwrap()
  assert_eq(a.signed_duration_since(b), b.signed_duration_since(a).neg())
}

///|
test "signed_duration_since treats a leap second as coinciding with the prior non-leap second" {
  let after_leap = @core.NaiveTime::from_hms_milli(3, 6, 0, 200).unwrap()
  let leap = @core.NaiveTime::from_hms_milli(3, 5, 59, 1_800).unwrap()
  assert_eq(
    after_leap.signed_duration_since(leap),
    @core.TimeDelta::milliseconds(400L).unwrap(),
  )
}

///|
test "signed_duration_since from a leap second matches the negation of the reverse difference" {
  let after_leap = @core.NaiveTime::from_hms_milli(3, 6, 0, 200).unwrap()
  let leap = @core.NaiveTime::from_hms_milli(3, 5, 59, 1_800).unwrap()
  assert_eq(
    leap.signed_duration_since(after_leap),
    @core.TimeDelta::milliseconds(-400L).unwrap(),
  )
}

///|
test "wrapping_add_signed advances within the day without wrapping" {
  let time = @core.NaiveTime::from_hms(10, 0, 0).unwrap()
  assert_eq(
    time.wrapping_add_signed(@core.TimeDelta::minutes(90L).unwrap()),
    @core.NaiveTime::from_hms(11, 30, 0).unwrap(),
  )
}

///|
test "wrapping_add_signed wraps past midnight and discards the day count" {
  let time = @core.NaiveTime::from_hms(23, 0, 0).unwrap()
  assert_eq(
    time.wrapping_add_signed(@core.TimeDelta::hours(2L).unwrap()),
    @core.NaiveTime::from_hms(1, 0, 0).unwrap(),
  )
}

///|
test "wrapping_sub_signed wraps before midnight and discards the day count" {
  let time = @core.NaiveTime::from_hms(1, 0, 0).unwrap()
  assert_eq(
    time.wrapping_sub_signed(@core.TimeDelta::hours(2L).unwrap()),
    @core.NaiveTime::from_hms(23, 0, 0).unwrap(),
  )
}

///|
test "wrapping_add_signed with a negative duration moves backward and wraps" {
  let time = @core.NaiveTime::from_hms(0, 30, 0).unwrap()
  assert_eq(
    time.wrapping_add_signed(@core.TimeDelta::hours(-1L).unwrap()),
    @core.NaiveTime::from_hms(23, 30, 0).unwrap(),
  )
}

///|
test "wrapping arithmetic by whole days returns the same time of day" {
  let time = @core.NaiveTime::from_hms_nano(13, 45, 6, 789).unwrap()
  assert_eq(time.wrapping_add_signed(@core.TimeDelta::days(3L).unwrap()), time)
  assert_eq(time.wrapping_sub_signed(@core.TimeDelta::days(3L).unwrap()), time)
}

///|
test "wrapping arithmetic keeps a leap second for a zero duration" {
  let leap = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  assert_eq(leap.wrapping_add_signed(@core.TimeDelta::zero()), leap)
  assert_eq(leap.wrapping_sub_signed(@core.TimeDelta::zero()), leap)
}

///|
test "wrapping arithmetic agrees with the time reported by the overflowing forms" {
  let time = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  let delta = @core.TimeDelta::seconds(90_001L).unwrap()
  assert_eq(
    time.wrapping_add_signed(delta),
    time.overflowing_add_signed(delta).0,
  )
  assert_eq(
    time.wrapping_sub_signed(delta),
    time.overflowing_sub_signed(delta).0,
  )
}

///|
test "to_string renders a time as hour:minute:second with zero padding" {
  assert_eq(
    @core.NaiveTime::from_hms(13, 45, 6).unwrap().to_string(),
    "13:45:06",
  )
  assert_eq(@core.NaiveTime::from_hms(0, 0, 0).unwrap().to_string(), "00:00:00")
  assert_eq(
    @core.NaiveTime::from_hms(23, 59, 59).unwrap().to_string(),
    "23:59:59",
  )
}

///|
test "to_string uses the fewest of 3, 6 or 9 fractional digits that represent the nanoseconds" {
  assert_eq(
    @core.NaiveTime::from_hms_nano(1, 2, 3, 500_000_000).unwrap().to_string(),
    "01:02:03.500",
  )
  assert_eq(
    @core.NaiveTime::from_hms_nano(1, 2, 3, 1_000_000).unwrap().to_string(),
    "01:02:03.001",
  )
  assert_eq(
    @core.NaiveTime::from_hms_nano(1, 2, 3, 123_456_000).unwrap().to_string(),
    "01:02:03.123456",
  )
  assert_eq(
    @core.NaiveTime::from_hms_nano(1, 2, 3, 1_000).unwrap().to_string(),
    "01:02:03.000001",
  )
  assert_eq(
    @core.NaiveTime::from_hms_nano(1, 2, 3, 789).unwrap().to_string(),
    "01:02:03.000000789",
  )
  assert_eq(
    @core.NaiveTime::from_hms_nano(1, 2, 3, 123_456_789).unwrap().to_string(),
    "01:02:03.123456789",
  )
}

///|
test "to_string renders a leap second with second 60" {
  assert_eq(
    @core.NaiveTime::from_hms_nano(23, 59, 59, 1_000_000_000)
    .unwrap()
    .to_string(),
    "23:59:60",
  )
  assert_eq(
    @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000)
    .unwrap()
    .to_string(),
    "23:59:60.500",
  )
}

///|
test "equal times hash equally and work as map keys" {
  let a = @core.NaiveTime::from_hms_nano(13, 45, 6, 789).unwrap()
  let b = @core.NaiveTime::from_hms(13, 45, 6)
    .unwrap()
    .with_nanosecond(789)
    .unwrap()
  assert_eq(a, b)
  assert_eq(a.hash(), b.hash())
  let seen : Map[@core.NaiveTime, String] = Map([])
  seen[a] = "first"
  seen[@core.NaiveTime::from_hms(13, 45, 7).unwrap()] = "second"
  assert_eq(seen.length(), 2)
  assert_eq(seen.get(b), Some("first"))
}

///|
test "a leap second and the following midnight-adjacent time are distinct map keys" {
  let leap = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  let regular = @core.NaiveTime::from_hms_nano(23, 59, 59, 500_000_000).unwrap()
  let seen : Map[@core.NaiveTime, Int] = Map([])
  seen[leap] = 1
  seen[regular] = 2
  assert_eq(seen.length(), 2)
  assert_eq(seen.get(leap), Some(1))
}

///|
test "midnight is 00:00:00 with no fractional part" {
  let midnight = @core.NaiveTime::midnight()
  assert_eq(midnight, @core.NaiveTime::from_hms(0, 0, 0).unwrap())
  assert_eq(midnight.num_seconds_from_midnight(), 0)
  assert_eq(midnight.nanosecond(), 0)
}

///|
test "midnight is the earliest time of day" {
  assert_true(
    @core.NaiveTime::midnight() <
    @core.NaiveTime::from_hms_nano(0, 0, 0, 1).unwrap(),
  )
  assert_true(@core.NaiveTime::midnight() <= @core.NaiveTime::midnight())
}

///|
test "the default time is midnight" {
  let time : @core.NaiveTime = Default::default()
  assert_eq(time, @core.NaiveTime::midnight())
}

///|
test "hms reports hour, minute, and second together" {
  let time = @core.NaiveTime::from_hms(23, 59, 58).unwrap()
  assert_eq(time.hms(), (23, 59, 58))
}

///|
test "hms reports a leap second as second 59, like second()" {
  let time = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  assert_eq(time.hms(), (23, 59, 59))
}
