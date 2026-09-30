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

///|
test "round_subsecs and truncate_subsecs on DateTime<Utc> have parity with plain NaiveDateTime" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms_nano(12, 34, 56, 987_654_321).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(naive, @tz.Utc::new())
  assert_eq(dt.truncate_subsecs(3).naive_utc(), naive.truncate_subsecs(3))
  assert_eq(dt.round_subsecs(3).map(d => d.naive_utc()), naive.round_subsecs(3))
}

///|
test "round_subsecs and truncate_subsecs keep the same time zone as self" {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms_nano(12, 34, 56, 987_654_321).unwrap(),
  )
  let fixed = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = @tz.DateTime::from_utc(naive, fixed)
  assert_eq(dt.truncate_subsecs(3).timezone(), fixed)
  assert_eq(dt.round_subsecs(3).unwrap().timezone(), fixed)
}

///|
fn instant_at(
  secs : Int64,
  tz : @tz.FixedOffset,
) -> @tz.DateTime[@tz.FixedOffset] {
  @tz.DateTime::from_timestamp(secs, 0, tz).unwrap()
}

///|
test "DateTime orders by UTC instant within the same time zone" {
  let utc = @tz.FixedOffset::east(0).unwrap()
  let earlier = instant_at(1_000L, utc)
  let later = instant_at(2_000L, utc)
  assert_true(earlier < later)
  assert_true(later > earlier)
  assert_true(earlier <= later)
  assert_true(later >= earlier)
  assert_true(earlier <= earlier)
  assert_true(earlier >= earlier)
  assert_eq(earlier.compare(later), -1)
  assert_eq(later.compare(earlier), 1)
  assert_eq(earlier.compare(earlier), 0)
}

///|
test "DateTime ordering follows the instant rather than the local wall-clock reading" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let utc = @tz.FixedOffset::east(0).unwrap()
  let a = instant_at(1_000L, tokyo)
  let b = instant_at(1_000L, utc)
  assert_true(a.naive_local() > b.naive_local())
  assert_eq(a.compare_instant(b), 0)
  assert_eq(b.compare_instant(a), 0)
}

///|
test "compare_instant orders datetimes expressed in different time zone types" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let earlier = instant_at(1_000L, tokyo)
  let later = @tz.DateTime::from_timestamp(2_000L, 0, @tz.Utc::new()).unwrap()
  assert_eq(earlier.compare_instant(later), -1)
  assert_eq(later.compare_instant(earlier), 1)
}

///|
fn tokyo_new_year_morning() -> @tz.DateTime[@tz.FixedOffset] {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  @tz.DateTime::from_ymd_hms(2024, 1, 1, 7, 30, 15, tokyo)
  .single()
  .unwrap()
  .add_signed(@core.TimeDelta::nanoseconds(123_456_789L).unwrap())
}

///|
test "DateTime calendar accessors report the local date, not the UTC date" {
  let dt = tokyo_new_year_morning()
  assert_eq(dt.naive_utc().year(), 2023)
  assert_eq(dt.year(), 2024)
  assert_eq(dt.month(), @core.Month::Jan)
  assert_eq(dt.day(), 1)
  assert_eq(dt.ordinal(), 1)
  assert_eq(dt.weekday(), @core.Weekday::Mon)
  assert_eq(dt.iso_week(), dt.date_naive().iso_week())
  assert_eq(dt.date_naive(), @core.NaiveDate::from_ymd(2024, 1, 1).unwrap())
}

///|
test "DateTime time-of-day accessors report the local time, not the UTC time" {
  let dt = tokyo_new_year_morning()
  assert_eq(dt.hour(), 7)
  assert_eq(dt.minute(), 30)
  assert_eq(dt.second(), 15)
  assert_eq(dt.nanosecond(), 123_456_789)
  assert_eq(
    dt.time(),
    @core.NaiveTime::from_hms_nano(7, 30, 15, 123_456_789).unwrap(),
  )
}

///|
fn assert_tokyo_reading(
  actual : @tz.MappedLocalTime[@tz.DateTime[@tz.FixedOffset]],
  ymd : (Int, Int, Int),
  hms : (Int, Int, Int),
  nanos : Int,
) -> Unit raise {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let (y, mo, d) = ymd
  let (h, mi, s) = hms
  let want = @tz.DateTime::from_ymd_hms(y, mo, d, h, mi, s, tokyo)
    .single()
    .unwrap()
    .add_signed(@core.TimeDelta::nanoseconds(nanos.to_int64()).unwrap())
  assert_eq(actual.single().unwrap(), want)
}

///|
test "with_* replaces a single local component and keeps the rest of the wall-clock reading" {
  let dt = tokyo_new_year_morning()
  let n = 123_456_789
  assert_tokyo_reading(dt.with_year(2025), (2025, 1, 1), (7, 30, 15), n)
  assert_tokyo_reading(dt.with_month(3), (2024, 3, 1), (7, 30, 15), n)
  assert_tokyo_reading(dt.with_day(20), (2024, 1, 20), (7, 30, 15), n)
  assert_tokyo_reading(dt.with_ordinal(60), (2024, 2, 29), (7, 30, 15), n)
  assert_tokyo_reading(dt.with_hour(23), (2024, 1, 1), (23, 30, 15), n)
  assert_tokyo_reading(dt.with_minute(0), (2024, 1, 1), (7, 0, 15), n)
  assert_tokyo_reading(dt.with_second(59), (2024, 1, 1), (7, 30, 59), n)
  assert_tokyo_reading(dt.with_nanosecond(5), (2024, 1, 1), (7, 30, 15), 5)
}

///|
test "with_* reports Absent for a component value that does not form a valid local reading" {
  let dt = tokyo_new_year_morning().with_month(1).single().unwrap()
  assert_true(dt.with_day(32) is @tz.Absent)
  assert_true(dt.with_month(13) is @tz.Absent)
  assert_true(dt.with_ordinal(367) is @tz.Absent)
  assert_true(dt.with_hour(24) is @tz.Absent)
  assert_true(dt.with_minute(60) is @tz.Absent)
  assert_true(dt.with_second(60) is @tz.Absent)
  assert_true(dt.with_nanosecond(2_000_000_000) is @tz.Absent)
  let leap_day = dt
    .with_month(2)
    .single()
    .unwrap()
    .with_day(29)
    .single()
    .unwrap()
  assert_true(leap_day.with_year(2025) is @tz.Absent)
  let jan_31 = dt.with_day(31).single().unwrap()
  assert_true(jan_31.with_month(2) is @tz.Absent)
}

///|
test "with_hour reports Absent when the new local reading falls in a spring-forward gap (America/New_York)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let after_gap = @tz.DateTime::from_ymd_hms(2024, 3, 10, 3, 30, 0, ny)
    .single()
    .unwrap()
  assert_true(after_gap.with_hour(2) is @tz.Absent)
}

///|
test "with_hour reports Ambiguous when the new local reading falls in a fall-back fold (America/New_York)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let after_fold = @tz.DateTime::from_ymd_hms(2024, 11, 3, 5, 30, 0, ny)
    .single()
    .unwrap()
  let result = after_fold.with_hour(1)
  let earliest = result.earliest().unwrap()
  let latest = result.latest().unwrap()
  assert_eq(earliest.hour(), 1)
  assert_eq(latest.hour(), 1)
  assert_eq(earliest.compare_instant(latest), -1)
}

///|
test "DateTime 0-based and derived calendar accessors report the local date, not the UTC date" {
  let dt = tokyo_new_year_morning()
  assert_eq(dt.naive_utc().year(), 2023)
  assert_eq(dt.month0(), 0)
  assert_eq(dt.day0(), 0)
  assert_eq(dt.ordinal0(), 0)
  assert_eq(dt.quarter(), 1)
  assert_eq(dt.year_ce(), (true, 2024))
  assert_eq(dt.num_days_in_month(), 31)
  assert_eq(dt.num_days_from_ce(), dt.date_naive().num_days_from_ce())
}

///|
test "DateTime 12-hour and seconds-since-midnight accessors report the local time, not the UTC time" {
  let dt = tokyo_new_year_morning()
  assert_eq(dt.hour12(), (false, 7))
  assert_eq(dt.num_seconds_from_midnight(), 7 * 3600 + 30 * 60 + 15)
  let afternoon = dt.with_hour(15).single().unwrap()
  assert_eq(afternoon.hour12(), (true, 3))
}

///|
test "with_month0, with_day0 and with_ordinal0 replace a 0-based local component and keep the rest of the reading" {
  let dt = tokyo_new_year_morning()
  let n = 123_456_789
  assert_tokyo_reading(dt.with_month0(2), (2024, 3, 1), (7, 30, 15), n)
  assert_tokyo_reading(dt.with_day0(19), (2024, 1, 20), (7, 30, 15), n)
  assert_tokyo_reading(dt.with_ordinal0(59), (2024, 2, 29), (7, 30, 15), n)
}

///|
test "with_month0, with_day0 and with_ordinal0 report Absent for a value that does not form a valid local reading" {
  let dt = tokyo_new_year_morning()
  assert_true(dt.with_month0(12) is @tz.Absent)
  assert_true(dt.with_day0(31) is @tz.Absent)
  assert_true(dt.with_ordinal0(366) is @tz.Absent)
}

///|
test "with_day0 reports Absent in a spring-forward gap and Ambiguous in a fall-back fold (America/New_York)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let before_gap = @tz.DateTime::from_ymd_hms(2024, 3, 9, 2, 30, 0, ny)
    .single()
    .unwrap()
  assert_true(before_gap.with_day0(9) is @tz.Absent)
  let before_fold = @tz.DateTime::from_ymd_hms(2024, 11, 2, 1, 30, 0, ny)
    .single()
    .unwrap()
  assert_true(before_fold.with_day0(2).earliest() is Some(_))
  assert_true(before_fold.with_day0(2).single() is None)
}

///|
test "DateTime timestamp accessors report the UTC instant regardless of the time zone" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let utc = @tz.FixedOffset::east(0).unwrap()
  let in_tokyo = @tz.DateTime::from_timestamp(
    1_700_000_000L, 123_456_789, tokyo,
  ).unwrap()
  let in_utc = in_tokyo.with_timezone(utc)
  for dt in [in_tokyo, in_utc] {
    assert_eq(dt.timestamp(), 1_700_000_000L)
    assert_eq(dt.timestamp_millis(), 1_700_000_000_123L)
    assert_eq(dt.timestamp_micros(), Some(1_700_000_000_123_456L))
    assert_eq(dt.timestamp_nanos(), Some(1_700_000_000_123_456_789L))
    assert_eq(dt.timestamp_subsec_nanos(), 123_456_789)
    assert_eq(dt.timestamp_subsec_millis(), 123)
    assert_eq(dt.timestamp_subsec_micros(), 123_456)
  }
}

///|
test "DateTime timestamp accessors floor toward negative infinity before the Unix epoch" {
  let utc = @tz.FixedOffset::east(0).unwrap()
  let dt = @tz.DateTime::from_timestamp(-1L, 500_000_000, utc).unwrap()
  assert_eq(dt.timestamp(), -1L)
  assert_eq(dt.timestamp_millis(), -500L)
  assert_eq(dt.timestamp_subsec_millis(), 500)
}

///|
test "DateTime timestamp_millis stays total for a far date while timestamp_micros and timestamp_nanos are None" {
  let utc = @tz.FixedOffset::east(0).unwrap()
  let far_date = @core.NaiveDate::from_ymd(1970, 1, 1)
    .unwrap()
    .add_days(2_000_000_000)
  let far = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(far_date, @core.NaiveTime::midnight()),
    utc,
  )
  assert_eq(far.timestamp_millis(), far.timestamp() * 1000L)
  assert_eq(far.timestamp_micros(), None)
  assert_eq(far.timestamp_nanos(), None)
}

///|
test "from_timestamp_millis, from_timestamp_micros and from_timestamp_nanos agree on the same instant and keep the given zone" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let from_millis = @tz.DateTime::from_timestamp_millis(
    1_700_000_000_123L, tokyo,
  ).unwrap()
  let from_micros = @tz.DateTime::from_timestamp_micros(
    1_700_000_000_123_000L, tokyo,
  ).unwrap()
  let from_nanos = @tz.DateTime::from_timestamp_nanos(
    1_700_000_000_123_000_000L, tokyo,
  ).unwrap()
  assert_eq(from_millis, from_micros)
  assert_eq(from_micros, from_nanos)
  assert_eq(from_millis.timezone(), tokyo)
  assert_eq(from_millis.timestamp_millis(), 1_700_000_000_123L)
}

///|
test "from_timestamp_millis, from_timestamp_micros and from_timestamp_nanos floor a pre-epoch value toward negative infinity" {
  let utc = @tz.FixedOffset::east(0).unwrap()
  assert_eq(
    @tz.DateTime::from_timestamp_millis(-1L, utc).unwrap().timestamp(),
    -1L,
  )
  assert_eq(
    @tz.DateTime::from_timestamp_micros(-1L, utc)
    .unwrap()
    .timestamp_subsec_micros(),
    999_999,
  )
  assert_eq(
    @tz.DateTime::from_timestamp_nanos(-1L, utc)
    .unwrap()
    .timestamp_subsec_nanos(),
    999_999_999,
  )
}

///|
test "from_timestamp_millis is None when the instant is beyond NaiveDate's range while micros and nanos accept the Int64 maximum" {
  let utc = @tz.FixedOffset::east(0).unwrap()
  let max = 9_223_372_036_854_775_807L
  assert_eq(@tz.DateTime::from_timestamp_millis(max, utc), None)
  assert_eq(
    @tz.DateTime::from_timestamp_micros(max, utc).unwrap().timestamp(),
    9_223_372_036_854L,
  )
  assert_eq(
    @tz.DateTime::from_timestamp_nanos(max, utc).unwrap().timestamp(),
    9_223_372_036L,
  )
}

///|
test "to_utc re-expresses the same instant in UTC" {
  let dt = tokyo_new_year_morning()
  let utc = dt.to_utc()
  assert_eq(utc.timezone(), @tz.Utc::new())
  assert_eq(utc.naive_utc(), dt.naive_utc())
  assert_eq(utc.naive_local(), dt.naive_utc())
  assert_eq(utc.compare_instant(dt), 0)
}

///|
test "fixed_offset freezes the offset in effect at the instant (America/New_York summer and winter)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let summer = @tz.DateTime::from_ymd_hms(2024, 7, 1, 12, 0, 0, ny)
    .single()
    .unwrap()
  let winter = @tz.DateTime::from_ymd_hms(2024, 1, 1, 12, 0, 0, ny)
    .single()
    .unwrap()
  let summer_fixed = summer.fixed_offset()
  let winter_fixed = winter.fixed_offset()
  assert_eq(summer_fixed.timezone(), @tz.FixedOffset::east(-4 * 3600).unwrap())
  assert_eq(winter_fixed.timezone(), @tz.FixedOffset::east(-5 * 3600).unwrap())
  assert_eq(summer_fixed.naive_local(), summer.naive_local())
  assert_eq(summer_fixed.compare_instant(summer), 0)
  assert_eq(winter_fixed.naive_local(), winter.naive_local())
}

///|
test "with_time replaces the local time of day and keeps the local date" {
  let dt = tokyo_new_year_morning()
  let time = @core.NaiveTime::from_hms(23, 59, 58).unwrap()
  assert_tokyo_reading(dt.with_time(time), (2024, 1, 1), (23, 59, 58), 0)
}

///|
test "with_time reports Absent in a spring-forward gap and Ambiguous in a fall-back fold (America/New_York)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let gap_time = @core.NaiveTime::from_hms(2, 30, 0).unwrap()
  let fold_time = @core.NaiveTime::from_hms(1, 30, 0).unwrap()
  let gap_day = @tz.DateTime::from_ymd_hms(2024, 3, 10, 12, 0, 0, ny)
    .single()
    .unwrap()
  let fold_day = @tz.DateTime::from_ymd_hms(2024, 11, 3, 12, 0, 0, ny)
    .single()
    .unwrap()
  assert_true(gap_day.with_time(gap_time) is @tz.Absent)
  let folded = gap_day.with_time(fold_time)
  assert_true(folded.single() is Some(_))
  let ambiguous = fold_day.with_time(fold_time)
  assert_true(ambiguous.single() is None)
  assert_eq(
    ambiguous.earliest().unwrap().compare_instant(ambiguous.latest().unwrap()),
    -1,
  )
}

///|
test "years_since counts full local calendar years and ignores the time of day" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let born = @tz.DateTime::from_ymd_hms(2000, 6, 15, 23, 0, 0, tokyo)
    .single()
    .unwrap()
  let day_before = @tz.DateTime::from_ymd_hms(2024, 6, 14, 12, 0, 0, tokyo)
    .single()
    .unwrap()
  let birthday_early = @tz.DateTime::from_ymd_hms(2024, 6, 15, 1, 0, 0, tokyo)
    .single()
    .unwrap()
  assert_eq(day_before.years_since(born), Some(23))
  assert_eq(birthday_early.years_since(born), Some(24))
  assert_eq(born.years_since(born), Some(0))
}

///|
test "years_since is None when the base is later than the datetime" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let earlier = @tz.DateTime::from_ymd_hms(2000, 6, 15, 0, 0, 0, tokyo)
    .single()
    .unwrap()
  let later = @tz.DateTime::from_ymd_hms(2024, 6, 15, 0, 0, 0, tokyo)
    .single()
    .unwrap()
  assert_eq(earlier.years_since(later), None)
}

///|
test "years_since compares local dates, not UTC dates" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let born = @tz.DateTime::from_ymd_hms(2000, 1, 1, 0, 30, 0, tokyo)
    .single()
    .unwrap()
  let now = @tz.DateTime::from_ymd_hms(2024, 1, 1, 0, 30, 0, tokyo)
    .single()
    .unwrap()
  assert_eq(born.naive_utc().year(), 1999)
  assert_eq(now.years_since(born), Some(24))
}

///|
test "Utc renders as UTC and FixedOffset as a colon-separated offset" {
  assert_eq(@tz.Utc::new().to_string(), "UTC")
  assert_eq(@tz.FixedOffset::east(9 * 3600).unwrap().to_string(), "+09:00")
  assert_eq(
    @tz.FixedOffset::east(-(5 * 3600 + 30 * 60)).unwrap().to_string(),
    "-05:30",
  )
  assert_eq(@tz.FixedOffset::east(0).unwrap().to_string(), "+00:00")
  assert_eq(@tz.FixedOffset::east(-17762).unwrap().to_string(), "-04:56:02")
}

///|
test "Location renders as its name, or as an empty string when unnamed" {
  assert_eq(@tz.Location::load("Asia/Tokyo").unwrap().to_string(), "Asia/Tokyo")
  assert_eq(@tz.Location::load("Japan").unwrap().to_string(), "Japan")
  assert_eq(@tz.Location::from_tzif_bytes(tzif_tokyo).unwrap().to_string(), "")
}

///|
test "DateTime renders its local date-time followed by the zone's name at that instant" {
  let base = tokyo_new_year_morning()
  assert_eq(base.to_string(), "2024-01-01 07:30:15.123456789 +09:00")
  assert_eq(base.to_utc().to_string(), "2023-12-31 22:30:15.123456789 UTC")
  let ny = @tz.Location::load("America/New_York").unwrap()
  assert_eq(
    @tz.DateTime::from_ymd_hms(2024, 7, 1, 12, 0, 0, ny)
    .single()
    .unwrap()
    .to_string(),
    "2024-07-01 12:00:00 EDT",
  )
  assert_eq(
    @tz.DateTime::from_ymd_hms(2024, 1, 1, 12, 0, 0, ny)
    .single()
    .unwrap()
    .to_string(),
    "2024-01-01 12:00:00 EST",
  )
}

///|
test "equal Utc and FixedOffset values hash equally and can key a Map" {
  assert_eq(@tz.Utc::new().hash(), @tz.Utc::new().hash())
  let a = @tz.FixedOffset::east(9 * 3600).unwrap()
  let b = @tz.FixedOffset::east(9 * 3600).unwrap()
  assert_eq(a.hash(), b.hash())
  assert_true(a.hash() != @tz.FixedOffset::east(0).unwrap().hash())
  let seen : Map[@tz.FixedOffset, Int] = Map([])
  seen[a] = 1
  assert_eq(seen.get(b), Some(1))
}

///|
test "DateTime hashing agrees with its Eq, which also compares the zone" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let utc = @tz.FixedOffset::east(0).unwrap()
  let a = @tz.DateTime::from_timestamp(1_000L, 0, tokyo).unwrap()
  let b = @tz.DateTime::from_timestamp(1_000L, 0, tokyo).unwrap()
  assert_eq(a.hash(), b.hash())
  assert_true(
    a.hash() != @tz.DateTime::from_timestamp(2_000L, 0, tokyo).unwrap().hash(),
  )
  assert_true(a != @tz.DateTime::from_timestamp(1_000L, 0, utc).unwrap())
  let seen : Map[@tz.DateTime[@tz.FixedOffset], Int] = Map([])
  seen[a] = 1
  assert_eq(seen.get(b), Some(1))
}

///|
test "Location and DateTime in a Location hash consistently with Eq" {
  let a = @tz.Location::load("Asia/Tokyo").unwrap()
  let b = @tz.Location::load("Asia/Tokyo").unwrap()
  assert_eq(a.hash(), b.hash())
  assert_true(a.hash() != @tz.Location::load("Japan").unwrap().hash())
  assert_eq(
    @tz.DateTime::from_timestamp(0L, 0, a).unwrap().hash(),
    @tz.DateTime::from_timestamp(0L, 0, b).unwrap().hash(),
  )
}

///|
test "TransitionBounds hashing agrees with its Eq" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let instant = @core.NaiveDateTime::from_timestamp(1_719_835_200L, 0).unwrap()
  let a = ny.transition_bounds(instant)
  let b = ny.transition_bounds(instant)
  assert_eq(a.hash(), b.hash())
  let other = ny.transition_bounds(
    @core.NaiveDateTime::from_timestamp(1_704_110_400L, 0).unwrap(),
  )
  assert_true(a.hash() != other.hash())
}
