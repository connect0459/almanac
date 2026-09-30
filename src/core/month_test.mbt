///|
test "succ advances to the next month and wraps from December to January" {
  for
    case in [
      (@core.Jan, @core.Feb),
      (@core.Feb, @core.Mar),
      (@core.Mar, @core.Apr),
      (@core.Apr, @core.May),
      (@core.May, @core.Jun),
      (@core.Jun, @core.Jul),
      (@core.Jul, @core.Aug),
      (@core.Aug, @core.Sep),
      (@core.Sep, @core.Oct),
      (@core.Oct, @core.Nov),
      (@core.Nov, @core.Dec),
      (@core.Dec, @core.Jan),
    ] {
    let (month, expected) = case
    assert_eq(month.succ(), expected)
  }
}

///|
test "pred goes back to the previous month and wraps from January to December" {
  for
    case in [
      (@core.Jan, @core.Dec),
      (@core.Feb, @core.Jan),
      (@core.Mar, @core.Feb),
      (@core.Apr, @core.Mar),
      (@core.May, @core.Apr),
      (@core.Jun, @core.May),
      (@core.Jul, @core.Jun),
      (@core.Aug, @core.Jul),
      (@core.Sep, @core.Aug),
      (@core.Oct, @core.Sep),
      (@core.Nov, @core.Oct),
      (@core.Dec, @core.Nov),
    ] {
    let (month, expected) = case
    assert_eq(month.pred(), expected)
  }
}

///|
test "number_from_month counts from 1 starting at January" {
  for
    case in [
      (@core.Jan, 1),
      (@core.Feb, 2),
      (@core.Mar, 3),
      (@core.Apr, 4),
      (@core.May, 5),
      (@core.Jun, 6),
      (@core.Jul, 7),
      (@core.Aug, 8),
      (@core.Sep, 9),
      (@core.Oct, 10),
      (@core.Nov, 11),
      (@core.Dec, 12),
    ] {
    let (month, expected) = case
    assert_eq(month.number_from_month(), expected)
  }
}

///|
test "name returns the English month name" {
  for
    case in [
      (@core.Jan, "January"),
      (@core.Feb, "February"),
      (@core.Mar, "March"),
      (@core.Apr, "April"),
      (@core.May, "May"),
      (@core.Jun, "June"),
      (@core.Jul, "July"),
      (@core.Aug, "August"),
      (@core.Sep, "September"),
      (@core.Oct, "October"),
      (@core.Nov, "November"),
      (@core.Dec, "December"),
    ] {
    let (month, expected) = case
    assert_eq(month.name(), expected)
  }
}

///|
test "num_days returns the length of 31-day months regardless of year" {
  for
    month in [
      @core.Jan,
      @core.Mar,
      @core.May,
      @core.Jul,
      @core.Aug,
      @core.Oct,
      @core.Dec,
    ] {
    assert_eq(month.num_days(2023), 31)
  }
}

///|
test "num_days returns the length of 30-day months regardless of year" {
  for month in [@core.Apr, @core.Jun, @core.Sep, @core.Nov] {
    assert_eq(month.num_days(2023), 30)
  }
}

///|
test "num_days for February depends on whether the year is a leap year" {
  assert_eq(@core.Feb.num_days(2023), 28)
  assert_eq(@core.Feb.num_days(2024), 29)
  assert_eq(@core.Feb.num_days(1900), 28)
  assert_eq(@core.Feb.num_days(2000), 29)
}

///|
test "to_string renders the English month name" {
  assert_eq(@core.Sep.to_string(), "September")
}

///|
test "from_number returns the month for each number in 1..=12" {
  for n in 1..<=12 {
    assert_eq(
      @core.Month::from_number(n).map(fn(m) { m.number_from_month() }),
      Some(n),
    )
  }
}

///|
test "from_number rejects numbers outside 1..=12" {
  assert_eq(@core.Month::from_number(0), None)
  assert_eq(@core.Month::from_number(13), None)
  assert_eq(@core.Month::from_number(-1), None)
}

///|
test "months are ordered from January to December" {
  assert_true(@core.Jan < @core.Feb)
  assert_true(@core.Nov < @core.Dec)
  assert_true(@core.Dec > @core.Jan)
  assert_true(@core.Mar <= @core.Mar)
  assert_true(@core.Mar >= @core.Mar)
  assert_eq(@core.Jun.compare(@core.Jun), 0)
}

///|
test "months hash equally when equal and work as map keys" {
  assert_eq(@core.Jan.hash(), @core.Dec.succ().hash())
  let seen : Map[@core.Month, Int] = Map([])
  seen[@core.Jan] = 1
  seen[@core.Dec.succ()] = seen.get(@core.Jan).unwrap() + 1
  seen[@core.Feb] = 5
  assert_eq(seen.length(), 2)
  assert_eq(seen.get(@core.Jan), Some(2))
}

///|
test "from_name accepts each full English month name" {
  for
    case in [
      ("January", @core.Jan),
      ("February", @core.Feb),
      ("March", @core.Mar),
      ("April", @core.Apr),
      ("May", @core.May),
      ("June", @core.Jun),
      ("July", @core.Jul),
      ("August", @core.Aug),
      ("September", @core.Sep),
      ("October", @core.Oct),
      ("November", @core.Nov),
      ("December", @core.Dec),
    ] {
    let (name, month) = case
    assert_eq(@core.Month::from_name(name), Some(month))
  }
}

///|
test "from_name accepts each three-letter abbreviation" {
  for
    case in [
      ("Jan", @core.Jan),
      ("Feb", @core.Feb),
      ("Mar", @core.Mar),
      ("Apr", @core.Apr),
      ("May", @core.May),
      ("Jun", @core.Jun),
      ("Jul", @core.Jul),
      ("Aug", @core.Aug),
      ("Sep", @core.Sep),
      ("Oct", @core.Oct),
      ("Nov", @core.Nov),
      ("Dec", @core.Dec),
    ] {
    let (name, month) = case
    assert_eq(@core.Month::from_name(name), Some(month))
  }
}

///|
test "from_name ignores ASCII letter case" {
  assert_eq(@core.Month::from_name("JANUARY"), Some(@core.Jan))
  assert_eq(@core.Month::from_name("january"), Some(@core.Jan))
  assert_eq(@core.Month::from_name("jAn"), Some(@core.Jan))
  assert_eq(@core.Month::from_name("DEC"), Some(@core.Dec))
}

///|
test "from_name inverts name for every month" {
  for number in 1..<=12 {
    let month = @core.Month::from_number(number).unwrap()
    assert_eq(@core.Month::from_name(month.name()), Some(month))
  }
}

///|
test "from_name rejects anything but an exact abbreviation or full name" {
  for
    bad in [
      "", "J", "Ja", "Janu", "Januar", "Sept", "Jan.", " Jan", "Jan ", "Jann", "Janvier",
      "1", "01", "\u{FF2A}\u{FF21}\u{FF2E}", "J\u{E5}n", "Ma",
    ] {
    assert_eq(@core.Month::from_name(bad), None)
  }
}

///|
test "Month add wraps around the year in both directions" {
  assert_eq(@core.Dec.add(1), @core.Jan)
  assert_eq(@core.Jan.add(-1), @core.Dec)
  assert_eq(@core.Mar.add(0), @core.Mar)
  assert_eq(@core.Nov.add(3), @core.Feb)
  assert_eq(@core.Feb.add(-3), @core.Nov)
}

///|
test "Month add of a whole number of years returns the same month" {
  assert_eq(@core.Jul.add(12), @core.Jul)
  assert_eq(@core.Jul.add(-24), @core.Jul)
}

///|
test "Month add agrees with repeated succ and pred" {
  for n in -30..<=30 {
    let mut expected = @core.Sep
    for _ in 0..<n.abs() {
      expected = if n > 0 { expected.succ() } else { expected.pred() }
    }
    assert_eq(@core.Sep.add(n), expected)
  }
}

///|
test "Month add accepts the extreme Int values without overflowing" {
  assert_eq(@core.Jan.add(2147483647), @core.Aug)
  assert_eq(@core.Jan.add(-2147483648), @core.May)
}
