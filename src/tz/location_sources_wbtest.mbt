///|
fn summer_instant() -> @core.NaiveDateTime {
  @core.NaiveDateTime::from_timestamp(1_718_452_800L, 0).unwrap()
}

///|
test "load_from_dirs prefers a zoneinfo file over the embedded zone and keeps the requested name" {
  let loc = Location::load_from_dirs(
    "Asia/Tokyo",
    ["/zi"],
    files_reader({ "/zi/Asia/Tokyo": embedded_tzif("America/New_York") }),
  ).unwrap()
  assert_eq(loc.zone_name(summer_instant()), "EDT")
  assert_eq(loc.name(), Some("Asia/Tokyo"))
}

///|
test "load_from_dirs searches directories in the given order" {
  let loc = Location::load_from_dirs(
    "Asia/Tokyo",
    ["/first", "/second"],
    files_reader({
      "/first/Asia/Tokyo": embedded_tzif("America/New_York"),
      "/second/Asia/Tokyo": embedded_tzif("Europe/London"),
    }),
  ).unwrap()
  assert_eq(loc.zone_name(summer_instant()), "EDT")
}

///|
test "load_from_dirs moves on to a later directory when an earlier one lacks the zone" {
  let loc = Location::load_from_dirs(
    "Asia/Tokyo",
    ["/first", "/second"],
    files_reader({ "/second/Asia/Tokyo": embedded_tzif("Europe/London") }),
  ).unwrap()
  assert_eq(loc.zone_name(summer_instant()), "BST")
}

///|
test "load_from_dirs joins a directory that ends with a slash without doubling it" {
  let loc = Location::load_from_dirs(
    "Asia/Tokyo",
    ["/zi/"],
    files_reader({ "/zi/Asia/Tokyo": embedded_tzif("America/New_York") }),
  ).unwrap()
  assert_eq(loc.zone_name(summer_instant()), "EDT")
}

///|
test "load_from_dirs falls back to the embedded zone when no directory has it" {
  let loc = Location::load_from_dirs("Asia/Tokyo", ["/zi"], no_files).unwrap()
  assert_eq(loc.zone_name(summer_instant()), "JST")
  assert_eq(loc.name(), Some("Asia/Tokyo"))
}

///|
test "load_from_dirs skips a zoneinfo file that is not TZif and uses the next source" {
  let loc = Location::load_from_dirs(
    "Asia/Tokyo",
    ["/zi"],
    files_reader({ "/zi/Asia/Tokyo": b"not tzif" }),
  ).unwrap()
  assert_eq(loc.zone_name(summer_instant()), "JST")
}

///|
test "load_from_dirs is None for a zone that no source knows" {
  assert_true(Location::load_from_dirs("Not/A_Zone", ["/zi"], no_files) is None)
}

///|
test "load_from_dirs rejects names that could escape the zoneinfo directory" {
  let tokyo = embedded_tzif("Asia/Tokyo")
  let files = files_reader({
    "/zi/Asia/../Asia/Tokyo": tokyo,
    "/zi//abs/Tokyo": tokyo,
    "/zi/\\win": tokyo,
    "/zi/": tokyo,
    "/zi/Asia\u0000Tokyo": tokyo,
  })
  for
    name in ["Asia/../Asia/Tokyo", "/abs/Tokyo", "\\win", "", "Asia\u0000Tokyo"] {
    assert_true(Location::load_from_dirs(name, ["/zi"], files) is None)
  }
}

///|
test "resolve looks up a TZ zone name in the zoneinfo directories before the embedded zones" {
  let resolved = Local::resolve(
    Some("Asia/Tokyo"),
    files_reader({ "/zi/Asia/Tokyo": embedded_tzif("America/New_York") }),
    zoneinfo_dirs=["/zi"],
  ).unwrap()
  assert_eq(resolved.zone_name(summer_instant()), "EDT")
}

///|
test "resolve does not read zoneinfo directories unless given any" {
  let resolved = Local::resolve(
    Some("Asia/Tokyo"),
    files_reader({
      "/usr/share/zoneinfo/Asia/Tokyo": embedded_tzif("America/New_York"),
    }),
  ).unwrap()
  assert_eq(resolved.zone_name(summer_instant()), "JST")
}
