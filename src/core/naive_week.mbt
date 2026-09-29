///|
/// The week containing a `NaiveDate`, under a configurable first day of
/// the week (see `NaiveDate::week`). Distinct from `IsoWeek`, which is
/// always Monday-based and tied to the ISO 8601 week-numbering year.
///
/// Two `NaiveWeek`s are equal (and compare) by the calendar week they
/// denote, i.e. by `first_day()` alone — the anchor date and `start`
/// weekday used to construct them don't affect equality.
pub struct NaiveWeek {
  priv first_day : NaiveDate
  priv start : Weekday
} derive(@debug.Debug)

///|
pub impl Eq for NaiveWeek with fn equal(self, other) {
  self.first_day == other.first_day
}

///|
pub extend NaiveWeek with Eq::{equal}

///|
pub extend NaiveWeek with Eq::{not_equal}

///|
pub impl Compare for NaiveWeek with fn compare(self, other) {
  self.first_day.compare(other.first_day)
}

///|
pub extend NaiveWeek with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub impl Hash for NaiveWeek with fn hash_combine(self, hasher) {
  self.first_day.hash_combine(hasher)
}

///|
pub extend NaiveWeek with Hash::{hash, hash_combine}

///|
pub extend NaiveWeek with @debug.Debug::{to_repr}

///|
/// The first day of the week (the `start` weekday, on or before the date
/// this week was constructed from).
pub fn NaiveWeek::first_day(self : NaiveWeek) -> NaiveDate {
  self.first_day
}

///|
/// The last day of the week, six days after `first_day()`.
pub fn NaiveWeek::last_day(self : NaiveWeek) -> NaiveDate {
  self.first_day.add_days(6)
}

///|
/// All seven days of the week, from `first_day()` to `last_day()`.
pub fn NaiveWeek::days(self : NaiveWeek) -> Array[NaiveDate] {
  let result = []
  for i = 0; i < 7; i = i + 1 {
    result.push(self.first_day.add_days(i))
  }
  result
}
