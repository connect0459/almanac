///|
test "from_local resolves a single unambiguous local reading via the time zone's offset" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let fixed = @tz.FixedOffset::east(9 * 3600).unwrap()
  let result = @tz.DateTime::from_local(naive, fixed)
  let dt = result.single().unwrap()
  assert_eq(dt.naive_local(), naive)
  assert_eq(dt.timezone(), fixed)
}

///|
test "from_local reports Absent within a real spring-forward gap (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_start = 1_710_054_000L
  let in_gap = @core.NaiveDateTime::from_timestamp(dst_start - 18000L, 0).unwrap()
  assert_true(@tz.DateTime::from_local(in_gap, ny) is @tz.Absent)
}

///|
test "from_local reports Ambiguous within a real fall-back fold, ordered earliest then latest (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_end = 1_730_613_600L
  let in_fold = @core.NaiveDateTime::from_timestamp(dst_end - 16000L, 0).unwrap()
  let result = @tz.DateTime::from_local(in_fold, ny)
  let earliest = result.earliest().unwrap()
  let latest = result.latest().unwrap()
  assert_eq(earliest.naive_local(), in_fold)
  assert_eq(latest.naive_local(), in_fold)
  assert_eq(earliest.offset(), @tz.FixedOffset::east(-14400).unwrap())
  assert_eq(latest.offset(), @tz.FixedOffset::east(-18000).unwrap())
  assert_true(earliest.naive_utc() < latest.naive_utc())
}

///|
test "from_ymd_hms builds a DateTime through a time zone from local calendar components" {
  let fixed = @tz.FixedOffset::east(9 * 3600).unwrap()
  let result = @tz.DateTime::from_ymd_hms(2024, 6, 15, 12, 0, 0, fixed)
  let dt = result.single().unwrap()
  assert_eq(
    dt.naive_local(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
    ),
  )
  assert_eq(dt.timezone(), fixed)
}

///|
test "from_ymd_hms reports Absent for an invalid calendar date or time-of-day" {
  let fixed = @tz.FixedOffset::east(0).unwrap()
  assert_true(
    @tz.DateTime::from_ymd_hms(2024, 2, 30, 12, 0, 0, fixed) is @tz.Absent,
  )
  assert_true(
    @tz.DateTime::from_ymd_hms(2024, 6, 15, 25, 0, 0, fixed) is @tz.Absent,
  )
}

///|
test "from_timestamp builds a DateTime from a Unix instant through a time zone" {
  let fixed = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = @tz.DateTime::from_timestamp(1_718_452_800L, 0, fixed).unwrap()
  assert_eq(
    dt.naive_utc(),
    @core.NaiveDateTime::from_timestamp(1_718_452_800L, 0).unwrap(),
  )
  assert_eq(dt.timezone(), fixed)
}

///|
test "from_timestamp reports None for an out-of-range nanosecond component" {
  assert_eq(
    @tz.DateTime::from_timestamp(1_718_452_800L, -1, @tz.Utc::new()),
    None,
  )
}

///|
test "from_utc composes a naive datetime and a time zone whose accessors report them back" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(dt.naive_utc(), naive)
  assert_eq(dt.timezone(), @tz.Utc::new())
}

///|
test "offset reports Utc's zero offset and a FixedOffset's own offset" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let utc_dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(utc_dt.offset(), @tz.FixedOffset::east(0).unwrap())
  let fixed = @tz.FixedOffset::east(9 * 3600).unwrap()
  let fixed_dt = @tz.DateTime::from_utc(naive, fixed)
  assert_eq(fixed_dt.offset(), fixed)
}

///|
test "naive_local shifts the UTC datetime by the time zone's offset" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(
    dt.naive_local(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(21, 0, 0).unwrap(),
    ),
  )
}

///|
test "naive_local for Utc equals the underlying naive datetime unchanged" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(dt.naive_local(), naive)
}

///|
test "with_timezone keeps the same UTC instant while changing the reported time zone" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let utc_dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  let fixed = @tz.FixedOffset::east(9 * 3600).unwrap()
  let converted = utc_dt.with_timezone(fixed)
  assert_eq(converted.naive_utc(), naive)
  assert_eq(converted.timezone(), fixed)
}

///|
test "add_signed and sub_signed on DateTime<Utc> have arithmetic parity with plain NaiveDateTime" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(23, 0, 0).unwrap(),
  )
  let delta = @core.TimeDelta::hours(2L).unwrap()
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(dt.add_signed(delta).naive_utc(), naive.add_signed(delta))
  assert_eq(dt.sub_signed(delta).naive_utc(), naive.sub_signed(delta))
}

///|
test "add_months and sub_months on DateTime<Utc> have arithmetic parity with plain NaiveDateTime" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 31).unwrap(),
    @core.NaiveTime::from_hms(23, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(dt.add_months(1).naive_utc(), naive.add_months(1))
  assert_eq(dt.sub_months(1).naive_utc(), naive.sub_months(1))
}

///|
test "add_days and sub_days on DateTime<Utc> have arithmetic parity with plain NaiveDateTime" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(23, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(dt.add_days(30).naive_utc(), naive.add_days(30))
  assert_eq(dt.sub_days(30).naive_utc(), naive.sub_days(30))
}

///|
test "add_months, add_days keep the same time zone as self" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let fixed = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = @tz.DateTime::from_utc(naive, fixed)
  assert_eq(dt.add_months(1).timezone(), fixed)
  assert_eq(dt.sub_months(1).timezone(), fixed)
  assert_eq(dt.add_days(1).timezone(), fixed)
  assert_eq(dt.sub_days(1).timezone(), fixed)
}

///|
test "signed_duration_since on DateTime<Utc> has arithmetic parity with plain NaiveDateTime" {
  let earlier = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(9, 0, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  let later = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 16).unwrap(),
      @core.NaiveTime::from_hms(10, 30, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(
    later.signed_duration_since(earlier),
    later.naive_utc().signed_duration_since(earlier.naive_utc()),
  )
}

///|
test "round and truncate on DateTime<Utc> have arithmetic parity with plain NaiveDateTime" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 45, 30).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  let granularity = @core.TimeDelta::hours(1L).unwrap()
  assert_eq(
    dt.truncate(granularity).unwrap().naive_utc(),
    naive.truncate(granularity).unwrap(),
  )
  assert_eq(
    dt.round(granularity).unwrap().naive_utc(),
    naive.round(granularity).unwrap(),
  )
}

///|
test "round and truncate operate on the underlying UTC instant, not the offset-shifted local presentation" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 15, 0).unwrap(),
  )
  let fixed = @tz.FixedOffset::east(9 * 3600 + 1800).unwrap()
  let dt = @tz.DateTime::from_utc(naive, fixed)
  let truncated = dt.truncate(@core.TimeDelta::hours(1L).unwrap()).unwrap()
  assert_eq(
    truncated.naive_utc(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
    ),
  )
  assert_eq(
    truncated.naive_local(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(21, 30, 0).unwrap(),
    ),
  )
  assert_eq(truncated.timezone(), fixed)
}

///|
test "round and truncate report None for an unsupported granularity, matching NaiveDateTime" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(9, 45, 30).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  let mixed = @core.TimeDelta::milliseconds(1500L).unwrap()
  assert_eq(dt.truncate(mixed), None)
  assert_eq(dt.round(mixed), None)
}

///|
test "add_years and sub_years on DateTime<Utc> have arithmetic parity with plain NaiveDateTime" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 2, 29).unwrap(),
    @core.NaiveTime::from_hms(23, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(dt.add_years(1).naive_utc(), naive.add_years(1))
  assert_eq(dt.sub_years(1).naive_utc(), naive.sub_years(1))
}

///|
test "add_years and sub_years keep the same time zone as self" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let fixed = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = @tz.DateTime::from_utc(naive, fixed)
  assert_eq(dt.add_years(1).timezone(), fixed)
  assert_eq(dt.sub_years(1).timezone(), fixed)
}
