///|
/// A named IANA time zone, backed by parsed TZif (RFC 8536) data plus,
/// when the file provides one, the POSIX TZ rule used to extrapolate
/// offsets past the file's last recorded transition.
pub struct Location {
  priv tzif : TzifData
  priv posix_tz : PosixTz?
  priv name : String?
} derive(Eq, Hash)

///|
pub extend Location with Eq::{equal}

///|
pub extend Location with Eq::{not_equal}

///|
pub extend Location with Hash::{hash, hash_combine}

///|
/// Renders as `name()`, or as an empty string for a `Location` without one.
pub impl Show for Location with fn output(self, logger) {
  logger.write_string(self.name.unwrap_or(""))
}

///|
pub extend Location with Show::{to_string, output}

///|
/// Constructs a `Location` from raw TZif bytes, or `None` if the bytes
/// are malformed, or its POSIX TZ footer (when present) is malformed.
/// `name()` reports `None`, since raw bytes carry no IANA identifier; use
/// `Location::from_tzif_bytes_named` or `Location::load` to construct a
/// `Location` whose `name()` is known.
pub fn Location::from_tzif_bytes(data : Bytes) -> Location? {
  match parse_tzif(data) {
    None => None
    Some(tzif) =>
      match tzif.posix_tz() {
        None => Some(Location::{ tzif, posix_tz: None, name: None, })
        Some(s) =>
          match parse_posix_tz(s) {
            None => None
            Some(p) => Some(Location::{ tzif, posix_tz: Some(p), name: None, })
          }
      }
  }
}

///|
/// Like `Location::from_tzif_bytes`, but `name()` reports `name`. Any text
/// is accepted as given, without validation.
pub fn Location::from_tzif_bytes_named(
  name : String,
  data : Bytes,
) -> Location? {
  Location::from_tzif_bytes(data).map(loc => Location::{
    ..loc,
    name: Some(name),
  })
}

///|
/// The IANA zone identifier this `Location` was loaded with (e.g.
/// `"Asia/Tokyo"`), or `None` if it was constructed via
/// `Location::from_tzif_bytes` instead. Distinct from `tz_name`, which
/// reports the instant-specific abbreviation (e.g. `"JST"`). Reports the
/// name exactly as given to `Location::load`, not the canonical name an
/// alias resolves to (mirrors Go's `time.LoadLocation`).
pub fn Location::name(self : Location) -> String? {
  self.name
}

///|
/// The bytes for `name` in `zones`, following `name` through `aliases`
/// (to its canonical name) when it is not itself a key of `zones`. `None`
/// if `name` is not a key of either map.
pub fn resolve_tzdata_bytes(
  zones : Map[String, Bytes],
  aliases : Map[String, String],
  name : String,
) -> Bytes? {
  match zones.get(name) {
    Some(bytes) => Some(bytes)
    None =>
      match aliases.get(name) {
        None => None
        Some(canonical) => zones.get(canonical)
      }
  }
}

///|
/// Loads the `Location` for the given embedded IANA zone name (e.g.
/// `"America/New_York"`), or `None` if `name` is not a known zone or its
/// embedded TZif bytes are malformed.
pub fn Location::load(name : String) -> Location? {
  match resolve_tzdata_bytes(tzdata_zones, tzdata_aliases, name) {
    None => None
    Some(bytes) => Location::from_tzif_bytes_named(name, bytes)
  }
}

///|
/// The UTC zone as a `Location`, for APIs that take a `Location` rather than
/// the separate `Utc` type: the embedded `"UTC"` zone, so `name()` is
/// `Some("UTC")`. Equal to `Location::load("UTC")`.
///
/// `Location::load("")` is not an alias for UTC (unlike Go's `LoadLocation`)
/// and returns `None`, so an empty name cannot silently become UTC.
pub fn Location::utc() -> Location {
  Location::load("UTC").unwrap()
}

///|
/// The local time type in effect before this zone's first recorded
/// transition (or for its entire timeline, if it has none): the first
/// non-DST type, or the first type if every type observes DST (RFC
/// 8536's rule for pre-first-transition instants).
fn Location::initial_type(self : Location) -> LocalTimeType {
  let types = self.tzif.local_time_types()
  for i = 0 {
    if i >= types.length() {
      break types[0]
    }
    if !types[i].is_dst() {
      break types[i]
    }
    continue i + 1
  }
}

///|
/// The index into `local_time_types` (via `transition_types`) in effect
/// at `target`, or `None` if `target` is before this zone's first
/// recorded transition, or it has none (use `initial_type` instead).
fn Location::segment_at(self : Location, target : Int64) -> Int? {
  let transitions = self.tzif.transitions()
  if transitions.is_empty() {
    None
  } else {
    let segment = match transitions.binary_search(target) {
      Ok(i) => i
      Err(i) => i - 1
    }
    if segment < 0 {
      None
    } else {
      Some(segment)
    }
  }
}

///|
/// The UTC offset a zone abbreviation (e.g. `"EST"`) denotes in this zone:
/// the offset of the local time type in effect at `near` if its
/// abbreviation matches, otherwise that of the first local time type in the
/// zone's table with that abbreviation, or `None` if no type has it. The
/// fallback is what resolves an abbreviation the zone is not observing at
/// `near`, such as `"EST"` in summer.
pub fn Location::offset_from_abbreviation(
  self : Location,
  abbreviation : String,
  near : @core.NaiveDateTime,
) -> FixedOffset? {
  let in_effect = self.type_at(near)
  if in_effect.abbreviation() == abbreviation {
    FixedOffset::east(in_effect.utc_offset())
  } else {
    match
      self.tzif
      .local_time_types()
      .iter()
      .find_first(t => t.abbreviation() == abbreviation) {
      Some(t) => FixedOffset::east(t.utc_offset())
      None => None
    }
  }
}

///|
/// Whether `target` is strictly past this zone's last recorded
/// transition (and so should be resolved via `posix_tz` rather than the
/// transition table).
fn Location::past_last_transition(self : Location, target : Int64) -> Bool {
  let transitions = self.tzif.transitions()
  !transitions.is_empty() && target > transitions[transitions.length() - 1]
}

///|
fn Location::type_at_segment(self : Location, segment : Int) -> LocalTimeType {
  self.tzif.local_time_types()[self.tzif.transition_types()[segment]]
}

///|
/// The local time type (offset, DST flag, and abbreviation) in effect at
/// the given UTC instant.
pub fn Location::type_at(
  self : Location,
  utc : @core.NaiveDateTime,
) -> LocalTimeType {
  let target = utc.timestamp()
  if self.past_last_transition(target) {
    match self.posix_tz {
      Some(p) => p.type_at(target)
      None => self.type_at_segment(self.tzif.transitions().length() - 1)
    }
  } else {
    match self.segment_at(target) {
      None => self.initial_type()
      Some(segment) => self.type_at_segment(segment)
    }
  }
}

///|
/// The validity window of the time-zone segment covering a given instant:
/// the local time type `type_at` reports is in effect from `start`
/// (inclusive) until `end` (exclusive). `None` on either side means
/// unbounded in that direction. Mirrors Go's `Time.ZoneBounds` (which
/// instead uses a zero-value `Time` sentinel for "unbounded").
pub struct TransitionBounds {
  priv start : @core.NaiveDateTime?
  priv end : @core.NaiveDateTime?
} derive(Eq, Hash, @debug.Debug)

///|
pub extend TransitionBounds with Eq::{equal}

///|
pub extend TransitionBounds with Eq::{not_equal}

///|
pub extend TransitionBounds with Hash::{hash, hash_combine}

///|
pub extend TransitionBounds with @debug.Debug::{to_repr}

///|
/// The instant this segment began, or `None` if it extends back
/// indefinitely (before the zone's first recorded transition, or for a
/// zone with no transitions at all).
pub fn TransitionBounds::start(self : TransitionBounds) -> @core.NaiveDateTime? {
  self.start
}

///|
/// The instant the next segment begins, or `None` if this segment
/// extends forward indefinitely (past the zone's last recorded
/// transition, when no POSIX rule extrapolates further).
pub fn TransitionBounds::end(self : TransitionBounds) -> @core.NaiveDateTime? {
  self.end
}

///|
/// The validity window of the segment covering `utc`. See
/// `TransitionBounds`.
pub fn Location::transition_bounds(
  self : Location,
  utc : @core.NaiveDateTime,
) -> TransitionBounds {
  let target = utc.timestamp()
  let transitions = self.tzif.transitions()
  fn at(secs : Int64) -> @core.NaiveDateTime {
    @core.NaiveDateTime::from_timestamp(secs, 0).unwrap()
  }

  if self.past_last_transition(target) {
    let unbounded_forward = TransitionBounds::{
      start: Some(at(transitions[transitions.length() - 1])),
      end: None,
    }
    match self.posix_tz {
      None => unbounded_forward
      Some(p) =>
        match p.bounds_at(target) {
          None => unbounded_forward
          Some((start, end)) =>
            TransitionBounds::{ start: Some(at(start)), end: Some(at(end)), }
        }
    }
  } else {
    match self.segment_at(target) {
      None =>
        TransitionBounds::{
          start: None,
          end: if transitions.is_empty() {
            None
          } else {
            Some(at(transitions[0]))
          },
        }
      Some(segment) => {
        let n = transitions.length()
        TransitionBounds::{
          start: Some(at(transitions[segment])),
          end: if segment + 1 < n {
            Some(at(transitions[segment + 1]))
          } else {
            None
          },
        }
      }
    }
  }
}

///|
pub impl TimeZone for Location with fn offset_from_utc(self, utc) {
  FixedOffset::east(self.type_at(utc).utc_offset()).unwrap()
}

///|
pub impl TimeZone for Location with fn tz_name(self, utc) {
  self.type_at(utc).abbreviation()
}

///|
/// Whether `segment` is a valid candidate resolution for the local
/// (wall-clock) reading `local_ts`: converting `local_ts` back to UTC via
/// `segment`'s own offset lands within `segment`'s own true range. This
/// (rather than trusting whichever segment a first-guess lookup landed
/// on) is what correctly identifies gaps and folds: near a transition,
/// the segment that a naive lookup finds is not necessarily the one
/// `local_ts` actually resolves through.
fn Location::candidate_offset(
  self : Location,
  segment : Int,
  local_ts : Int64,
) -> Int? {
  let transitions = self.tzif.transitions()
  let n = transitions.length()
  if segment < 0 || segment >= n {
    None
  } else {
    let offset = self.type_at_segment(segment).utc_offset()
    let candidate_utc = local_ts - offset.to_int64()
    let lower_ok = segment == 0 || candidate_utc >= transitions[segment]
    let upper_ok = segment == n - 1 || candidate_utc < transitions[segment + 1]
    if lower_ok && upper_ok {
      Some(offset)
    } else {
      None
    }
  }
}

///|
/// A gap or fold only ever straddles a single transition, so of the three
/// neighboring segments checked below, only an adjacent pair (`prev` with
/// `cur`, or `cur` with `next`) can ever be valid together; the remaining
/// combinations are unreachable with well-formed TZif data and exist only
/// to make the match exhaustive.
pub impl TimeZone for Location with fn offset_from_local(self, naive_local) {
  let local_ts = naive_local.timestamp()
  if self.past_last_transition(local_ts) {
    match self.posix_tz {
      Some(p) => p.offset_from_local(naive_local)
      None =>
        Single(
          FixedOffset::east(
            self
            .type_at_segment(self.tzif.transitions().length() - 1)
            .utc_offset(),
          ).unwrap(),
        )
    }
  } else {
    match self.segment_at(local_ts) {
      None =>
        Single(FixedOffset::east(self.initial_type().utc_offset()).unwrap())
      Some(segment) => {
        let prev = self.candidate_offset(segment - 1, local_ts)
        let cur = self.candidate_offset(segment, local_ts)
        let next = self.candidate_offset(segment + 1, local_ts)
        match (prev, cur, next) {
          (None, None, None) => Absent
          (Some(a), None, None) => Single(FixedOffset::east(a).unwrap())
          (None, Some(a), None) => Single(FixedOffset::east(a).unwrap())
          (None, None, Some(a)) => Single(FixedOffset::east(a).unwrap())
          (Some(a), Some(b), None) =>
            Ambiguous(
              FixedOffset::east(a).unwrap(),
              FixedOffset::east(b).unwrap(),
            )
          (None, Some(a), Some(b)) =>
            Ambiguous(
              FixedOffset::east(a).unwrap(),
              FixedOffset::east(b).unwrap(),
            )
          _ => Absent
        }
      }
    }
  }
}

///|
pub impl TimeZone for Location with fn is_dst(self, utc) {
  self.type_at(utc).is_dst()
}

///|
pub impl TimeZone for Location with fn transition_bounds(self, utc) {
  Location::transition_bounds(self, utc)
}

///|
pub impl TimeZone for Location with fn offset_from_abbreviation(
  self,
  abbreviation,
  near,
) {
  Location::offset_from_abbreviation(self, abbreviation, near)
}

///|
pub extend Location with TimeZone::{
  offset_from_utc,
  offset_from_local,
  tz_name,
  is_dst,
  from_utc_datetime,
  from_local_datetime,
}
