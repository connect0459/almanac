///|
test "MappedLocalTime distinguishes Single, Ambiguous, and Absent as unequal" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_true(@tz.Single(a) != @tz.Single(b))
  assert_true(@tz.Single(a) != @tz.Ambiguous(a, b))
  assert_true((@tz.Absent : @tz.MappedLocalTime) != @tz.Single(a))
  assert_eq(@tz.Ambiguous(a, b), @tz.Ambiguous(a, b))
}
