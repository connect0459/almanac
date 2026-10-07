///|
fn restore_tz_env(saved : String?) -> Unit {
  match saved {
    Some(v) => @env.set_env_var("TZ", v)
    None => @env.unset_env_var("TZ")
  }
}

///|
fn with_tz_env(value : String?, body : () -> Unit raise) -> Unit raise {
  let saved = @env.get_env_var("TZ")
  match value {
    Some(v) => @env.set_env_var("TZ", v)
    None => @env.unset_env_var("TZ")
  }
  defer restore_tz_env(saved)
  body()
}

///|
test "new() resolves an IANA zone name from TZ" {
  with_tz_env(Some("Asia/Tokyo"), () => {
    let zone = @tz.Local::new().unwrap()
    let utc = @core.NaiveDateTime::from_timestamp(1_718_452_800L, 0).unwrap()
    assert_eq(
      zone.offset_from_utc(utc),
      @tz.FixedOffset::east(9 * 3600).unwrap(),
    )
  })
}

///|
test "new() resolves a bare POSIX rule from TZ" {
  with_tz_env(Some("JST-9"), () => {
    let zone = @tz.Local::new().unwrap()
    let utc = @core.NaiveDateTime::from_timestamp(1_718_452_800L, 0).unwrap()
    assert_eq(
      zone.offset_from_utc(utc),
      @tz.FixedOffset::east(9 * 3600).unwrap(),
    )
  })
}

///|
test "new() treats an empty TZ as UTC" {
  with_tz_env(Some(""), () => {
    let zone = @tz.Local::new().unwrap()
    let utc = @core.NaiveDateTime::from_timestamp(1_718_452_800L, 0).unwrap()
    assert_eq(zone.offset_from_utc(utc), @tz.FixedOffset::east(0).unwrap())
  })
}

///|
test "new() is None when TZ is unset because there is no host zone file to fall back on" {
  with_tz_env(None, () => assert_true(@tz.Local::new() is None))
}

///|
test "new() is None when TZ names an unrecognized zone" {
  with_tz_env(Some("Not/AZone"), () => assert_true(@tz.Local::new() is None))
}

///|
test "Local::now() is the current instant expressed in the TZ zone" {
  with_tz_env(Some("Asia/Tokyo"), () => {
    let before = @tz.Utc::now()
    let now = @tz.Local::now().unwrap()
    let after = @tz.Utc::now()
    assert_true(now.signed_duration_since(before).num_milliseconds() >= 0L)
    assert_true(after.signed_duration_since(now).num_milliseconds() >= 0L)
    assert_eq(now.offset(), @tz.FixedOffset::east(9 * 3600).unwrap())
  })
}

///|
test "Location::load_system resolves like Location::load" {
  let loc = @tz.Location::load_system("Asia/Tokyo").unwrap()
  assert_eq(loc.name(), Some("Asia/Tokyo"))
  assert_true(@tz.Location::load_system("Not/A_Zone") is None)
}
