///|
test "Utc::now() returns an instant after a known past reference date" {
  let reference = @core.NaiveDateTime::from_timestamp(1_700_000_000L, 0).unwrap()
  assert_true(@tz.Utc::now().naive_utc().timestamp() > reference.timestamp())
}

///|
test "Utc::now()'s time zone is Utc" {
  assert_eq(@tz.Utc::now().timezone(), @tz.Utc::new())
}

///|
test "Utc::now() has no precision finer than a millisecond" {
  for _ in 0..<100 {
    assert_eq(@tz.Utc::now().naive_utc().nanosecond() % 1_000_000, 0)
  }
}
