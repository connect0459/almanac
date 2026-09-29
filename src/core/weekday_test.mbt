///|
test "succ advances to the next day and wraps from Sunday to Monday" {
  for
    case in [
      (@core.Mon, @core.Tue),
      (@core.Tue, @core.Wed),
      (@core.Wed, @core.Thu),
      (@core.Thu, @core.Fri),
      (@core.Fri, @core.Sat),
      (@core.Sat, @core.Sun),
      (@core.Sun, @core.Mon),
    ] {
    let (day, expected) = case
    assert_eq(day.succ(), expected)
  }
}

///|
test "pred goes back to the previous day and wraps from Monday to Sunday" {
  for
    case in [
      (@core.Mon, @core.Sun),
      (@core.Tue, @core.Mon),
      (@core.Wed, @core.Tue),
      (@core.Thu, @core.Wed),
      (@core.Fri, @core.Thu),
      (@core.Sat, @core.Fri),
      (@core.Sun, @core.Sat),
    ] {
    let (day, expected) = case
    assert_eq(day.pred(), expected)
  }
}

///|
test "num_days_from_monday counts from 0 starting at Monday" {
  for
    case in [
      (@core.Mon, 0),
      (@core.Tue, 1),
      (@core.Wed, 2),
      (@core.Thu, 3),
      (@core.Fri, 4),
      (@core.Sat, 5),
      (@core.Sun, 6),
    ] {
    let (day, expected) = case
    assert_eq(day.num_days_from_monday(), expected)
  }
}

///|
test "num_days_from_sunday counts from 0 starting at Sunday" {
  for
    case in [
      (@core.Mon, 1),
      (@core.Tue, 2),
      (@core.Wed, 3),
      (@core.Thu, 4),
      (@core.Fri, 5),
      (@core.Sat, 6),
      (@core.Sun, 0),
    ] {
    let (day, expected) = case
    assert_eq(day.num_days_from_sunday(), expected)
  }
}

///|
test "number_from_monday counts from 1 starting at Monday" {
  for
    case in [
      (@core.Mon, 1),
      (@core.Tue, 2),
      (@core.Wed, 3),
      (@core.Thu, 4),
      (@core.Fri, 5),
      (@core.Sat, 6),
      (@core.Sun, 7),
    ] {
    let (day, expected) = case
    assert_eq(day.number_from_monday(), expected)
  }
}

///|
test "number_from_sunday counts from 1 starting at Sunday" {
  for
    case in [
      (@core.Mon, 2),
      (@core.Tue, 3),
      (@core.Wed, 4),
      (@core.Thu, 5),
      (@core.Fri, 6),
      (@core.Sat, 7),
      (@core.Sun, 1),
    ] {
    let (day, expected) = case
    assert_eq(day.number_from_sunday(), expected)
  }
}

///|
test "days_since counts zero for the same weekday" {
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
    assert_eq(day.days_since(day), 0)
  }
}

///|
test "days_since counts the days elapsed since an earlier weekday" {
  for
    case in [
      (@core.Mon, @core.Mon, 0),
      (@core.Sun, @core.Tue, 5),
      (@core.Wed, @core.Sun, 3),
      (@core.Tue, @core.Fri, 4),
    ] {
    let (day, other, expected) = case
    assert_eq(day.days_since(other), expected)
  }
}

///|
test "days_since from Monday agrees with num_days_from_monday" {
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
    assert_eq(day.days_since(@core.Mon), day.num_days_from_monday())
  }
}

///|
test "days_since from Sunday agrees with num_days_from_sunday" {
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
    assert_eq(day.days_since(@core.Sun), day.num_days_from_sunday())
  }
}

///|
test "name returns the English weekday name" {
  for
    case in [
      (@core.Mon, "Monday"),
      (@core.Tue, "Tuesday"),
      (@core.Wed, "Wednesday"),
      (@core.Thu, "Thursday"),
      (@core.Fri, "Friday"),
      (@core.Sat, "Saturday"),
      (@core.Sun, "Sunday"),
    ] {
    let (day, expected) = case
    assert_eq(day.name(), expected)
  }
}

///|
test "to_string renders the English weekday name" {
  assert_eq(@core.Wed.to_string(), "Wednesday")
}

///|
test "from_number_from_monday inverts number_from_monday" {
  for n in 1..<=7 {
    assert_eq(
      @core.Weekday::from_number_from_monday(n).map(fn(d) {
        d.number_from_monday()
      }),
      Some(n),
    )
  }
}

///|
test "from_number_from_sunday inverts number_from_sunday" {
  for n in 1..<=7 {
    assert_eq(
      @core.Weekday::from_number_from_sunday(n).map(fn(d) {
        d.number_from_sunday()
      }),
      Some(n),
    )
  }
}

///|
test "from_num_days_from_monday inverts num_days_from_monday" {
  for n in 0..<=6 {
    assert_eq(
      @core.Weekday::from_num_days_from_monday(n).map(fn(d) {
        d.num_days_from_monday()
      }),
      Some(n),
    )
  }
}

///|
test "from_num_days_from_sunday inverts num_days_from_sunday" {
  for n in 0..<=6 {
    assert_eq(
      @core.Weekday::from_num_days_from_sunday(n).map(fn(d) {
        d.num_days_from_sunday()
      }),
      Some(n),
    )
  }
}

///|
test "weekday from-number constructors reject numbers outside their range" {
  assert_eq(@core.Weekday::from_number_from_monday(0), None)
  assert_eq(@core.Weekday::from_number_from_monday(8), None)
  assert_eq(@core.Weekday::from_number_from_sunday(0), None)
  assert_eq(@core.Weekday::from_number_from_sunday(8), None)
  assert_eq(@core.Weekday::from_num_days_from_monday(-1), None)
  assert_eq(@core.Weekday::from_num_days_from_monday(7), None)
  assert_eq(@core.Weekday::from_num_days_from_sunday(-1), None)
  assert_eq(@core.Weekday::from_num_days_from_sunday(7), None)
}

///|
test "from_number_from_monday and from_number_from_sunday disagree on Sunday" {
  assert_eq(@core.Weekday::from_number_from_monday(7), Some(@core.Sun))
  assert_eq(@core.Weekday::from_number_from_sunday(1), Some(@core.Sun))
}

///|
test "weekdays hash equally when equal and work as map keys" {
  assert_eq(@core.Mon.hash(), @core.Sun.succ().hash())
  let seen : Map[@core.Weekday, Int] = Map([])
  seen[@core.Mon] = 1
  seen[@core.Sun.succ()] = seen.get(@core.Mon).unwrap() + 1
  seen[@core.Tue] = 5
  assert_eq(seen.length(), 2)
  assert_eq(seen.get(@core.Mon), Some(2))
}

///|
test "from_name accepts each full English weekday name" {
  for
    case in [
      ("Monday", @core.Mon),
      ("Tuesday", @core.Tue),
      ("Wednesday", @core.Wed),
      ("Thursday", @core.Thu),
      ("Friday", @core.Fri),
      ("Saturday", @core.Sat),
      ("Sunday", @core.Sun),
    ] {
    let (name, day) = case
    assert_eq(@core.Weekday::from_name(name), Some(day))
  }
}

///|
test "from_name accepts each three-letter abbreviation" {
  for
    case in [
      ("Mon", @core.Mon),
      ("Tue", @core.Tue),
      ("Wed", @core.Wed),
      ("Thu", @core.Thu),
      ("Fri", @core.Fri),
      ("Sat", @core.Sat),
      ("Sun", @core.Sun),
    ] {
    let (name, day) = case
    assert_eq(@core.Weekday::from_name(name), Some(day))
  }
}

///|
test "from_name ignores ASCII letter case" {
  assert_eq(@core.Weekday::from_name("MONDAY"), Some(@core.Mon))
  assert_eq(@core.Weekday::from_name("monday"), Some(@core.Mon))
  assert_eq(@core.Weekday::from_name("sUn"), Some(@core.Sun))
}

///|
test "from_name inverts name for every weekday" {
  for number in 1..<=7 {
    let day = @core.Weekday::from_number_from_monday(number).unwrap()
    assert_eq(@core.Weekday::from_name(day.name()), Some(day))
  }
}

///|
test "from_name rejects anything but an exact abbreviation or full name" {
  for
    bad in [
      "", "M", "Mo", "Mond", "Tues", "Thur", "Thurs", "Mon.", " Mon", "Mon ", "Lundi",
      "1", "\u{FF2D}\u{FF2F}\u{FF2E}", "Mon\u{E9}", "Sund",
    ] {
    assert_eq(@core.Weekday::from_name(bad), None)
  }
}
