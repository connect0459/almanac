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

///|
test "iter defaults to Monday-first order, matching to_array" {
  let set = @core.WeekdaySet::from_array([@core.Sun, @core.Mon, @core.Wed])
  assert_eq(set.iter().collect(), set.to_array())
  assert_eq(set.iter().collect(), [@core.Mon, @core.Wed, @core.Sun])
}

///|
test "iter cycles from the given start weekday and wraps past Sunday" {
  let set = @core.WeekdaySet::from_array([@core.Mon, @core.Wed, @core.Sun])
  assert_eq(set.iter(start=@core.Sun).collect(), [
    @core.Sun,
    @core.Mon,
    @core.Wed,
  ])
  assert_eq(set.iter(start=@core.Wed).collect(), [
    @core.Wed,
    @core.Sun,
    @core.Mon,
  ])
  assert_eq(set.iter(start=@core.Thu).collect(), [
    @core.Sun,
    @core.Mon,
    @core.Wed,
  ])
}

///|
test "iter starts at the next member when the start weekday is not in the set" {
  let set = @core.WeekdaySet::from_array([@core.Mon, @core.Wed, @core.Fri])
  assert_eq(set.iter(start=@core.Tue).collect(), [
    @core.Wed,
    @core.Fri,
    @core.Mon,
  ])
}

///|
test "iter of the empty set yields nothing and of the full set yields all seven from the start" {
  assert_eq(@core.WeekdaySet::empty().iter(start=@core.Thu).collect(), [])
  assert_eq(@core.WeekdaySet::all().iter(start=@core.Thu).collect(), [
    @core.Thu,
    @core.Fri,
    @core.Sat,
    @core.Sun,
    @core.Mon,
    @core.Tue,
    @core.Wed,
  ])
}

///|
test "a for loop walks the Iter from iter, Monday first by default" {
  let set = @core.WeekdaySet::from_array([@core.Fri, @core.Tue])
  let seen : Array[@core.Weekday] = []
  for day in set.iter() {
    seen.push(day)
  }
  assert_eq(seen, [@core.Tue, @core.Fri])
  let from_saturday : Array[@core.Weekday] = []
  for day in set.iter(start=@core.Sat) {
    from_saturday.push(day)
  }
  assert_eq(from_saturday, [@core.Tue, @core.Fri])
}

///|
test "iter supports adapters and reports the member count as its size hint" {
  let set = @core.WeekdaySet::from_array([@core.Mon, @core.Wed, @core.Sun])
  assert_eq(set.iter(start=@core.Wed).take(2).map(d => d.name()).collect(), [
    "Wednesday", "Sunday",
  ])
  assert_eq(set.iter().size_hint(), Some(3))
  assert_eq(set.iter().count(), 3)
}

///|
test "iter does not change the set" {
  let set = @core.WeekdaySet::from_array([@core.Mon, @core.Wed])
  ignore(set.iter(start=@core.Wed).collect())
  assert_eq(set, @core.WeekdaySet::from_array([@core.Mon, @core.Wed]))
}

///|
test "iter_from yields members in cyclic order from the start with next" {
  let it = @core.WeekdaySet::from_array([@core.Mon, @core.Wed, @core.Sun]).iter_from(
    @core.Wed,
  )
  assert_eq(it.length(), 3)
  assert_eq(it.next(), Some(@core.Wed))
  assert_eq(it.next(), Some(@core.Sun))
  assert_eq(it.next(), Some(@core.Mon))
  assert_eq(it.next(), None)
  assert_eq(it.length(), 0)
}

///|
test "iter_from next_back yields members from the end of the cycle" {
  let it = @core.WeekdaySet::from_array([@core.Mon, @core.Wed, @core.Sun]).iter_from(
    @core.Sun,
  )
  assert_eq(it.next_back(), Some(@core.Wed))
  assert_eq(it.next_back(), Some(@core.Mon))
  assert_eq(it.next_back(), Some(@core.Sun))
  assert_eq(it.next_back(), None)
}

///|
test "iter_from converges from both ends without skipping or repeating a weekday" {
  let it = @core.WeekdaySet::from_array([
    @core.Mon,
    @core.Tue,
    @core.Wed,
    @core.Thu,
  ]).iter_from(@core.Mon)
  assert_eq(it.next(), Some(@core.Mon))
  assert_eq(it.next_back(), Some(@core.Thu))
  assert_eq(it.length(), 2)
  assert_eq(it.next(), Some(@core.Tue))
  assert_eq(it.next_back(), Some(@core.Wed))
  assert_eq(it.next(), None)
  assert_eq(it.next_back(), None)
}

///|
test "the Iter from an iter_from iterator continues from its current position" {
  let it = @core.WeekdaySet::from_array([@core.Mon, @core.Wed, @core.Sun]).iter_from(
    @core.Mon,
  )
  ignore(it.next())
  ignore(it.next_back())
  assert_eq(it.iter().collect(), [@core.Wed])
  assert_eq(it.next(), None)
}
