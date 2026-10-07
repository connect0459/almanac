///|
/// The week containing a `NaiveDate`, under a configurable first day of
/// the week (see `NaiveDate::week`). Distinct from `IsoWeek`, which is
/// always Monday-based and tied to the ISO 8601 week-numbering year.
///
/// Two `NaiveWeek`s are equal (and compare) by the calendar week they
/// denote, i.e. by their first day alone — the anchor date and `start`
/// weekday used to construct them don't affect equality.
///
/// A week at either end of `NaiveDate`'s representable range can extend
/// past it. Such a week can still be constructed, compared and hashed;
/// `first_day`, `last_day` and `days` abort if they would leave the range,
/// and `checked_first_day`, `checked_last_day` and `checked_days` return
/// `None` instead.
pub struct NaiveWeek {
  priv date : NaiveDate
  priv start : Weekday
} derive(@debug.Debug)

///|
fn NaiveWeek::first_epoch_days(self : NaiveWeek) -> Int64 {
  let back = (
      self.date.weekday().num_days_from_monday() -
      self.start.num_days_from_monday() +
      7
    ) %
    7
  self.date.epoch_days().to_int64() - back.to_int64()
}

///|
pub impl Eq for NaiveWeek with fn equal(self, other) {
  self.first_epoch_days() == other.first_epoch_days()
}

///|
pub extend NaiveWeek with Eq::{equal}

///|
pub extend NaiveWeek with Eq::{not_equal}

///|
pub impl Compare for NaiveWeek with fn compare(self, other) {
  self.first_epoch_days().compare(other.first_epoch_days())
}

///|
pub extend NaiveWeek with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub impl Hash for NaiveWeek with fn hash_combine(self, hasher) {
  Hash::hash_combine(self.first_epoch_days(), hasher)
}

///|
pub extend NaiveWeek with Hash::{hash, hash_combine}

///|
pub extend NaiveWeek with @debug.Debug::{to_repr}

///|
/// The first day of the week (the `start` weekday, on or before the date
/// this week was constructed from).
///
/// Aborts if that day falls before `NaiveDate`'s representable range; use
/// `checked_first_day` to get `None` instead.
pub fn NaiveWeek::first_day(self : NaiveWeek) -> NaiveDate {
  expect_in_range(self.checked_first_day(), "NaiveWeek::first_day")
}

///|
/// The first day of the week, or `None` if it falls before `NaiveDate`'s
/// representable range.
pub fn NaiveWeek::checked_first_day(self : NaiveWeek) -> NaiveDate? {
  NaiveDate::from_epoch_days64(self.first_epoch_days())
}

///|
/// The last day of the week, six days after the first.
///
/// Aborts if that day falls after `NaiveDate`'s representable range; use
/// `checked_last_day` to get `None` instead.
pub fn NaiveWeek::last_day(self : NaiveWeek) -> NaiveDate {
  expect_in_range(self.checked_last_day(), "NaiveWeek::last_day")
}

///|
/// The last day of the week, six days after the first, or `None` if it
/// falls after `NaiveDate`'s representable range.
pub fn NaiveWeek::checked_last_day(self : NaiveWeek) -> NaiveDate? {
  NaiveDate::from_epoch_days64(self.first_epoch_days() + 6L)
}

///|
/// All seven days of the week, from the first day to the last.
///
/// Aborts if any of them falls outside `NaiveDate`'s representable range;
/// use `checked_days` to get `None` instead.
pub fn NaiveWeek::days(self : NaiveWeek) -> Array[NaiveDate] {
  expect_in_range(self.checked_days(), "NaiveWeek::days")
}

///|
/// All seven days of the week, from the first day to the last, or `None`
/// if any of them falls outside `NaiveDate`'s representable range.
pub fn NaiveWeek::checked_days(self : NaiveWeek) -> Array[NaiveDate]? {
  let first = self.first_epoch_days()
  let result = []
  for i = 0L; i < 7L; i = i + 1L {
    match NaiveDate::from_epoch_days64(first + i) {
      Some(day) => result.push(day)
      None => return None
    }
  }
  Some(result)
}
