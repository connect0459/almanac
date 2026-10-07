///|
fn[T : @core.Datelike] ymd_facts(value : T) -> (Int, Int, Int, Int, Int, Bool) {
  (
    value.year(),
    value.month().number(),
    value.day(),
    value.ordinal(),
    value.quarter(),
    value.leap_year(),
  )
}

///|
fn[T : @core.Timelike] hms_facts(value : T) -> (Int, Int, Int, Int, Int) {
  (
    value.hour(),
    value.minute(),
    value.second(),
    value.nanosecond(),
    value.num_seconds_from_midnight(),
  )
}

///|
fn local_sample() -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 2, 29).unwrap(),
    @core.NaiveTime::from_hms_nano(23, 30, 15, 250_000_000).unwrap(),
  )
}

///|
test "a DateTime in Utc reads its UTC calendar and clock through Datelike and Timelike" {
  let dt = @tz.DateTime::from_utc(local_sample(), @tz.Utc::new())
  assert_eq(ymd_facts(dt), (2024, 2, 29, 60, 1, true))
  assert_eq(hms_facts(dt), (23, 30, 15, 250_000_000, 84615))
}

///|
test "a DateTime in a fixed offset reads its local calendar and clock, not UTC" {
  let plus9 = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = @tz.DateTime::from_utc(local_sample(), plus9)
  assert_eq(ymd_facts(dt), (2024, 3, 1, 61, 1, true))
  assert_eq(hms_facts(dt), (8, 30, 15, 250_000_000, 30615))
  assert_eq(dt.weekday(), @core.Fri)
}

///|
test "Datelike and Timelike on a DateTime agree with its own accessors across zones" {
  let plus9 = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = @tz.DateTime::from_utc(local_sample(), plus9)
  assert_eq(
    dt.iso_week(),
    @core.NaiveDate::from_ymd(2024, 3, 1).unwrap().iso_week(),
  )
  assert_eq(
    dt.num_days_from_ce(),
    @core.NaiveDate::from_ymd(2024, 3, 1).unwrap().num_days_from_ce(),
  )
  assert_eq(dt.hour12().hour(), 8)
  assert_eq(dt.num_days_in_month(), 31)
  assert_eq(dt.month0(), 2)
  assert_eq(dt.day0(), 0)
  assert_eq(dt.ordinal0(), 60)
}
