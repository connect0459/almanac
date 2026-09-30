///|
test "every embedded zone loads as a Location" {
  for name, _ in tzdata_zones {
    assert_true(Location::load(name) is Some(_))
  }
}
