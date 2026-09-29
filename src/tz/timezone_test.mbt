///|
test "MappedLocalTime distinguishes Single, Ambiguous, and Absent as unequal" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_true(@tz.Single(a) != @tz.Single(b))
  assert_true(@tz.Single(a) != @tz.Ambiguous(a, b))
  assert_true(
    (@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]) != @tz.Single(a),
  )
  assert_eq(@tz.Ambiguous(a, b), @tz.Ambiguous(a, b))
}

///|
test "single returns the offset only when the result is unambiguous" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_eq(@tz.Single(a).single(), Some(a))
  assert_eq(@tz.Ambiguous(a, b).single(), None)
  assert_eq((@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]).single(), None)
}

///|
test "earliest returns the first offset of an ambiguous fold" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_eq(@tz.Single(a).earliest(), Some(a))
  assert_eq(@tz.Ambiguous(a, b).earliest(), Some(a))
  assert_eq(
    (@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]).earliest(),
    None,
  )
}

///|
test "latest returns the second offset of an ambiguous fold" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  assert_eq(@tz.Single(a).latest(), Some(a))
  assert_eq(@tz.Ambiguous(a, b).latest(), Some(b))
  assert_eq((@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]).latest(), None)
}

///|
test "map transforms every offset carried by the result" {
  let a = @tz.FixedOffset::east(3600).unwrap()
  let b = @tz.FixedOffset::east(7200).unwrap()
  let bump = fn(offset : @tz.FixedOffset) -> @tz.FixedOffset {
    @tz.FixedOffset::east(offset.local_minus_utc() + 1).unwrap()
  }
  assert_eq(@tz.Single(a).map(bump), @tz.Single(bump(a)))
  assert_eq(@tz.Ambiguous(a, b).map(bump), @tz.Ambiguous(bump(a), bump(b)))
  assert_eq(
    (@tz.Absent : @tz.MappedLocalTime[@tz.FixedOffset]).map(bump),
    @tz.Absent,
  )
}
