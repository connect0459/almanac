///|
test "a period reports the years, months and days it was built with" {
  let period = @core.Period::new(years=1, months=2, days=3)
  assert_eq(period.years(), 1)
  assert_eq(period.months(), 2)
  assert_eq(period.days(), 3)
}

///|
test "omitted components of a period default to zero" {
  let period = @core.Period::new(months=5)
  assert_eq(period.years(), 0)
  assert_eq(period.months(), 5)
  assert_eq(period.days(), 0)
}

///|
test "a period keeps its components unnormalized" {
  assert_true(
    @core.Period::new(months=14) != @core.Period::new(years=1, months=2),
  )
  assert_eq(@core.Period::new(months=14).months(), 14)
  assert_eq(@core.Period::new(days=45).days(), 45)
}

///|
test "components of a period may carry independent signs" {
  let period = @core.Period::new(years=1, months=-2, days=3)
  assert_eq(period.years(), 1)
  assert_eq(period.months(), -2)
  assert_eq(period.days(), 3)
}

///|
test "the zero period and the default period are the same and report is_zero" {
  assert_eq(@core.Period::zero(), @core.Period::new())
  assert_eq(@core.Period::default(), @core.Period::zero())
  assert_true(@core.Period::zero().is_zero())
}

///|
test "a period with any non-zero component is not zero" {
  assert_false(@core.Period::new(years=1).is_zero())
  assert_false(@core.Period::new(months=-1).is_zero())
  assert_false(@core.Period::new(days=1).is_zero())
}

///|
test "periods with the same components are equal and hash equally" {
  let a = @core.Period::new(years=1, months=2, days=3)
  let b = @core.Period::new(years=1, months=2, days=3)
  assert_eq(a, b)
  assert_eq(a.hash(), b.hash())
  assert_true(a != @core.Period::new(years=1, months=2, days=4))
}

///|
test "periods can be used as map keys" {
  let map : Map[@core.Period, String] = Map([])
  map[@core.Period::new(months=1)] = "one month"
  assert_eq(map.get(@core.Period::new(months=1)), Some("one month"))
  assert_eq(map.get(@core.Period::new(days=30)), None)
}

///|
test "a period renders in the ISO 8601 date-based duration style" {
  assert_eq(@core.Period::new(years=1, months=2, days=3).to_string(), "P1Y2M3D")
  assert_eq(@core.Period::new(months=2).to_string(), "P2M")
  assert_eq(@core.Period::new(years=1, days=3).to_string(), "P1Y3D")
}

///|
test "the zero period renders as P0D" {
  assert_eq(@core.Period::zero().to_string(), "P0D")
}

///|
test "negative components of a period render with a leading minus" {
  assert_eq(@core.Period::new(years=-1, days=3).to_string(), "P-1Y3D")
}

///|
test "negating a period negates every component" {
  let negated = @core.Period::new(years=1, months=-2, days=3).checked_neg()
  assert_eq(negated, Some(@core.Period::new(years=-1, months=2, days=-3)))
}

///|
test "negating a period whose component is the minimum value is out of range" {
  assert_eq(@core.Period::new(years=-2147483648).checked_neg(), None)
  assert_eq(@core.Period::new(months=-2147483648).checked_neg(), None)
  assert_eq(@core.Period::new(days=-2147483648).checked_neg(), None)
}

///|
test "adding periods sums each component independently" {
  let sum = @core.Period::new(years=1, months=2, days=3).checked_add(
    @core.Period::new(years=0, months=11, days=-5),
  )
  assert_eq(sum, Some(@core.Period::new(years=1, months=13, days=-2)))
}

///|
test "adding periods that overflow a component is out of range" {
  let max = 2147483647
  assert_eq(
    @core.Period::new(years=max).checked_add(@core.Period::new(years=1)),
    None,
  )
  assert_eq(
    @core.Period::new(months=max).checked_add(@core.Period::new(months=1)),
    None,
  )
  assert_eq(
    @core.Period::new(days=max).checked_add(@core.Period::new(days=1)),
    None,
  )
  assert_eq(
    @core.Period::new(days=-max).checked_add(@core.Period::new(days=-max)),
    None,
  )
}

///|
test "subtracting a period from itself yields the zero period" {
  let period = @core.Period::new(years=1, months=2, days=3)
  assert_eq(period.checked_sub(period), Some(@core.Period::zero()))
}

///|
test "subtracting periods differences each component independently" {
  let diff = @core.Period::new(years=3, months=1, days=0).checked_sub(
    @core.Period::new(years=1, months=2, days=3),
  )
  assert_eq(diff, Some(@core.Period::new(years=2, months=-1, days=-3)))
}

///|
test "subtracting periods that overflow a component is out of range" {
  assert_eq(
    @core.Period::new(years=-2147483648).checked_sub(@core.Period::new(years=1)),
    None,
  )
  assert_eq(
    @core.Period::new(months=0).checked_sub(
      @core.Period::new(months=-2147483648),
    ),
    None,
  )
  assert_eq(
    @core.Period::new(days=2147483647).checked_sub(@core.Period::new(days=-1)),
    None,
  )
}

///|
test "multiplying a period scales each component" {
  let scaled = @core.Period::new(years=1, months=2, days=-3).checked_mul(3)
  assert_eq(scaled, Some(@core.Period::new(years=3, months=6, days=-9)))
}

///|
test "multiplying a period by zero yields the zero period" {
  assert_eq(
    @core.Period::new(years=1, months=2, days=3).checked_mul(0),
    Some(@core.Period::zero()),
  )
}

///|
test "multiplying a period by a negative scalar flips every component" {
  assert_eq(
    @core.Period::new(years=1, months=-2, days=3).checked_mul(-1),
    Some(@core.Period::new(years=-1, months=2, days=-3)),
  )
}

///|
test "multiplying a period that overflows a component is out of range" {
  assert_eq(@core.Period::new(years=1_073_741_824).checked_mul(2), None)
  assert_eq(@core.Period::new(months=1_073_741_824).checked_mul(2), None)
  assert_eq(@core.Period::new(days=1_073_741_824).checked_mul(2), None)
}

///|
test "multiplying the minimum component by negative one is out of range" {
  assert_eq(@core.Period::new(years=-2147483648).checked_mul(-1), None)
  assert_eq(@core.Period::new(months=-2147483648).checked_mul(-1), None)
  assert_eq(@core.Period::new(days=-2147483648).checked_mul(-1), None)
}

///|
test "multiplying components at the extreme values stays within range" {
  let max = 2147483647
  assert_eq(
    @core.Period::new(years=max, months=-max, days=max).checked_mul(1),
    Some(@core.Period::new(years=max, months=-max, days=max)),
  )
  assert_eq(
    @core.Period::new(years=max, months=-max, days=max).checked_mul(-1),
    Some(@core.Period::new(years=-max, months=max, days=-max)),
  )
  assert_eq(@core.Period::new(years=max).checked_mul(2), None)
}
