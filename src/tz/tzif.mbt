///|
/// One local time type entry from a TZif file: a UTC offset, whether it
/// observes daylight saving, and its abbreviation (e.g. `"EST"`, `"EDT"`).
pub struct LocalTimeType {
  priv utc_offset : Int
  priv is_dst : Bool
  priv abbreviation : String
} derive(Eq, Hash, @debug.Debug)

///|
pub extend LocalTimeType with Eq::{equal}

///|
pub extend LocalTimeType with Eq::{not_equal}

///|
pub extend LocalTimeType with Hash::{hash, hash_combine}

///|
pub extend LocalTimeType with @debug.Debug::{to_repr}

///|
/// Constructs a local time type from its components, or `None` if
/// `utc_offset` is outside `±86399` seconds (`±23:59:59`), the range a
/// `FixedOffset` can hold; so every `LocalTimeType` has an offset the
/// time-zone lookups can report.
pub fn LocalTimeType::new(
  utc_offset : Int,
  is_dst : Bool,
  abbreviation : String,
) -> LocalTimeType? {
  if offset_in_range(utc_offset) {
    Some(LocalTimeType::{ utc_offset, is_dst, abbreviation, })
  } else {
    None
  }
}

///|
/// The signed number of seconds added to UTC to obtain local time under
/// this local time type.
pub fn LocalTimeType::utc_offset(self : LocalTimeType) -> Int {
  self.utc_offset
}

///|
/// Whether this local time type observes daylight saving.
pub fn LocalTimeType::is_dst(self : LocalTimeType) -> Bool {
  self.is_dst
}

///|
/// The abbreviation for this local time type (e.g. `"EST"`, `"EDT"`).
pub fn LocalTimeType::abbreviation(self : LocalTimeType) -> String {
  self.abbreviation
}

///|
/// The parsed contents of a TZif (RFC 8536) timezone-data file.
///
/// `transitions[i]` (a Unix instant) switches to the local time type
/// `local_time_types[transition_types[i]]`; `transitions` is sorted
/// ascending. `posix_tz` is the POSIX TZ footer string, present only in
/// version 2 and later files, used to extrapolate offsets past the last
/// recorded transition.
pub struct TzifData {
  priv transitions : Array[Int64]
  priv transition_types : Array[Int]
  priv local_time_types : Array[LocalTimeType]
  priv leap_seconds : Array[(Int64, Int)]
  priv posix_tz : String?
} derive(Eq, Hash)

///|
pub extend TzifData with Eq::{equal}

///|
pub extend TzifData with Eq::{not_equal}

///|
pub extend TzifData with Hash::{hash, hash_combine}

///|
/// A copy of the transitions array; changing it does not affect
/// this value.
pub fn TzifData::transitions(self : TzifData) -> Array[Int64] {
  self.transitions.copy()
}

///|
/// A copy of the transition types array; changing it does not affect
/// this value.
pub fn TzifData::transition_types(self : TzifData) -> Array[Int] {
  self.transition_types.copy()
}

///|
/// A copy of the local time types array; changing it does not affect
/// this value.
pub fn TzifData::local_time_types(self : TzifData) -> Array[LocalTimeType] {
  self.local_time_types.copy()
}

///|
/// Leap-second records `(transition, correction)`, parsed for fidelity but
/// not applied to civil-time arithmetic. Returns a copy.
pub fn TzifData::leap_seconds(self : TzifData) -> Array[(Int64, Int)] {
  self.leap_seconds.copy()
}

///|
/// The POSIX TZ footer string (e.g. `"EST5EDT,M3.2.0,M11.1.0"`), present
/// only in version 2 and later files.
pub fn TzifData::posix_tz(self : TzifData) -> String? {
  self.posix_tz
}

///|
fn read_i32_be(data : Bytes, offset : Int) -> Int {
  (data.at(offset).to_int() << 24) |
  (data.at(offset + 1).to_int() << 16) |
  (data.at(offset + 2).to_int() << 8) |
  data.at(offset + 3).to_int()
}

///|
fn read_i64_be(data : Bytes, offset : Int) -> Int64 {
  (data.at(offset).to_int64() << 56) |
  (data.at(offset + 1).to_int64() << 48) |
  (data.at(offset + 2).to_int64() << 40) |
  (data.at(offset + 3).to_int64() << 32) |
  (data.at(offset + 4).to_int64() << 24) |
  (data.at(offset + 5).to_int64() << 16) |
  (data.at(offset + 6).to_int64() << 8) |
  data.at(offset + 7).to_int64()
}

///|
/// The length of the NUL-terminated string starting at `offset`, or `None`
/// if no NUL occurs before `limit`.
fn cstring_length_within(data : Bytes, offset : Int, limit : Int) -> Int? {
  for i = offset {
    if i >= limit {
      break None
    }
    if data.at(i) == b'\x00' {
      break Some(i - offset)
    }
    continue i + 1
  }
}

///|
/// One parsed TZif data block (the portion following a 44-byte header),
/// using `time_size`-byte transition/leap times (`4` for a version-1
/// block, `8` for the version-2-and-later block that follows it).
priv struct RawBlock {
  transitions : Array[Int64]
  transition_types : Array[Int]
  local_time_types : Array[LocalTimeType]
  leap_seconds : Array[(Int64, Int)]
  /// The offset in `data` immediately following this block.
  next_offset : Int
}

///|
fn parse_block(data : Bytes, header_offset : Int, time_size : Int) -> RawBlock? {
  if data.length() < header_offset + 44 {
    return None
  }
  if data.at(header_offset).to_int() != b'T'.to_int() ||
    data.at(header_offset + 1).to_int() != b'Z'.to_int() ||
    data.at(header_offset + 2).to_int() != b'i'.to_int() ||
    data.at(header_offset + 3).to_int() != b'f'.to_int() {
    return None
  }
  let isutcnt = read_i32_be(data, header_offset + 20)
  let isstdcnt = read_i32_be(data, header_offset + 24)
  let leapcnt = read_i32_be(data, header_offset + 28)
  let timecnt = read_i32_be(data, header_offset + 32)
  let typecnt = read_i32_be(data, header_offset + 36)
  let charcnt = read_i32_be(data, header_offset + 40)
  if isutcnt < 0 ||
    isstdcnt < 0 ||
    leapcnt < 0 ||
    timecnt < 0 ||
    typecnt < 1 ||
    charcnt < 0 {
    return None
  }
  let data_size = timecnt.to_int64() * (time_size + 1).to_int64() +
    typecnt.to_int64() * 6L +
    charcnt.to_int64() +
    leapcnt.to_int64() * (time_size + 4).to_int64() +
    isstdcnt.to_int64() +
    isutcnt.to_int64()
  if data.length().to_int64() < header_offset.to_int64() + 44L + data_size {
    return None
  }
  let mut p = header_offset + 44
  let transitions = []
  for i = 0; i < timecnt; i = i + 1 {
    let transition = if time_size == 8 {
      read_i64_be(data, p)
    } else {
      read_i32_be(data, p).to_int64()
    }
    if i > 0 && transition <= transitions[i - 1] {
      return None
    }
    transitions.push(transition)
    p = p + time_size
  }
  let transition_types = []
  for i = 0; i < timecnt; i = i + 1 {
    let index = data.at(p).to_int()
    if index >= typecnt {
      return None
    }
    transition_types.push(index)
    p = p + 1
  }
  let local_time_types = []
  let designations_offset = p + typecnt * 6
  for i = 0; i < typecnt; i = i + 1 {
    let utc_offset = read_i32_be(data, p)
    let is_dst = data.at(p + 4).to_int() != 0
    let desigidx = data.at(p + 5).to_int()
    let name_offset = designations_offset + desigidx
    let name_len = match
      cstring_length_within(data, name_offset, designations_offset + charcnt) {
      None => return None
      Some(len) => len
    }
    let abbreviation = @utf8.decode_lossy(
      data.exact_view(start=name_offset, end=name_offset + name_len),
    )
    match LocalTimeType::new(utc_offset, is_dst, abbreviation) {
      None => return None
      Some(local_time_type) => local_time_types.push(local_time_type)
    }
    p = p + 6
  }
  p = designations_offset + charcnt
  let leap_seconds = []
  for i = 0; i < leapcnt; i = i + 1 {
    let t = if time_size == 8 {
      read_i64_be(data, p)
    } else {
      read_i32_be(data, p).to_int64()
    }
    let correction = read_i32_be(data, p + time_size)
    leap_seconds.push((t, correction))
    p = p + time_size + 4
  }
  p = p + isstdcnt + isutcnt
  Some(RawBlock::{
    transitions,
    transition_types,
    local_time_types,
    leap_seconds,
    next_offset: p,
  })
}

///|
/// Parses a TZif (RFC 8536) timezone-data byte buffer, or `None` if it is
/// malformed or truncated, or holds a UTC offset beyond `±23:59:59`. Also
/// rejected are structures that would make lookups misbehave: no local time
/// type, a transition naming a missing type, transitions that are not
/// strictly increasing, and an abbreviation outside the designation block.
///
/// For a version 2/3/4 file, only the 64-bit second data block (and the
/// POSIX TZ footer that follows it) is returned: the initial 32-bit block
/// exists solely for backward compatibility with readers that predate
/// 64-bit `time_t`.
pub fn parse_tzif(data : Bytes) -> TzifData? {
  match parse_block(data, 0, 4) {
    None => None
    Some(v1) =>
      if data.at(4).to_int() == 0 {
        Some(TzifData::{
          transitions: v1.transitions,
          transition_types: v1.transition_types,
          local_time_types: v1.local_time_types,
          leap_seconds: v1.leap_seconds,
          posix_tz: None,
        })
      } else {
        match parse_block(data, v1.next_offset, 8) {
          None => None
          Some(v2) =>
            parse_posix_footer(data, v2.next_offset).map(posix_tz => TzifData::{
              transitions: v2.transitions,
              transition_types: v2.transition_types,
              local_time_types: v2.local_time_types,
              leap_seconds: v2.leap_seconds,
              posix_tz: Some(posix_tz),
            })
        }
      }
  }
}

///|
/// Parses the `\n`-delimited POSIX TZ string footer starting at `offset`,
/// or `None` if it is malformed.
fn parse_posix_footer(data : Bytes, offset : Int) -> String? {
  if data.length() < offset + 2 || data.at(offset).to_int() != b'\n'.to_int() {
    None
  } else {
    let nl2 = offset + 1 + cstring_length_until_newline(data, offset + 1)
    if nl2 >= data.length() || data.at(nl2).to_int() != b'\n'.to_int() {
      None
    } else {
      Some(@utf8.decode_lossy(data.exact_view(start=offset + 1, end=nl2)))
    }
  }
}

///|
/// The number of bytes from `offset` up to (not including) the next `\n`.
fn cstring_length_until_newline(data : Bytes, offset : Int) -> Int {
  for i = offset {
    if i >= data.length() || data.at(i) == b'\n' {
      break i - offset
    }
    continue i + 1
  }
}
