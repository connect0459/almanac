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
