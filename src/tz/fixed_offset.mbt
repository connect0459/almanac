///|
/// A fixed UTC offset, constant year-round (no daylight saving).
///
/// Represented as the signed number of seconds added to UTC to obtain the
/// local time, within `±23:59:59` (`±86399` seconds).
pub struct FixedOffset {
  priv local_minus_utc : Int
} derive(Eq, Hash, @debug.Debug)

///|
pub extend FixedOffset with Eq::{equal}

///|
pub extend FixedOffset with Eq::{not_equal}

///|
pub extend FixedOffset with Hash::{hash, hash_combine}

///|
pub extend FixedOffset with @debug.Debug::{to_repr}

///|
/// Renders as a colon-separated sign, hour and minute, e.g. `+09:00`,
/// extended with a seconds component for a non-whole-minute offset, e.g.
/// `-04:56:02`; the same text as `tz_name`.
pub impl Show for FixedOffset with fn output(self, logger) {
  logger.write_string(format_offset_colon(self.local_minus_utc))
}

///|
pub extend FixedOffset with Show::{to_string, output}

///|
/// The fixed offset `secs` seconds east of UTC (local time is ahead of
/// UTC), or `None` if `secs` is outside `±86399` (`±23:59:59`).
pub fn FixedOffset::east(secs : Int) -> FixedOffset? {
  if secs > 86399 || secs < -86399 {
    None
  } else {
    Some(FixedOffset::{ local_minus_utc: secs, })
  }
}

///|
/// The fixed offset `secs` seconds west of UTC (local time is behind UTC),
/// or `None` if `secs` is outside `±86399` (`±23:59:59`).
pub fn FixedOffset::west(secs : Int) -> FixedOffset? {
  FixedOffset::east(-secs)
}

///|
/// The signed number of seconds added to UTC to obtain local time.
pub fn FixedOffset::local_minus_utc(self : FixedOffset) -> Int {
  self.local_minus_utc
}

///|
fn pad2(n : Int) -> String {
  if n < 10 {
    "0" + n.to_string()
  } else {
    n.to_string()
  }
}

///|
/// Renders `secs` as a signed `HH:MM` string, extended to `HH:MM:SS` when
/// the offset is not a whole minute (e.g. a pre-standardization local mean
/// time zone).
fn format_offset_colon(secs : Int) -> String {
  let sign = if secs < 0 { "-" } else { "+" }
  let magnitude = if secs < 0 { -secs } else { secs }
  let hours = magnitude / 3600
  let minutes = magnitude % 3600 / 60
  let seconds = magnitude % 60
  if seconds == 0 {
    sign + pad2(hours) + ":" + pad2(minutes)
  } else {
    sign + pad2(hours) + ":" + pad2(minutes) + ":" + pad2(seconds)
  }
}

///|
pub impl TimeZone for FixedOffset with fn offset_from_utc(self, _dt) {
  self
}

///|
pub impl TimeZone for FixedOffset with fn offset_from_local(self, _dt) {
  Single(self)
}

///|
pub impl TimeZone for FixedOffset with fn tz_name(self, _dt) {
  format_offset_colon(self.local_minus_utc)
}

///|
pub extend FixedOffset with TimeZone::{
  offset_from_utc,
  offset_from_local,
  tz_name,
  is_dst,
  transition_bounds,
  from_utc_datetime,
  from_local_datetime,
}
