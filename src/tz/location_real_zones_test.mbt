///|
fn utc_instant(timestamp : Int64) -> @core.NaiveDateTime {
  @core.NaiveDateTime::from_timestamp(timestamp, 0).unwrap()
}

///|
fn wall_clock_reading(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  minute : Int,
  second : Int,
) -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(year, month, day).unwrap(),
    @core.NaiveTime::from_hms(hour, minute, second).unwrap(),
  )
}

///|
let negative_dst_types : Array[(Int, Int, Int)] = [(3600, 0, 0), (0, 1, 4)]

///|
let negative_dst_chars : Array[Int] = [
  0x49, 0x53, 0x54, 0x00, 0x47, 0x4D, 0x54, 0x00,
]

///|
fn dublin_style_negative_dst() -> @tz.Location {
  @tz.Location::from_tzif_bytes(
    tzif_v2_build(
      [0L],
      [0],
      negative_dst_types,
      negative_dst_chars,
      "IST-1GMT0,M10.5.0,M3.5.0/1",
    ),
  ).unwrap()
}

///|
test "a negative-DST rule reports winter as daylight time with a smaller offset than summer (Dublin-style IST-1GMT0)" {
  let loc = dublin_style_negative_dst()
  let summer = loc.type_at(utc_instant(2_540_000_000L))
  assert_eq(summer.utc_offset(), 3600)
  assert_eq(summer.is_dst(), false)
  assert_eq(summer.abbreviation(), "IST")
  let winter = loc.type_at(utc_instant(2_555_000_000L))
  assert_eq(winter.utc_offset(), 0)
  assert_eq(winter.is_dst(), true)
  assert_eq(winter.abbreviation(), "GMT")
}

///|
test "a negative-DST rule switches at the exact instants of its POSIX rule (Dublin-style IST-1GMT0, 2050)" {
  let loc = dublin_style_negative_dst()
  let leaves_winter = 2_531_955_600L
  let enters_winter = 2_550_704_400L
  assert_eq(loc.type_at(utc_instant(leaves_winter - 1L)).abbreviation(), "GMT")
  assert_eq(loc.type_at(utc_instant(leaves_winter)).abbreviation(), "IST")
  assert_eq(loc.type_at(utc_instant(enters_winter - 1L)).abbreviation(), "IST")
  assert_eq(loc.type_at(utc_instant(enters_winter)).abbreviation(), "GMT")
}

///|
test "a negative-DST rule bounds the winter segment between its POSIX transitions (Dublin-style IST-1GMT0, 2050)" {
  let loc = dublin_style_negative_dst()
  let bounds = loc.transition_bounds(utc_instant(2_555_000_000L))
  assert_eq(bounds.start(), Some(utc_instant(2_550_704_400L)))
  assert_eq(bounds.end(), Some(utc_instant(2_563_405_200L)))
}

///|
test "a negative rule time (M3.5.0/-1) moves the spring transition to the previous evening in local time (America/Nuuk)" {
  let nuuk = @tz.Location::load("America/Nuuk").unwrap()
  let spring = 1_711_846_800L
  let before = nuuk.type_at(utc_instant(spring - 1L))
  assert_eq(before.utc_offset(), -7200)
  assert_eq(before.is_dst(), false)
  let after = nuuk.type_at(utc_instant(spring))
  assert_eq(after.utc_offset(), -3600)
  assert_eq(after.is_dst(), true)
  assert_eq(
    nuuk.offset_from_utc(utc_instant(spring)),
    @tz.FixedOffset::east(-3600).unwrap(),
  )
}

///|
test "a negative rule time reads local midnight of the transition day as already daylight time (America/Nuuk, 2024-03-31)" {
  let nuuk = @tz.Location::load("America/Nuuk").unwrap()
  assert_eq(
    nuuk.offset_from_local(wall_clock_reading(2024, 3, 30, 22, 59, 59)),
    @tz.Single(@tz.FixedOffset::east(-7200).unwrap()),
  )
  assert_eq(
    nuuk.offset_from_local(wall_clock_reading(2024, 3, 30, 23, 30, 0)),
    @tz.Absent,
  )
  assert_eq(
    nuuk.offset_from_local(wall_clock_reading(2024, 3, 31, 0, 0, 0)),
    @tz.Single(@tz.FixedOffset::east(-3600).unwrap()),
  )
}

///|
test "a negative rule time still drives transitions past the recorded table (America/Nuuk, 2050)" {
  let nuuk = @tz.Location::load("America/Nuuk").unwrap()
  let spring = 2_531_955_600L
  let autumn = 2_550_704_400L
  assert_eq(nuuk.type_at(utc_instant(spring - 1L)).utc_offset(), -7200)
  assert_eq(nuuk.type_at(utc_instant(spring)).utc_offset(), -3600)
  assert_eq(nuuk.type_at(utc_instant(autumn - 1L)).utc_offset(), -3600)
  assert_eq(nuuk.type_at(utc_instant(autumn)).utc_offset(), -7200)
}

///|
test "a southern zone that dropped DST stays on standard time all year after its last transition (America/Sao_Paulo)" {
  let sao_paulo = @tz.Location::load("America/Sao_Paulo").unwrap()
  for
    timestamp in [
      1_700_000_000L, 1_893_456_000L, 2_540_000_000L, 2_555_000_000L,
    ] {
    let kind = sao_paulo.type_at(utc_instant(timestamp))
    assert_eq(kind.utc_offset(), -10800)
    assert_eq(kind.is_dst(), false)
    assert_eq(kind.abbreviation(), "-03")
  }
}

///|
test "a southern zone that dropped DST still reports its earlier summer time (America/Sao_Paulo, 2018-11-04)" {
  let sao_paulo = @tz.Location::load("America/Sao_Paulo").unwrap()
  let start = 1_541_300_400L
  assert_eq(sao_paulo.type_at(utc_instant(start - 1L)).is_dst(), false)
  let summer = sao_paulo.type_at(utc_instant(start))
  assert_eq(summer.utc_offset(), -7200)
  assert_eq(summer.is_dst(), true)
}

///|
test "a date-line skip leaves no local reading for the skipped day (Pacific/Apia, 2011-12-30)" {
  let apia = @tz.Location::load("Pacific/Apia").unwrap()
  assert_eq(
    apia.offset_from_local(wall_clock_reading(2011, 12, 29, 23, 59, 59)),
    @tz.Single(@tz.FixedOffset::east(-36000).unwrap()),
  )
  assert_eq(
    apia.offset_from_local(wall_clock_reading(2011, 12, 30, 0, 0, 0)),
    @tz.Absent,
  )
  assert_eq(
    apia.offset_from_local(wall_clock_reading(2011, 12, 30, 23, 59, 59)),
    @tz.Absent,
  )
  assert_eq(
    apia.offset_from_local(wall_clock_reading(2011, 12, 31, 0, 0, 0)),
    @tz.Single(@tz.FixedOffset::east(50400).unwrap()),
  )
}

///|
test "a date-line skip advances the offset by a whole day across one second of UTC (Pacific/Apia)" {
  let apia = @tz.Location::load("Pacific/Apia").unwrap()
  let skip = 1_325_239_200L
  assert_eq(
    apia.offset_from_utc(utc_instant(skip - 1L)),
    @tz.FixedOffset::east(-36000).unwrap(),
  )
  assert_eq(
    apia.offset_from_utc(utc_instant(skip)),
    @tz.FixedOffset::east(50400).unwrap(),
  )
}

///|
fn slim_new_york() -> @tz.Location {
  @tz.Location::from_tzif_bytes(
    tzif_v2_build(
      [1_167_609_600L],
      [0],
      [(-18000, 0, 0), (-14400, 1, 4)],
      [0x45, 0x53, 0x54, 0x00, 0x45, 0x44, 0x54, 0x00],
      "EST5EDT,M3.2.0,M11.1.0",
    ),
  ).unwrap()
}

///|
test "a slim TZif resolves every later year from its footer (EST5EDT after a single recorded transition)" {
  let loc = slim_new_york()
  let winter = loc.type_at(utc_instant(1_704_067_200L))
  assert_eq(winter.utc_offset(), -18000)
  assert_eq(winter.abbreviation(), "EST")
  let summer = loc.type_at(utc_instant(1_720_000_000L))
  assert_eq(summer.utc_offset(), -14400)
  assert_eq(summer.abbreviation(), "EDT")
  assert_eq(summer.is_dst(), true)
}

///|
test "a slim TZif reports the footer's exact transition window (EST5EDT, 2024)" {
  let loc = slim_new_york()
  let bounds = loc.transition_bounds(utc_instant(1_720_000_000L))
  assert_eq(bounds.start(), Some(utc_instant(1_710_054_000L)))
  assert_eq(bounds.end(), Some(utc_instant(1_730_613_600L)))
}

///|
test "a slim TZif resolves an ambiguous and an absent local reading from its footer (EST5EDT, 2024)" {
  let loc = slim_new_york()
  assert_eq(
    loc.offset_from_local(wall_clock_reading(2024, 3, 10, 2, 30, 0)),
    @tz.Absent,
  )
  assert_eq(
    loc.offset_from_local(wall_clock_reading(2024, 11, 3, 1, 30, 0)),
    @tz.Ambiguous(
      @tz.FixedOffset::east(-14400).unwrap(),
      @tz.FixedOffset::east(-18000).unwrap(),
    ),
  )
}

///|
test "a zone observes daylight time in the 1918 summer and returns to standard time that autumn (PST8PDT)" {
  let loc = @tz.Location::load("PST8PDT").unwrap()
  let summer = loc.type_at(utc_instant(-1_600_000_000L))
  assert_eq(summer.utc_offset(), -25200)
  assert_eq(summer.is_dst(), true)
  assert_eq(summer.abbreviation(), "PDT")
  let winter = loc.type_at(utc_instant(-1_580_000_000L))
  assert_eq(winter.utc_offset(), -28800)
  assert_eq(winter.is_dst(), false)
  assert_eq(winter.abbreviation(), "PST")
}

///|
test "a 1900 instant is on standard time at -05:00, not local mean time (America/New_York)" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  let kind = ny.type_at(utc_instant(-2_208_988_800L))
  assert_eq(kind.utc_offset(), -18000)
  assert_eq(kind.is_dst(), false)
  assert_eq(kind.abbreviation(), "EST")
}

///|
test "an instant before 1883 standardisation uses local mean time -04:56:02 (America/New_York)" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  let kind = ny.type_at(utc_instant(-2_717_650_801L))
  assert_eq(kind.utc_offset(), -17762)
  assert_eq(kind.abbreviation(), "LMT")
}
