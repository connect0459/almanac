///|
/// Conservative, round upper bound used as the default limit for
/// `NaiveDate::iter_days`/`iter_weeks`: `+275760-09-13`, matching the
/// well-known ECMAScript `Date` representable range (100,000,000 days from
/// the Unix epoch). This is a practical default, not `NaiveDate`'s actual
/// overflow-safe range (day counts stay correct up to roughly
/// `Int::max_value() - 719_468`, around the year 5,879,610) — a round,
/// well-precedented number is easier to reason about and document than
/// that exact margin.
const ITER_BOUND_DAYS : Int = 100_000_000

///|
/// A lazy, bounded, double-ended iterator over successive dates, stepping
/// by one day. See `NaiveDate::iter_days`.
pub struct NaiveDateDaysIterator {
  priv mut value : NaiveDate
  priv mut end : NaiveDate
} derive(@debug.Debug)

///|
pub extend NaiveDateDaysIterator with @debug.Debug::{to_repr}

///|
/// The next date, advancing forward, or `None` once every date up to and
/// including the upper bound has been yielded.
pub fn NaiveDateDaysIterator::next(self : NaiveDateDaysIterator) -> NaiveDate? {
  if self.value > self.end {
    None
  } else {
    let current = self.value
    self.value = current.succ()
    Some(current)
  }
}

///|
/// The next date from the back, moving backward, or `None` once every
/// date down to and including the current front has been yielded.
pub fn NaiveDateDaysIterator::next_back(
  self : NaiveDateDaysIterator,
) -> NaiveDate? {
  if self.value > self.end {
    None
  } else {
    let current = self.end
    self.end = current.pred()
    Some(current)
  }
}

///|
/// The number of dates remaining to be yielded.
pub fn NaiveDateDaysIterator::length(self : NaiveDateDaysIterator) -> Int {
  if self.value.days > self.end.days {
    0
  } else {
    self.end.days - self.value.days + 1
  }
}

///|
/// A lazy, bounded, double-ended iterator over successive dates, stepping
/// by one week. See `NaiveDate::iter_weeks`.
pub struct NaiveDateWeeksIterator {
  priv mut value : NaiveDate
  priv mut end : NaiveDate
} derive(@debug.Debug)

///|
pub extend NaiveDateWeeksIterator with @debug.Debug::{to_repr}

///|
/// The next date, advancing forward by a week, or `None` once every
/// weekly step up to and including the upper bound has been yielded.
pub fn NaiveDateWeeksIterator::next(
  self : NaiveDateWeeksIterator,
) -> NaiveDate? {
  if self.value > self.end {
    None
  } else {
    let current = self.value
    self.value = current.add_days(7)
    Some(current)
  }
}

///|
/// The next date from the back, moving backward by a week, or `None` once
/// every weekly step down to and including the current front has been
/// yielded.
pub fn NaiveDateWeeksIterator::next_back(
  self : NaiveDateWeeksIterator,
) -> NaiveDate? {
  if self.value > self.end {
    None
  } else {
    let current = self.end
    self.end = current.sub_days(7)
    Some(current)
  }
}

///|
/// The number of weekly steps remaining to be yielded.
pub fn NaiveDateWeeksIterator::length(self : NaiveDateWeeksIterator) -> Int {
  if self.value.days > self.end.days {
    0
  } else {
    (self.end.days - self.value.days) / 7 + 1
  }
}
