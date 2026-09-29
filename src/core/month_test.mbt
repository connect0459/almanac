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
