///|
/// An ISO 8601 week date's year and week number. The ISO year may differ
/// from the calendar year of any date that falls in it (see `NaiveDate::iso_week`).
pub struct IsoWeek {
  priv year : Int
  priv week : Int
} derive(Eq, @debug.Debug)

///|
pub extend IsoWeek with Eq::{equal}

///|
pub extend IsoWeek with Eq::{not_equal}

///|
pub extend IsoWeek with @debug.Debug::{to_repr}

///|
/// The ISO 8601 week-numbering year.
pub fn IsoWeek::year(self : IsoWeek) -> Int {
  self.year
}

///|
/// The 1-based ISO 8601 week number.
pub fn IsoWeek::week(self : IsoWeek) -> Int {
  self.week
}

///|
/// The 0-based ISO 8601 week number.
pub fn IsoWeek::week0(self : IsoWeek) -> Int {
  self.week - 1
}
