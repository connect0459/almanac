///|
test "empty set contains no weekday" {
  for
    day in [
      @core.Mon,
      @core.Tue,
      @core.Wed,
      @core.Thu,
      @core.Fri,
      @core.Sat,
      @core.Sun,
    ] {
    assert_false(@core.WeekdaySet::empty().contains(day))
  }
  assert_true(@core.WeekdaySet::empty().is_empty())
  assert_eq(@core.WeekdaySet::empty().length(), 0)
}

///|
test "all set contains every weekday" {
  for
    day in [
      @core.Mon,
      @core.Tue,
      @core.Wed,
      @core.Thu,
      @core.Fri,
      @core.Sat,
      @core.Sun,
    ] {
    assert_true(@core.WeekdaySet::all().contains(day))
  }
  assert_false(@core.WeekdaySet::all().is_empty())
  assert_eq(@core.WeekdaySet::all().length(), 7)
}

///|
test "single builds a set containing exactly that weekday" {
  let s = @core.WeekdaySet::single(@core.Wed)
  assert_true(s.contains(@core.Wed))
  assert_false(s.contains(@core.Tue))
  assert_false(s.contains(@core.Thu))
  assert_eq(s.length(), 1)
}

///|
test "from_array builds a set from multiple weekdays" {
  let s = @core.WeekdaySet::from_array([@core.Mon, @core.Wed, @core.Fri])
  assert_eq(s.to_array(), [@core.Mon, @core.Wed, @core.Fri])
}

///|
test "from_array of an empty array yields the empty set" {
  assert_eq(@core.WeekdaySet::from_array([]), @core.WeekdaySet::empty())
}

///|
test "single_day recognizes a set with exactly one member" {
  for
    day in [
      @core.Mon,
      @core.Tue,
      @core.Wed,
      @core.Thu,
      @core.Fri,
      @core.Sat,
      @core.Sun,
    ] {
    assert_eq(@core.WeekdaySet::single(day).single_day(), Some(day))
  }
}

///|
test "single_day is none for the empty set" {
  assert_eq(@core.WeekdaySet::empty().single_day(), None)
}

///|
test "single_day is none for a set with more than one member" {
  assert_eq(
    @core.WeekdaySet::from_array([@core.Mon, @core.Tue]).single_day(),
    None,
  )
}

///|
test "insert adds a weekday without disturbing existing members" {
  let s = @core.WeekdaySet::single(@core.Mon).insert(@core.Tue)
  assert_true(s.contains(@core.Mon))
  assert_true(s.contains(@core.Tue))
  assert_eq(s.length(), 2)
}

///|
test "insert is idempotent for an already-present weekday" {
  let s = @core.WeekdaySet::single(@core.Mon).insert(@core.Mon)
  assert_eq(s, @core.WeekdaySet::single(@core.Mon))
}

///|
test "remove drops a weekday without disturbing other members" {
  let s = @core.WeekdaySet::from_array([@core.Mon, @core.Tue]).remove(@core.Mon)
  assert_eq(s, @core.WeekdaySet::single(@core.Tue))
}

///|
test "remove is a no-op for an absent weekday" {
  let s = @core.WeekdaySet::single(@core.Mon).remove(@core.Tue)
  assert_eq(s, @core.WeekdaySet::single(@core.Mon))
}

///|
test "is_subset holds when every member of self is in other" {
  assert_true(
    @core.WeekdaySet::single(@core.Mon).is_subset(@core.WeekdaySet::all()),
  )
  assert_true(
    @core.WeekdaySet::empty().is_subset(@core.WeekdaySet::single(@core.Mon)),
  )
}

///|
test "is_subset fails when self has a member missing from other" {
  assert_false(
    @core.WeekdaySet::single(@core.Mon).is_subset(@core.WeekdaySet::empty()),
  )
}

///|
test "intersection keeps only weekdays common to both sets" {
  let a = @core.WeekdaySet::from_array([@core.Mon, @core.Tue])
  let b = @core.WeekdaySet::from_array([@core.Tue, @core.Wed])
  assert_eq(a.intersection(b), @core.WeekdaySet::single(@core.Tue))
}

///|
test "union combines weekdays from both sets" {
  let a = @core.WeekdaySet::single(@core.Mon)
  let b = @core.WeekdaySet::single(@core.Tue)
  assert_eq(a.union(b), @core.WeekdaySet::from_array([@core.Mon, @core.Tue]))
}

///|
test "symmetric_difference keeps weekdays in exactly one set" {
  let a = @core.WeekdaySet::from_array([@core.Mon, @core.Tue])
  let b = @core.WeekdaySet::from_array([@core.Tue, @core.Wed])
  assert_eq(
    a.symmetric_difference(b),
    @core.WeekdaySet::from_array([@core.Mon, @core.Wed]),
  )
}

///|
test "difference keeps weekdays only in self" {
  let a = @core.WeekdaySet::from_array([@core.Mon, @core.Tue])
  let b = @core.WeekdaySet::single(@core.Tue)
  assert_eq(a.difference(b), @core.WeekdaySet::single(@core.Mon))
}

///|
test "first returns the earliest weekday starting from Monday" {
  assert_eq(
    @core.WeekdaySet::from_array([@core.Wed, @core.Fri]).first(),
    Some(@core.Wed),
  )
  assert_eq(@core.WeekdaySet::all().first(), Some(@core.Mon))
}

///|
test "first is none for the empty set" {
  assert_eq(@core.WeekdaySet::empty().first(), None)
}

///|
test "last returns the latest weekday starting from Sunday" {
  assert_eq(
    @core.WeekdaySet::from_array([@core.Mon, @core.Wed]).last(),
    Some(@core.Wed),
  )
  assert_eq(@core.WeekdaySet::all().last(), Some(@core.Sun))
}

///|
test "last is none for the empty set" {
  assert_eq(@core.WeekdaySet::empty().last(), None)
}

///|
test "to_array lists members in Monday-to-Sunday order regardless of insertion order" {
  let s = @core.WeekdaySet::from_array([@core.Sun, @core.Mon, @core.Fri])
  assert_eq(s.to_array(), [@core.Mon, @core.Fri, @core.Sun])
}

///|
test "to_array of the empty set is empty" {
  assert_eq(@core.WeekdaySet::empty().to_array(), [])
}

///|
test "equal sets compare equal regardless of construction path" {
  assert_eq(
    @core.WeekdaySet::from_array([@core.Mon, @core.Tue]),
    @core.WeekdaySet::single(@core.Mon).insert(@core.Tue),
  )
}

///|
test "to_string lists the members' short names in Monday-first order" {
  assert_eq(
    @core.WeekdaySet::from_array([@core.Sun, @core.Mon, @core.Fri]).to_string(),
    "[Mon, Fri, Sun]",
  )
  assert_eq(@core.WeekdaySet::single(@core.Wed).to_string(), "[Wed]")
  assert_eq(
    @core.WeekdaySet::all().to_string(),
    "[Mon, Tue, Wed, Thu, Fri, Sat, Sun]",
  )
}

///|
test "to_string renders the empty set as empty brackets" {
  assert_eq(@core.WeekdaySet::empty().to_string(), "[]")
}

///|
test "equal weekday sets hash equally and work as map keys" {
  let a = @core.WeekdaySet::from_array([@core.Mon, @core.Fri])
  let b = @core.WeekdaySet::single(@core.Fri).insert(@core.Mon)
  assert_eq(a, b)
  assert_eq(a.hash(), b.hash())
  let seen : Map[@core.WeekdaySet, Int] = Map([])
  seen[a] = 1
  seen[@core.WeekdaySet::empty()] = 2
  assert_eq(seen.length(), 2)
  assert_eq(seen.get(b), Some(1))
}

///|
test "the default weekday set is empty" {
  let set : @core.WeekdaySet = Default::default()
  assert_eq(set, @core.WeekdaySet::empty())
}
