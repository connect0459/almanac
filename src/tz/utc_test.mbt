///|
test "Utc's offset_from_utc is always zero, regardless of the given datetime" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    @tz.Utc::new().offset_from_utc(dt),
    @tz.FixedOffset::east(0).unwrap(),
  )
}

///|
test "Utc's offset_from_local reports a single zero offset, never ambiguous or absent" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    @tz.Utc::new().offset_from_local(dt),
    @tz.Single(@tz.FixedOffset::east(0).unwrap()),
  )
}
