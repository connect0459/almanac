///|
/// An iterator over the members of a `WeekdaySet` in cyclic weekday order
/// from a chosen start weekday, double-ended: `next` walks forward from the
/// start (wrapping from `Sun` to `Mon`) and `next_back` walks backward from
/// the end of that cycle. See `WeekdaySet::iter_from`.
pub struct WeekdaySetIterator {
  priv mut remaining : WeekdaySet
  priv start : Weekday
} derive(@debug.Debug)

///|
pub extend WeekdaySetIterator with @debug.Debug::{to_repr}

///|
fn WeekdaySetIterator::day_at(
  self : WeekdaySetIterator,
  offset : Int,
) -> Weekday {
  Weekday::from_num_days_from_monday(
    (self.start.num_days_from_monday() + offset) % 7,
  ).unwrap()
}

///|
/// The next member from the front of the cycle, or `None` once every member
/// has been yielded from either end.
pub fn WeekdaySetIterator::next(self : WeekdaySetIterator) -> Weekday? {
  for offset in 0..<7 {
    let day = self.day_at(offset)
    if self.remaining.contains(day) {
      self.remaining = self.remaining.remove(day)
      return Some(day)
    }
  }
  None
}

///|
/// The next member from the back of the cycle, or `None` once every member
/// has been yielded from either end.
pub fn WeekdaySetIterator::next_back(self : WeekdaySetIterator) -> Weekday? {
  for offset = 6; offset >= 0; offset = offset - 1 {
    let day = self.day_at(offset)
    if self.remaining.contains(day) {
      self.remaining = self.remaining.remove(day)
      return Some(day)
    }
  }
  None
}

///|
/// The number of members remaining to be yielded.
pub fn WeekdaySetIterator::length(self : WeekdaySetIterator) -> Int {
  self.remaining.length()
}

///|
/// This iterator as a standard `Iter`, so it works in a `for` loop and with
/// adapters such as `map` and `take`. The `Iter` shares this iterator's
/// state, as for `NaiveDateDaysIterator::iter`.
pub fn WeekdaySetIterator::iter(self : WeekdaySetIterator) -> Iter[Weekday] {
  Iter::new(() => self.next(), size_hint=self.length())
}

///|
/// A double-ended iterator over this set's members in cyclic weekday order
/// starting at `start` (default `Mon`), wrapping from `Sun` to `Mon`: a
/// start weekday that is not a member simply begins at the next member. See
/// `WeekdaySetIterator`.
pub fn WeekdaySet::iter_from(
  self : WeekdaySet,
  start? : Weekday = Mon,
) -> WeekdaySetIterator {
  WeekdaySetIterator::{ remaining: self, start, }
}

///|
/// This set's members in cyclic weekday order starting at `start` (default
/// `Mon`, which matches `to_array`), as a standard `Iter`, usable in a `for`
/// loop (`for day in set.iter(start=Sun)`) and with adapters. Use
/// `iter_from` for a double-ended iterator.
pub fn WeekdaySet::iter(
  self : WeekdaySet,
  start? : Weekday = Mon,
) -> Iter[Weekday] {
  self.iter_from(start~).iter()
}
