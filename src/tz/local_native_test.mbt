///|
test "new() resolves the host's configured local time zone" {
  assert_true(@tz.Local::new() is Some(_))
}

///|
test "Local::now() is the current instant expressed in the host's local zone" {
  let before = @tz.Utc::now()
  let now = @tz.Local::now().unwrap()
  let after = @tz.Utc::now()
  assert_true(now.signed_duration_since(before).num_milliseconds() >= 0L)
  assert_true(after.signed_duration_since(now).num_milliseconds() >= 0L)
}

///|
test "Local::now() uses the same zone as Local::new()" {
  let now = @tz.Local::now().unwrap()
  let zone = @tz.Local::new().unwrap()
  assert_eq(now.offset(), zone.offset_from_utc(now.naive_utc()))
  assert_eq(now.zone_name(), zone.zone_name(now.naive_utc()))
}

///|
test "Location::load_system resolves a zone known to the embedded database" {
  let loc = @tz.Location::load_system("Asia/Tokyo").unwrap()
  assert_eq(loc.name(), Some("Asia/Tokyo"))
}

///|
test "Location::load_system is None for an unknown zone" {
  assert_true(@tz.Location::load_system("Not/A_Zone") is None)
}

///|
fn with_env(
  name : String,
  value : String,
  body : () -> Unit raise,
) -> Unit raise {
  let saved = @env.get_env_var(name)
  @env.set_env_var(name, value)
  defer (match saved {
    Some(v) => @env.set_env_var(name, v)
    None => @env.unset_env_var(name)
  })
  body()
}

///|
test "Location::load_system reads a zone from the ZONEINFO directory" {
  with_env("ZONEINFO", "src/tz/testdata/zoneinfo", () => {
    let loc = @tz.Location::load_system("Fixture/Zone").unwrap()
    assert_eq(loc.name(), Some("Fixture/Zone"))
  })
}

///|
test "Local::new resolves a TZ zone name from the ZONEINFO directory" {
  with_env("ZONEINFO", "src/tz/testdata/zoneinfo", () => {
    with_env("TZ", "Fixture/Zone", () => {
      let zone = @tz.Local::new().unwrap()
      let summer = @core.NaiveDateTime::from_timestamp(1_718_452_800L, 0).unwrap()
      assert_eq(zone.zone_name(summer), "BST")
    })
  })
}
