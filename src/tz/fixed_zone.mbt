///|
/// A named time zone with one constant offset (no daylight saving): the
/// name is what `zone_name` (and so `%Z`) reports, in place of the offset text
/// a bare `FixedOffset` falls back to.
///
/// Two zones are equal only when both the name and the offset are equal.
pub struct FixedZone {
  priv name : String
  priv offset : FixedOffset
} derive(Eq, Hash, @debug.Debug)

///|
pub extend FixedZone with Eq::{equal}

///|
pub extend FixedZone with Eq::{not_equal}

///|
pub extend FixedZone with Hash::{hash, hash_combine}

///|
pub extend FixedZone with @debug.Debug::{to_repr}

///|
/// Renders as the zone's name, the same text as `zone_name`.
pub impl Show for FixedZone with fn output(self, logger) {
  logger.write_string(self.name)
}

///|
pub extend FixedZone with Show::{to_string, output}

///|
/// A zone called `name` whose offset is always `offset`.
pub fn FixedZone::new(name : String, offset : FixedOffset) -> FixedZone {
  FixedZone::{ name, offset, }
}

///|
/// The name the zone was built with, e.g. `"JST"`: the identifier of this
/// zone, which is also what `zone_name` reports at every instant.
pub fn FixedZone::name(self : FixedZone) -> String {
  self.name
}

///|
/// The zone's constant offset.
pub fn FixedZone::offset(self : FixedZone) -> FixedOffset {
  self.offset
}

///|
pub impl TimeZone for FixedZone with fn offset_from_utc(self, _dt) {
  self.offset
}

///|
pub impl TimeZone for FixedZone with fn offset_from_local(self, _dt) {
  Single(self.offset)
}

///|
pub impl TimeZone for FixedZone with fn zone_name(self, _dt) {
  self.name
}

///|
pub impl TimeZone for FixedZone with fn offset_from_abbreviation(
  self,
  abbreviation,
  _near,
) {
  if abbreviation == self.name {
    Some(self.offset)
  } else {
    None
  }
}

///|
pub extend FixedZone with TimeZone::{
  offset_from_utc,
  offset_from_local,
  zone_name,
  is_dst,
  transition_bounds,
  offset_from_abbreviation,
}
