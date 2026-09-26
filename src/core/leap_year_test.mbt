///|
test "is_leap_year holds for years divisible by 4 but not by 100" {
  for year in [4, 1996, 2024, 2004] {
    assert_true(@core.is_leap_year(year))
  }
}

///|
test "is_leap_year fails for years not divisible by 4" {
  for year in [1, 2023, 2025, 1999] {
    assert_false(@core.is_leap_year(year))
  }
}

///|
test "is_leap_year fails for century years not divisible by 400" {
  for year in [1900, 2100, 1800, 2200] {
    assert_false(@core.is_leap_year(year))
  }
}

///|
test "is_leap_year holds for century years divisible by 400" {
  for year in [2000, 1600, 2400] {
    assert_true(@core.is_leap_year(year))
  }
}

///|
test "is_leap_year holds proleptically for year 0 and negative multiples of 400" {
  for year in [0, -400, -800] {
    assert_true(@core.is_leap_year(year))
  }
}
