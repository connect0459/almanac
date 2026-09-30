///|
test "from_tzif_bytes rejects malformed TZif data" {
  assert_true(@tz.Location::from_tzif_bytes(Bytes::make(44, b'\x00')) is None)
}

///|
test "name reports the identifier a Location was loaded with" {
  let tokyo = @tz.Location::load("Asia/Tokyo").unwrap()
  assert_eq(tokyo.name(), Some("Asia/Tokyo"))
}

///|
test "name is None for a Location built directly from raw TZif bytes" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  assert_eq(ny.name(), None)
}

///|
test "transition_bounds reports the exact recorded transition window within the table (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_start_2024 = 1_710_054_000L
  let dst_end_2024 = 1_730_613_600L
  let bounds = ny.transition_bounds(
    @core.NaiveDateTime::from_timestamp(dst_start_2024, 0).unwrap(),
  )
  assert_eq(
    bounds.start(),
    Some(@core.NaiveDateTime::from_timestamp(dst_start_2024, 0).unwrap()),
  )
  assert_eq(
    bounds.end(),
    Some(@core.NaiveDateTime::from_timestamp(dst_end_2024, 0).unwrap()),
  )
}

///|
test "transition_bounds reports an unbounded start before the zone's first recorded transition (America/New_York)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let just_before = @core.NaiveDateTime::from_timestamp(-2_717_650_801L, 0).unwrap()
  let bounds = ny.transition_bounds(just_before)
  assert_eq(bounds.start(), None)
  assert_eq(
    bounds.end(),
    Some(@core.NaiveDateTime::from_timestamp(-2_717_650_800L, 0).unwrap()),
  )
}

///|
test "transition_bounds computes the exact (not approximated) POSIX-extrapolated window past the last recorded transition (America/New_York, 2040)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let summer_2040 = @core.NaiveDateTime::from_timestamp(2_224_713_600L, 0).unwrap()
  let bounds = ny.transition_bounds(summer_2040)
  assert_eq(
    bounds.start(),
    Some(@core.NaiveDateTime::from_timestamp(2_215_062_000L, 0).unwrap()),
  )
  assert_eq(
    bounds.end(),
    Some(@core.NaiveDateTime::from_timestamp(2_235_621_600L, 0).unwrap()),
  )
}

///|
test "transition_bounds reports an unbounded end past the last recorded transition when the POSIX footer has no DST rule (Asia/Tokyo)" {
  let tokyo = @tz.Location::load("Asia/Tokyo").unwrap()
  let far_future = @core.NaiveDateTime::from_timestamp(2_000_000_000L, 0).unwrap()
  let bounds = tokyo.transition_bounds(far_future)
  assert_eq(
    bounds.start(),
    Some(@core.NaiveDateTime::from_timestamp(-577_962_000L, 0).unwrap()),
  )
  assert_eq(bounds.end(), None)
}

///|
test "transition_bounds reports an unbounded end at the last recorded transition itself, within the table" {
  let loc = @tz.Location::from_tzif_bytes(tzif_v1_only_with_transitions).unwrap()
  let at_last_transition = @core.NaiveDateTime::from_timestamp(
    1_000_000_000L, 0,
  ).unwrap()
  let bounds = loc.transition_bounds(at_last_transition)
  assert_eq(bounds.start(), Some(at_last_transition))
  assert_eq(bounds.end(), None)
}

///|
test "transition_bounds reports both sides unbounded for a zone with no transitions (UTC)" {
  let utc = @tz.Location::from_tzif_bytes(tzif_utc).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(1_700_000_000L, 0).unwrap()
  let bounds = utc.transition_bounds(dt)
  assert_eq(bounds.start(), None)
  assert_eq(bounds.end(), None)
}

///|
test "transition_bounds reports an unbounded end past the last recorded transition when there is no POSIX footer" {
  let loc = @tz.Location::from_tzif_bytes(tzif_v1_only_with_transitions).unwrap()
  let far_future = @core.NaiveDateTime::from_timestamp(2_000_000_000L, 0).unwrap()
  let bounds = loc.transition_bounds(far_future)
  assert_eq(
    bounds.start(),
    Some(@core.NaiveDateTime::from_timestamp(1_000_000_000L, 0).unwrap()),
  )
  assert_eq(bounds.end(), None)
}

///|
test "type_at reports the abbreviation and DST flag from the table, and from the POSIX rule past the last transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_start_2024 = @core.NaiveDateTime::from_timestamp(1_710_054_000L, 0).unwrap()
  let via_table = ny.type_at(dst_start_2024)
  assert_eq(via_table.abbreviation(), "EDT")
  assert_eq(via_table.is_dst(), true)
  let summer_2040 = @core.NaiveDateTime::from_timestamp(2_224_713_600L, 0).unwrap()
  let via_posix = ny.type_at(summer_2040)
  assert_eq(via_posix.abbreviation(), "EDT")
  assert_eq(via_posix.is_dst(), true)
  assert_eq(via_posix.utc_offset(), -14400)
}

///|
test "zone_name reports the abbreviation in effect at the given instant, matching type_at" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_start_2024 = @core.NaiveDateTime::from_timestamp(1_710_054_000L, 0).unwrap()
  assert_eq(ny.zone_name(dst_start_2024), "EDT")
  let summer_2040 = @core.NaiveDateTime::from_timestamp(2_224_713_600L, 0).unwrap()
  assert_eq(ny.zone_name(summer_2040), "EDT")
}

///|
test "offset_from_utc uses the first non-DST local time type before the first recorded transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let just_before = @core.NaiveDateTime::from_timestamp(-2_717_650_801L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(just_before),
    @tz.FixedOffset::east(-17762).unwrap(),
  )
}

///|
test "offset_from_utc uses the table for an instant at and after the first recorded transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let at_first = @core.NaiveDateTime::from_timestamp(-2_717_650_800L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(at_first),
    @tz.FixedOffset::east(-18000).unwrap(),
  )
}

///|
test "offset_from_utc resolves a known recent DST transition from the table (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_start = 1_710_054_000L
  let dst_end = 1_730_613_600L
  assert_eq(
    ny.offset_from_utc(
      @core.NaiveDateTime::from_timestamp(dst_start - 1L, 0).unwrap(),
    ),
    @tz.FixedOffset::east(-18000).unwrap(),
  )
  assert_eq(
    ny.offset_from_utc(
      @core.NaiveDateTime::from_timestamp(dst_start, 0).unwrap(),
    ),
    @tz.FixedOffset::east(-14400).unwrap(),
  )
  assert_eq(
    ny.offset_from_utc(
      @core.NaiveDateTime::from_timestamp(dst_end - 1L, 0).unwrap(),
    ),
    @tz.FixedOffset::east(-14400).unwrap(),
  )
  assert_eq(
    ny.offset_from_utc(@core.NaiveDateTime::from_timestamp(dst_end, 0).unwrap()),
    @tz.FixedOffset::east(-18000).unwrap(),
  )
}

///|
test "offset_from_utc uses the table at and before the last recorded transition, and the POSIX rule strictly after it" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let last = @core.NaiveDateTime::from_timestamp(2_140_668_000L, 0).unwrap()
  assert_eq(ny.offset_from_utc(last), @tz.FixedOffset::east(-18000).unwrap())
  let summer_2040 = @core.NaiveDateTime::from_timestamp(2_224_713_600L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(summer_2040),
    @tz.FixedOffset::east(-14400).unwrap(),
  )
  let winter_2040 = @core.NaiveDateTime::from_timestamp(2_208_988_800L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(winter_2040),
    @tz.FixedOffset::east(-18000).unwrap(),
  )
}

///|
test "offset_from_utc is constant for a zone with no transitions (UTC)" {
  let utc = @tz.Location::from_tzif_bytes(tzif_utc).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(1_700_000_000L, 0).unwrap()
  assert_eq(utc.offset_from_utc(dt), @tz.FixedOffset::east(0).unwrap())
}

///|
test "offset_from_local reports Absent within a real spring-forward gap and Single either side of it (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_start = 1_710_054_000L
  let before_gap = @core.NaiveDateTime::from_timestamp(
    dst_start - 18000L - 1L,
    0,
  ).unwrap()
  let in_gap = @core.NaiveDateTime::from_timestamp(dst_start - 18000L, 0).unwrap()
  let after_gap = @core.NaiveDateTime::from_timestamp(dst_start - 14400L, 0).unwrap()
  assert_eq(
    ny.offset_from_local(before_gap),
    @tz.Single(@tz.FixedOffset::east(-18000).unwrap()),
  )
  assert_true(ny.offset_from_local(in_gap) is @tz.Absent)
  assert_eq(
    ny.offset_from_local(after_gap),
    @tz.Single(@tz.FixedOffset::east(-14400).unwrap()),
  )
}

///|
test "offset_from_local reports Ambiguous within a real fall-back fold (America/New_York, 2024)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let dst_end = 1_730_613_600L
  let in_fold = @core.NaiveDateTime::from_timestamp(dst_end - 16000L, 0).unwrap()
  assert_eq(
    ny.offset_from_local(in_fold),
    @tz.Ambiguous(
      @tz.FixedOffset::east(-14400).unwrap(),
      @tz.FixedOffset::east(-18000).unwrap(),
    ),
  )
}

///|
test "offset_from_local delegates to the POSIX rule strictly past the last recorded transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let summer_2040 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2040, 7, 1).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    ny.offset_from_local(summer_2040),
    @tz.Single(@tz.FixedOffset::east(-14400).unwrap()),
  )
}

///|
test "offset_from_local is a single unambiguous resolution before the first recorded transition" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let colonial_era = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(1800, 1, 1).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    ny.offset_from_local(colonial_era),
    @tz.Single(@tz.FixedOffset::east(-17762).unwrap()),
  )
}

///|
test "from_tzif_bytes rejects a well-formed TZif file whose POSIX footer is malformed" {
  assert_true(@tz.Location::from_tzif_bytes(tzif_bad_posix_footer) is None)
}

///|
test "initial_type falls back to the first local time type when every type observes DST" {
  let loc = @tz.Location::from_tzif_bytes(tzif_all_dst_types).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(1_700_000_000L, 0).unwrap()
  assert_eq(loc.offset_from_utc(dt), @tz.FixedOffset::east(3600).unwrap())
}

///|
test "offset_from_local resolves a local reading in the very first recorded segment" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let year1900 = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(1900, 6, 1).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    ny.offset_from_local(year1900),
    @tz.Single(@tz.FixedOffset::east(-18000).unwrap()),
  )
}

///|
test "offset_from_local reports Ambiguous within a real fall-back fold in a positive-offset zone (Australia/Sydney)" {
  let sydney = @tz.Location::from_tzif_bytes(tzif_sydney).unwrap()
  let fold_end = 1_712_419_200L
  let in_fold = @core.NaiveDateTime::from_timestamp(fold_end + 37000L, 0).unwrap()
  assert_eq(
    sydney.offset_from_local(in_fold),
    @tz.Ambiguous(
      @tz.FixedOffset::east(39600).unwrap(),
      @tz.FixedOffset::east(36000).unwrap(),
    ),
  )
}

///|
test "offset_from_local reports Absent (not Ambiguous) when a local reading matches two non-adjacent segments but not the segment between them" {
  let loc = @tz.Location::from_tzif_bytes(tzif_pathological_close_transitions).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(25L, 0).unwrap()
  assert_true(loc.offset_from_local(dt) is @tz.Absent)
}

///|
test "offset_from_local resolves via the previous segment alone when the naive lookup's own segment and its next neighbor both fail to apply" {
  let loc = @tz.Location::from_tzif_bytes(tzif_prev_only_candidate).unwrap()
  let dt = @core.NaiveDateTime::from_timestamp(10L, 0).unwrap()
  assert_eq(
    loc.offset_from_local(dt),
    @tz.Single(@tz.FixedOffset::east(10).unwrap()),
  )
}

///|
test "a zone with no POSIX footer clamps to its last recorded transition's type past it" {
  let loc = @tz.Location::from_tzif_bytes(tzif_v1_only_with_transitions).unwrap()
  let far_future = @core.NaiveDateTime::from_timestamp(2_000_000_000L, 0).unwrap()
  assert_eq(
    loc.offset_from_utc(far_future),
    @tz.FixedOffset::east(3600).unwrap(),
  )
  assert_eq(
    loc.offset_from_local(far_future),
    @tz.Single(@tz.FixedOffset::east(3600).unwrap()),
  )
}

///|
test "Location::load loads a real embedded zone by name and rejects an unknown name" {
  let ny = @tz.Location::load("America/New_York").unwrap()
  let dst_start_2024 = @core.NaiveDateTime::from_timestamp(1_710_054_000L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(dst_start_2024),
    @tz.FixedOffset::east(-14400).unwrap(),
  )
  assert_true(@tz.Location::load("Not/A/Real/Zone") is None)
}

///|
test "Location compares equal to another Location built from the same TZif bytes" {
  let a = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let b = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  assert_true(a == b)
  assert_true(a != @tz.Location::from_tzif_bytes(tzif_tokyo).unwrap())
}

///|
test "Location compares unequal when only the POSIX footer presence differs" {
  let with_footer = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let without_footer = @tz.Location::from_tzif_bytes(tzif_v1_only).unwrap()
  assert_true(with_footer != without_footer)
}

///|
test "Location compares equal for the same loaded zone and unequal for an alias of it" {
  let tokyo = @tz.Location::load("Asia/Tokyo").unwrap()
  assert_true(tokyo == @tz.Location::load("Asia/Tokyo").unwrap())
  let japan = @tz.Location::load("Japan").unwrap()
  assert_true(tokyo != japan)
}

///|
test "DateTime in a Location supports equality and instant ordering" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let earlier = @tz.DateTime::from_timestamp(1_000L, 0, ny).unwrap()
  let later = @tz.DateTime::from_timestamp(2_000L, 0, ny).unwrap()
  assert_true(earlier == earlier)
  assert_true(earlier != later)
  assert_true(earlier < later)
}

///|
test "from_tzif_bytes_named reports the given name and resolves like from_tzif_bytes" {
  let named = @tz.Location::from_tzif_bytes_named("Test/NewYork", tzif_new_york).unwrap()
  let unnamed = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  assert_eq(named.name(), Some("Test/NewYork"))
  let instant = @core.NaiveDateTime::from_timestamp(1_710_054_000L, 0).unwrap()
  assert_eq(named.type_at(instant), unnamed.type_at(instant))
  assert_true(named != unnamed)
}

///|
test "from_tzif_bytes_named accepts any name text, including an empty one" {
  let empty = @tz.Location::from_tzif_bytes_named("", tzif_tokyo).unwrap()
  assert_eq(empty.name(), Some(""))
}

///|
test "from_tzif_bytes_named rejects malformed bytes" {
  assert_true(@tz.Location::from_tzif_bytes_named("Bad", b"nope") is None)
  assert_true(
    @tz.Location::from_tzif_bytes_named("Bad", tzif_bad_posix_footer) is None,
  )
}

///|
test "from_tzif_bytes_named equals a loaded zone built from identical bytes and name" {
  let a = @tz.Location::from_tzif_bytes_named("X", tzif_tokyo).unwrap()
  let b = @tz.Location::from_tzif_bytes_named("X", tzif_tokyo).unwrap()
  assert_true(a == b)
  assert_true(
    a != @tz.Location::from_tzif_bytes_named("Y", tzif_tokyo).unwrap(),
  )
}

///|
fn utc_at(secs : Int64) -> @core.NaiveDateTime {
  @core.NaiveDateTime::from_timestamp(secs, 0).unwrap()
}

///|
test "offset_from_abbreviation prefers the abbreviation in effect at the given instant (Europe/Moscow MSK)" {
  let moscow = @tz.Location::load("Europe/Moscow").unwrap()
  let in_2012 = utc_at(1_338_508_800L)
  let in_2020 = utc_at(1_590_969_600L)
  assert_eq(
    moscow.offset_from_abbreviation("MSK", in_2012),
    @tz.FixedOffset::east(4 * 3600),
  )
  assert_eq(
    moscow.offset_from_abbreviation("MSK", in_2020),
    @tz.FixedOffset::east(3 * 3600),
  )
}

///|
test "offset_from_abbreviation falls back to the first matching type when the abbreviation is not in effect (America/New_York)" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let summer = utc_at(1_719_835_200L)
  let winter = utc_at(1_704_110_400L)
  assert_eq(
    ny.offset_from_abbreviation("EDT", summer),
    @tz.FixedOffset::east(-4 * 3600),
  )
  assert_eq(
    ny.offset_from_abbreviation("EST", summer),
    @tz.FixedOffset::east(-5 * 3600),
  )
  assert_eq(
    ny.offset_from_abbreviation("EDT", winter),
    @tz.FixedOffset::east(-4 * 3600),
  )
  assert_eq(
    ny.offset_from_abbreviation("EST", winter),
    @tz.FixedOffset::east(-5 * 3600),
  )
}

///|
test "offset_from_abbreviation finds a historical-only abbreviation and rejects an unknown one" {
  let ny = @tz.Location::from_tzif_bytes(tzif_new_york).unwrap()
  let now = utc_at(1_719_835_200L)
  assert_true(ny.offset_from_abbreviation("LMT", now) is Some(_))
  assert_eq(ny.offset_from_abbreviation("XYZ", now), None)
  assert_eq(ny.offset_from_abbreviation("", now), None)
}

///|
test "offset_from_abbreviation resolves a fixed zone's only abbreviation (Asia/Tokyo JST)" {
  let tokyo = @tz.Location::from_tzif_bytes(tzif_tokyo).unwrap()
  assert_eq(
    tokyo.offset_from_abbreviation("JST", utc_at(0L)),
    @tz.FixedOffset::east(9 * 3600),
  )
}

///|
test "utc is a Location named UTC with a zero offset and no daylight saving" {
  let utc = @tz.Location::utc()
  let epoch = @core.NaiveDateTime::unix_epoch()
  assert_eq(utc.name(), Some("UTC"))
  assert_eq(utc.offset_from_utc(epoch), @tz.FixedOffset::east(0).unwrap())
  assert_eq(utc.zone_name(epoch), "UTC")
  assert_eq(utc.is_dst(epoch), false)
}

///|
test "utc is the same zone that load resolves for the name UTC" {
  assert_true(@tz.Location::utc() == @tz.Location::load("UTC").unwrap())
}

///|
test "utc agrees with the Utc zone at any instant" {
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  assert_eq(
    @tz.Location::utc().offset_from_utc(dt),
    @tz.Utc::new().offset_from_utc(dt),
  )
  assert_eq(
    @tz.Location::utc().offset_from_local(dt),
    @tz.Utc::new().offset_from_local(dt),
  )
}

///|
test "load rejects an empty zone name instead of treating it as UTC" {
  assert_true(@tz.Location::load("") is None)
}

///|
test "Location and TzifData compare structurally with a diagnostic representation" {
  let a = @tz.Location::load("Asia/Tokyo").unwrap()
  let b = @tz.Location::load("Asia/Tokyo").unwrap()
  assert_eq(a, b)
  let tzif = @tz.parse_tzif(tzif_tokyo).unwrap()
  assert_eq(tzif, @tz.parse_tzif(tzif_tokyo).unwrap())
}
