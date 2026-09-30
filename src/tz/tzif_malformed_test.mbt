///|
fn be32(value : Int) -> Array[Byte] {
  [
    ((value >> 24) & 0xFF).to_byte(),
    ((value >> 16) & 0xFF).to_byte(),
    ((value >> 8) & 0xFF).to_byte(),
    (value & 0xFF).to_byte(),
  ]
}

///|
/// A version-1 TZif buffer built from its parts: each type is
/// `(utc_offset, is_dst, designation_index)`, and `chars` is the raw
/// designation block.
fn tzif_v1_build(
  transitions : Array[Int],
  transition_types : Array[Int],
  types : Array[(Int, Int, Int)],
  chars : Array[Int],
) -> Bytes {
  let out : Array[Byte] = [b'T', b'Z', b'i', b'f']
  for _ in 0..<16 {
    out.push(b'\x00')
  }
  for count in [0, 0, 0, transitions.length(), types.length(), chars.length()] {
    out.push_iter(be32(count).iter())
  }
  for t in transitions {
    out.push_iter(be32(t).iter())
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
  Bytes::from_array(out)
}

///|
let standard_types : Array[(Int, Int, Int)] = [(0, 0, 0), (3600, 1, 2)]

///|
let standard_chars : Array[Int] = [0x41, 0, 0x42, 0]

///|
test "a well-formed hand-built TZif buffer parses, so the malformed cases below differ only in the defect" {
  let parsed = @tz.parse_tzif(
    tzif_v1_build([100, 200], [1, 0], standard_types, standard_chars),
  ).unwrap()
  assert_eq(parsed.transitions(), [100L, 200L])
  assert_eq(parsed.local_time_types().length(), 2)
}

///|
test "parse_tzif rejects a transition that names a local time type which does not exist" {
  assert_true(
    @tz.parse_tzif(tzif_v1_build([100], [2], standard_types, standard_chars))
    is None,
  )
}

///|
test "parse_tzif rejects a file with no local time type" {
  assert_true(@tz.parse_tzif(tzif_v1_build([], [], [], [0])) is None)
}

///|
test "parse_tzif rejects an abbreviation index past the designation block" {
  assert_true(
    @tz.parse_tzif(tzif_v1_build([], [], [(0, 0, 4)], standard_chars)) is None,
  )
}

///|
test "parse_tzif rejects an abbreviation that is not NUL-terminated inside the designation block" {
  assert_true(
    @tz.parse_tzif(tzif_v1_build([], [], [(0, 0, 0)], [0x41, 0x42])) is None,
  )
}

///|
test "parse_tzif rejects transitions that are not strictly increasing" {
  assert_true(
    @tz.parse_tzif(
      tzif_v1_build([200, 100], [0, 1], standard_types, standard_chars),
    )
    is None,
  )
  assert_true(
    @tz.parse_tzif(
      tzif_v1_build([100, 100], [0, 1], standard_types, standard_chars),
    )
    is None,
  )
}

///|
test "parse_tzif rejects a header count so large that the section sizes overflow" {
  let valid = tzif_v1_build([], [], [(0, 0, 0)], [0x41, 0]).to_array()
  let bytes_of_count = be32(0x7FFFFFFF)
  for i in 0..<4 {
    valid[32 + i] = bytes_of_count[i]
  }
  assert_true(@tz.parse_tzif(Bytes::from_array(valid)) is None)
}

///|
test "parse_tzif rejects a negative header count" {
  let valid = tzif_v1_build([], [], [(0, 0, 0)], [0x41, 0]).to_array()
  for i in 0..<4 {
    valid[32 + i] = b'\xFF'
  }
  assert_true(@tz.parse_tzif(Bytes::from_array(valid)) is None)
}
