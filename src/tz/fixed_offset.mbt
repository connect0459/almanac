///|
/// A fixed UTC offset, constant year-round (no daylight saving).
///
/// Represented as the signed number of seconds added to UTC to obtain the
/// local time, within `±23:59:59` (`±86399` seconds).
pub struct FixedOffset {
  priv local_minus_utc : Int
} derive(Eq, @debug.Debug)

///|
pub extend FixedOffset with Eq::{equal}

///|
pub extend FixedOffset with Eq::{not_equal}

///|
pub extend FixedOffset with @debug.Debug::{to_repr}

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
pub impl TimeZone for FixedOffset with fn offset_from_utc(self, _dt) {
  self
}

///|
pub impl TimeZone for FixedOffset with fn offset_from_local(self, _dt) {
  Single(self)
}

///|
pub extend FixedOffset with TimeZone::{offset_from_utc, offset_from_local}
