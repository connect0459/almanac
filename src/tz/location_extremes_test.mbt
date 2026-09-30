///|
fn be64(value : Int64) -> Array[Byte] {
  let out = []
  for i = 7; i >= 0; i = i - 1 {
    out.push(((value >> (i * 8)) & 0xFFL).to_int().to_byte())
  }
  out
}

///|
fn tzif_v2_build(
  transitions : Array[Int64],
  transition_types : Array[Int],
  types : Array[(Int, Int, Int)],
  chars : Array[Int],
  footer : String,
) -> Bytes {
  let out : Array[Byte] = [b'T', b'Z', b'i', b'f', b'2']
  for _ in 0..<15 {
    out.push(b'\x00')
  }
  for count in [0, 0, 0, 0, 1, 2] {
    out.push_iter(be32(count).iter())
  }
  out.push_iter([b'\x00', b'\x00', b'\x00', b'\x00', b'\x00', b'\x00'].iter())
  out.push_iter([b'X', b'\x00'].iter())
  out.push_iter([b'T', b'Z', b'i', b'f', b'2'].iter())
  for _ in 0..<15 {
    out.push(b'\x00')
  }
  for count in [0, 0, 0, transitions.length(), types.length(), chars.length()] {
    out.push_iter(be32(count).iter())
  }
  for t in transitions {
    out.push_iter(be64(t).iter())
  }
  for index in transition_types {
    out.push(index.to_byte())
  }
  for t in types {
    let (offset, is_dst, designation) = t
    out.push_iter(be32(offset).iter())
    out.push(is_dst.to_byte())
    out.push(designation.to_byte())
  }
  for c in chars {
    out.push(c.to_byte())
  }
  out.push(b'\n')
  for c in footer {
    out.push(c.to_int().to_byte())
  }
  out.push(b'\n')
  Bytes::from_array(out)
}

///|
fn exercise(loc : @tz.Location) -> Unit {
  let limit = 2_147_483_647L - 719_468L
  let instants = [
    0L,
    -limit * 86400L,
    limit * 86400L + 86399L,
    1_700_000_000L,
    -1_700_000_000L,
  ]
  for secs in instants {
    let naive = @core.NaiveDateTime::from_timestamp(secs, 0).unwrap()
    ignore(loc.type_at(naive))
    ignore(@tz.TimeZone::offset_from_utc(loc, naive))
    ignore(@tz.TimeZone::offset_from_local(loc, naive))
    ignore(@tz.TimeZone::zone_name(loc, naive))
    ignore(@tz.TimeZone::is_dst(loc, naive))
    ignore(@tz.TimeZone::transition_bounds(loc, naive))
    ignore(@tz.TimeZone::offset_from_abbreviation(loc, "X", naive))
  }
}

///|
let probe_types : Array[(Int, Int, Int)] = [(0, 0, 0), (3600, 1, 2)]

///|
let probe_chars : Array[Int] = [0x41, 0, 0x42, 0]

///|
test "a transition at Int64 max leaves every Location query total" {
  let loc = @tz.Location::from_tzif_bytes(
    tzif_v2_build([9223372036854775807L], [1], probe_types, probe_chars, "AAA0"),
  ).unwrap()
  exercise(loc)
}

///|
test "a transition at Int64 min leaves every Location query total" {
  let loc = @tz.Location::from_tzif_bytes(
    tzif_v2_build(
      [-9223372036854775807L - 1L],
      [1],
      probe_types,
      probe_chars,
      "AAA0",
    ),
  ).unwrap()
  exercise(loc)
}

///|
test "transitions at both Int64 extremes leave every Location query total" {
  let loc = @tz.Location::from_tzif_bytes(
    tzif_v2_build(
      [-9223372036854775807L - 1L, 9223372036854775807L],
      [1, 0],
      probe_types,
      probe_chars,
      "AAA0",
    ),
  ).unwrap()
  exercise(loc)
}

///|
test "a POSIX footer with a DST rule and no transitions leaves every Location query total" {
  let loc = @tz.Location::from_tzif_bytes(
    tzif_v2_build([], [], probe_types, probe_chars, "AAA5BBB,M3.2.0,M11.1.0"),
  ).unwrap()
  exercise(loc)
}

///|
test "a POSIX footer with a DST rule after the last transition leaves every Location query total, including at the date range limits" {
  let loc = @tz.Location::from_tzif_bytes(
    tzif_v2_build(
      [100L],
      [1],
      probe_types,
      probe_chars,
      "AAA5BBB,M3.2.0,M11.1.0",
    ),
  ).unwrap()
  exercise(loc)
}

///|
test "a southern-hemisphere POSIX rule leaves every Location query total, including at the date range limits" {
  let loc = @tz.Location::from_tzif_bytes(
    tzif_v2_build(
      [100L],
      [0],
      probe_types,
      probe_chars,
      "AAA-10BBB,M10.1.0,M4.1.0/3",
    ),
  ).unwrap()
  exercise(loc)
}

///|
test "extreme POSIX offsets and Julian rule dates leave every Location query total" {
  let loc = @tz.Location::from_tzif_bytes(
    tzif_v2_build(
      [100L],
      [0],
      probe_types,
      probe_chars,
      "AAA-23:59:59BBB-23:59:58,J1,J365",
    ),
  ).unwrap()
  exercise(loc)
}

///|
test "a real zone with a POSIX rule answers every query at the date range limits" {
  exercise(@tz.Location::load("America/New_York").unwrap())
  exercise(@tz.Location::load("Australia/Sydney").unwrap())
}

///|
test "a bare PosixTz answers every query at the date range limits" {
  let tz = @tz.parse_posix_tz("EST5EDT,M3.2.0,M11.1.0").unwrap()
  let limit = 2_147_483_647L - 719_468L
  for secs in [-limit * 86400L, limit * 86400L + 86399L] {
    let naive = @core.NaiveDateTime::from_timestamp(secs, 0).unwrap()
    ignore(tz.type_at(naive))
    ignore(@tz.TimeZone::offset_from_local(tz, naive))
    ignore(@tz.TimeZone::transition_bounds(tz, naive))
  }
}
