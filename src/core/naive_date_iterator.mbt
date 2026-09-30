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
///
/// An iterator is a position that is consumed, the one stateful kind of
/// value in this package: `next` and `next_back` advance it in place, `iter`
/// does not advance it by itself but returns an `Iter` that shares its
/// state, and the method that creates it (`NaiveDate::iter_days`) returns a fresh iterator on
/// every call, leaving the date unchanged.
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
/// This iterator as a standard `Iter`, so it works in a `for` loop
/// (`for date in start.iter_days()`) and with adapters such as `map` and
/// `take`. The `Iter` shares this iterator's state: whatever it consumes
/// from the front is consumed here too, and it stops before any dates
/// already taken with `next_back`.
pub fn NaiveDateDaysIterator::iter(
  self : NaiveDateDaysIterator,
) -> Iter[NaiveDate] {
  Iter::new(() => self.next(), size_hint=self.length())
}

///|
/// A lazy, bounded, double-ended iterator over successive dates, stepping
/// by one week. See `NaiveDate::iter_weeks`.
///
/// An iterator is a position that is consumed, the one stateful kind of
/// value in this package: `next` and `next_back` advance it in place, `iter`
/// does not advance it by itself but returns an `Iter` that shares its
/// state, and the method that creates it (`NaiveDate::iter_weeks`) returns a fresh iterator on
/// every call, leaving the date unchanged.
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

///|
/// This iterator as a standard `Iter`, so it works in a `for` loop
/// (`for date in start.iter_weeks()`) and with adapters such as `map` and
/// `take`. The `Iter` shares this iterator's state, as for
/// `NaiveDateDaysIterator::iter`.
pub fn NaiveDateWeeksIterator::iter(
  self : NaiveDateWeeksIterator,
) -> Iter[NaiveDate] {
  Iter::new(() => self.next(), size_hint=self.length())
}
