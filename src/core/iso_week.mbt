///|
/// An ISO 8601 week date's year and week number. The ISO year may differ
/// from the calendar year of any date that falls in it (see `NaiveDate::iso_week`).
pub struct IsoWeek {
  priv year : Int
  priv week : Int
} derive(Eq, Compare, Hash, @debug.Debug)

///|
pub extend IsoWeek with Eq::{equal}

///|
pub extend IsoWeek with Eq::{not_equal}

///|
pub extend IsoWeek with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub extend IsoWeek with Hash::{hash, hash_combine}

///|
pub extend IsoWeek with @debug.Debug::{to_repr}

///|
/// Renders as `YYYY-Www`, e.g. `2015-W38`; a year outside `0..=9999` gets an
/// explicit sign (`+10000-W01`).
pub impl Show for IsoWeek with fn output(self, logger) {
  logger.write_string(year_text(self.year) + "-W" + pad_zero(self.week, 2))
}

///|
pub extend IsoWeek with Show::{to_string, output}

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
