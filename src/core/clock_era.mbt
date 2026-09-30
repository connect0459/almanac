///|
/// A year split around the Common Era: whether it is in the Common Era
/// (`is_ce`, years `1` and later) and the positive number of the year within
/// that era, so year `0` is `1` BCE. See `NaiveDate::year_ce`.
pub struct YearCe {
  priv is_ce : Bool
  priv year : Int
} derive(Eq, Hash, @debug.Debug)

///|
pub extend YearCe with Eq::{equal, not_equal}

///|
pub extend YearCe with Hash::{hash, hash_combine}

///|
pub extend YearCe with @debug.Debug::{to_repr}

///|
/// Whether the year is in the Common Era (year `1` and later).
pub fn YearCe::is_ce(self : YearCe) -> Bool {
  self.is_ce
}

///|
/// The positive year number within its era.
pub fn YearCe::year(self : YearCe) -> Int {
  self.year
}

///|
/// An hour on a 12-hour clock: whether it is PM (`is_pm`) and the hour,
/// `1..=12`, where midnight and noon read `12`. See `NaiveTime::hour12`.
pub struct ClockHour12 {
  priv is_pm : Bool
  priv hour : Int
} derive(Eq, Hash, @debug.Debug)

///|
pub extend ClockHour12 with Eq::{equal, not_equal}

///|
pub extend ClockHour12 with Hash::{hash, hash_combine}

///|
pub extend ClockHour12 with @debug.Debug::{to_repr}

///|
/// Whether the hour is in the afternoon (`12:00` and later on a 24-hour
/// clock).
pub fn ClockHour12::is_pm(self : ClockHour12) -> Bool {
  self.is_pm
}

///|
/// The hour on the 12-hour clock, `1..=12`.
pub fn ClockHour12::hour(self : ClockHour12) -> Int {
  self.hour
}
