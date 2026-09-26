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
