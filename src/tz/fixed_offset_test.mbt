///|
test "east constructs an offset whose local_minus_utc reports the given seconds" {
  let offset = @tz.FixedOffset::east(3600).unwrap()
  assert_eq(offset.local_minus_utc(), 3600)
}

///|
test "west constructs an offset with the negated seconds" {
  let offset = @tz.FixedOffset::west(3600).unwrap()
  assert_eq(offset.local_minus_utc(), -3600)
}

///|
test "east and west reject an offset outside plus-or-minus 23:59:59" {
  assert_eq(@tz.FixedOffset::east(86400), None)
  assert_eq(@tz.FixedOffset::east(-86400), None)
  assert_eq(@tz.FixedOffset::west(86400), None)
  assert_true(@tz.FixedOffset::east(86399) is Some(_))
  assert_true(@tz.FixedOffset::east(-86399) is Some(_))
}

///|
test "offset_from_utc returns the fixed offset unchanged regardless of the given datetime" {
  let offset = @tz.FixedOffset::east(1800).unwrap()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  assert_eq(offset.offset_from_utc(dt), offset)
}

///|
test "offset_from_local reports a single unambiguous offset, matching offset_from_utc" {
  let offset = @tz.FixedOffset::west(1800).unwrap()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  assert_eq(offset.offset_from_local(dt), @tz.Single(offset))
}

///|
test "tz_name renders a positive offset as a colon-separated sign, hour, and minute" {
  let offset = @tz.FixedOffset::east(9 * 3600).unwrap()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  assert_eq(offset.tz_name(dt), "+09:00")
}

///|
test "tz_name renders a negative offset with the same colon-separated form" {
  let offset = @tz.FixedOffset::west(5 * 3600).unwrap()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  assert_eq(offset.tz_name(dt), "-05:00")
}

///|
test "tz_name renders a zero offset as \"+00:00\"" {
  let offset = @tz.FixedOffset::east(0).unwrap()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  assert_eq(offset.tz_name(dt), "+00:00")
}

///|
test "tz_name includes a seconds component when the offset is not a whole minute" {
  let offset = @tz.FixedOffset::east(-17762).unwrap()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  assert_eq(offset.tz_name(dt), "-04:56:02")
}
