///|
test "iter_days yields successive dates one day apart" {
  let it = @core.NaiveDate::from_ymd(2024, 2, 27).unwrap().iter_days()
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(2024, 2, 27).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(2024, 2, 28).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(2024, 2, 29).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(2024, 3, 1).unwrap()))
}

///|
test "iter_days next_back yields successive dates one day apart in reverse" {
  let it = @core.NaiveDate::from_ymd(2024, 2, 27).unwrap().iter_days()
  assert_eq(
    it.next_back(),
    Some(@core.NaiveDate::from_ymd(275760, 9, 13).unwrap()),
  )
  assert_eq(
    it.next_back(),
    Some(@core.NaiveDate::from_ymd(275760, 9, 12).unwrap()),
  )
}

///|
test "iter_days reaches and includes its practical upper bound when starting near it" {
  let it = @core.NaiveDate::from_ymd(275760, 9, 10).unwrap().iter_days()
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(275760, 9, 10).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(275760, 9, 11).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(275760, 9, 12).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(275760, 9, 13).unwrap()))
  assert_eq(it.next(), None)
}

///|
test "iter_days interleaving next and next_back yields every date near the bound exactly once" {
  let it = @core.NaiveDate::from_ymd(275760, 9, 10).unwrap().iter_days()
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(275760, 9, 10).unwrap()))
  assert_eq(
    it.next_back(),
    Some(@core.NaiveDate::from_ymd(275760, 9, 13).unwrap()),
  )
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(275760, 9, 11).unwrap()))
  assert_eq(
    it.next_back(),
    Some(@core.NaiveDate::from_ymd(275760, 9, 12).unwrap()),
  )
  assert_eq(it.next(), None)
  assert_eq(it.next_back(), None)
}

///|
test "iter_days length reports the number of dates remaining, decreasing as it is consumed" {
  let it = @core.NaiveDate::from_ymd(275760, 9, 10).unwrap().iter_days()
  assert_eq(it.length(), 4)
  let _ = it.next()
  assert_eq(it.length(), 3)
  let _ = it.next_back()
  assert_eq(it.length(), 2)
}

///|
test "iter_days yields nothing when self is already beyond the practical upper bound" {
  let it = @core.NaiveDate::from_ymd(275760, 9, 14).unwrap().iter_days()
  assert_eq(it.next(), None)
  assert_eq(it.next_back(), None)
  assert_eq(it.length(), 0)
}

///|
test "iter_weeks yields successive dates one week apart" {
  let it = @core.NaiveDate::from_ymd(2016, 2, 27).unwrap().iter_weeks()
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(2016, 2, 27).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(2016, 3, 5).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(2016, 3, 12).unwrap()))
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(2016, 3, 19).unwrap()))
}

///|
test "iter_weeks next_back yields the same weeks in reverse when the range is exactly week-aligned to the bound" {
  // 275760-08-23 is exactly 3 weeks (21 days) before the practical upper
  // bound, 275760-09-13, so iter_weeks' alignment reaches it exactly.
  let it = @core.NaiveDate::from_ymd(275760, 8, 23).unwrap().iter_weeks()
  assert_eq(
    it.next_back(),
    Some(@core.NaiveDate::from_ymd(275760, 9, 13).unwrap()),
  )
  assert_eq(
    it.next_back(),
    Some(@core.NaiveDate::from_ymd(275760, 9, 6).unwrap()),
  )
}

///|
test "iter_weeks length reports the number of weekly steps remaining, decreasing as it is consumed" {
  let it = @core.NaiveDate::from_ymd(275760, 8, 23).unwrap().iter_weeks()
  assert_eq(it.length(), 4)
  let _ = it.next()
  assert_eq(it.length(), 3)
}

///|
test "iter_weeks yields a single date when less than a full week remains before the bound" {
  let it = @core.NaiveDate::from_ymd(275760, 9, 11).unwrap().iter_weeks()
  assert_eq(it.length(), 1)
  assert_eq(it.next(), Some(@core.NaiveDate::from_ymd(275760, 9, 11).unwrap()))
  assert_eq(it.next(), None)
}

///|
test "iter_weeks yields nothing when self is already beyond the practical upper bound" {
  let it = @core.NaiveDate::from_ymd(275760, 9, 14).unwrap().iter_weeks()
  assert_eq(it.next(), None)
  assert_eq(it.next_back(), None)
  assert_eq(it.length(), 0)
}

///|
test "a for loop walks iter_days directly and stops at break" {
  let start = @core.NaiveDate::from_ymd(2024, 2, 27).unwrap()
  let seen : Array[@core.NaiveDate] = []
  for date in start.iter_days() {
    if seen.length() == 4 {
      break
    }
    seen.push(date)
  }
  assert_eq(seen, [
    @core.NaiveDate::from_ymd(2024, 2, 27).unwrap(),
    @core.NaiveDate::from_ymd(2024, 2, 28).unwrap(),
    @core.NaiveDate::from_ymd(2024, 2, 29).unwrap(),
    @core.NaiveDate::from_ymd(2024, 3, 1).unwrap(),
  ])
}

///|
test "iter_days supports iterator adapters through iter" {
  let start = @core.NaiveDate::from_ymd(2024, 2, 27).unwrap()
  let days = start.iter_days().iter().take(4).map(d => d.day()).collect()
  assert_eq(days, [27, 28, 29, 1])
}

///|
test "iter_days for loop terminates after yielding its upper bound" {
  let start = @core.NaiveDate::from_ymd(275760, 9, 11).unwrap()
  let seen : Array[@core.NaiveDate] = []
  for date in start.iter_days() {
    seen.push(date)
  }
  assert_eq(seen, [
    @core.NaiveDate::from_ymd(275760, 9, 11).unwrap(),
    @core.NaiveDate::from_ymd(275760, 9, 12).unwrap(),
    @core.NaiveDate::from_ymd(275760, 9, 13).unwrap(),
  ])
}

///|
test "iter_days iter reports the remaining count as its size hint" {
  let start = @core.NaiveDate::from_ymd(275760, 9, 11).unwrap()
  assert_eq(start.iter_days().iter().size_hint(), Some(3))
  assert_eq(start.iter_days().iter().count(), 3)
}

///|
test "iter continues from where the iterator was and shares its state" {
  let it = @core.NaiveDate::from_ymd(275760, 9, 10).unwrap().iter_days()
  ignore(it.next())
  let rest = it.iter().collect()
  assert_eq(rest.length(), 3)
  assert_eq(it.next(), None)
}

///|
test "iter after next_back stops before the dates taken from the back" {
  let it = @core.NaiveDate::from_ymd(275760, 9, 10).unwrap().iter_days()
  ignore(it.next_back())
  assert_eq(it.iter().collect(), [
    @core.NaiveDate::from_ymd(275760, 9, 10).unwrap(),
    @core.NaiveDate::from_ymd(275760, 9, 11).unwrap(),
    @core.NaiveDate::from_ymd(275760, 9, 12).unwrap(),
  ])
}

///|
test "iter_weeks works in a for loop and with adapters" {
  let start = @core.NaiveDate::from_ymd(2024, 1, 1).unwrap()
  let seen : Array[@core.NaiveDate] = []
  for date in start.iter_weeks() {
    if seen.length() == 3 {
      break
    }
    seen.push(date)
  }
  assert_eq(seen, [
    @core.NaiveDate::from_ymd(2024, 1, 1).unwrap(),
    @core.NaiveDate::from_ymd(2024, 1, 8).unwrap(),
    @core.NaiveDate::from_ymd(2024, 1, 15).unwrap(),
  ])
  let days = start.iter_weeks().iter().take(3).map(d => d.day()).collect()
  assert_eq(days, [1, 8, 15])
}

///|
test "iter_weeks iter reports the remaining count as its size hint and terminates at the bound" {
  let start = @core.NaiveDate::from_ymd(275760, 8, 30).unwrap()
  let iter = start.iter_weeks().iter()
  assert_eq(iter.size_hint(), Some(start.iter_weeks().length()))
  assert_eq(iter.count(), start.iter_weeks().length())
}
