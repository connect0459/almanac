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
