///|
/// The UTC time zone: a fixed offset of zero.
pub struct Utc {} derive(Eq, Hash, @debug.Debug)

///|
pub extend Utc with Eq::{equal}

///|
pub extend Utc with Eq::{not_equal}

///|
pub extend Utc with Hash::{hash, hash_combine}

///|
pub extend Utc with @debug.Debug::{to_repr}

///|
/// Renders as `UTC`, the same text as `tz_name`.
pub impl Show for Utc with fn output(_self, logger) {
  logger.write_string("UTC")
}

///|
pub extend Utc with Show::{to_string, output}

///|
/// The singleton `Utc` value.
pub fn Utc::new() -> Utc {
  Utc::{ }
}

///|
pub impl TimeZone for Utc with fn offset_from_utc(_self, _dt) {
  FixedOffset::east(0).unwrap()
}

///|
pub impl TimeZone for Utc with fn offset_from_local(_self, _dt) {
  Single(FixedOffset::east(0).unwrap())
}

///|
pub impl TimeZone for Utc with fn tz_name(_self, _dt) {
  "UTC"
}

///|
pub extend Utc with TimeZone::{
  offset_from_utc,
  offset_from_local,
  tz_name,
  is_dst,
  from_utc_datetime,
  from_local_datetime,
}
