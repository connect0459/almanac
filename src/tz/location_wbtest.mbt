///|
test "resolve_tzdata_bytes finds an exact zone name, follows an alias, and rejects an unknown name" {
  let zones : Map[String, Bytes] = Map::from_array([("Zone/Canonical", b"data")])
  let aliases : Map[String, String] = Map::from_array([
    ("Zone/Alias", "Zone/Canonical"),
  ])
  assert_eq(
    resolve_tzdata_bytes(zones, aliases, "Zone/Canonical"),
    Some(b"data"),
  )
  assert_eq(resolve_tzdata_bytes(zones, aliases, "Zone/Alias"), Some(b"data"))
  assert_true(resolve_tzdata_bytes(zones, aliases, "Not/A/Zone") is None)
}

///|
test "Location::load returns the same parsed zone for repeated loads of a name" {
  let first = Location::load("Asia/Tokyo").unwrap()
  let second = Location::load("Asia/Tokyo").unwrap()
  assert_true(physical_equal(first, second))
}

///|
test "Location::load keeps the requested name for an alias of an already loaded zone" {
  let canonical = Location::load("Asia/Tokyo").unwrap()
  let via_alias = Location::load("Japan").unwrap()
  assert_eq(canonical.name(), Some("Asia/Tokyo"))
  assert_eq(via_alias.name(), Some("Japan"))
}

///|
test "Location::load does not cache an unknown zone name" {
  let before = loaded_zones.length()
  assert_true(Location::load("Not/A/Zone") is None)
  assert_eq(loaded_zones.length(), before)
}
