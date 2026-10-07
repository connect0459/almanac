///|
/// A collection of `Weekday` values, stored as a 7-bit set.
///
/// Bit `i` corresponds to the weekday whose `Weekday::index()` is `i`
/// (`Mon = 0` .. `Sun = 6`); higher bits are always `0`.
///
/// Sets have no total order: the bit layout is a representation detail and
/// the meaningful relation is `is_subset`.
pub struct WeekdaySet {
  priv bits : Int
} derive(Eq, Hash, @debug.Debug)

///|
pub extend WeekdaySet with Eq::{equal}

///|
pub extend WeekdaySet with Eq::{not_equal}

///|
/// Renders as a bracketed list of the members' short names in `Mon..Sun`
/// order, e.g. `[Mon, Fri]`; the empty set is `[]`.
pub impl Show for WeekdaySet with fn output(self, logger) {
  let names = self.to_array().map(day => day.short_name())
  logger.write_string("[" + names.join(", ") + "]")
}

///|
pub extend WeekdaySet with Show::{to_string, output}

///|
pub extend WeekdaySet with Hash::{hash, hash_combine}

///|
/// The empty set; see `empty`.
pub impl Default for WeekdaySet with fn default() {
  WeekdaySet::empty()
}

///|
pub extend WeekdaySet with Default::{default}

///|
pub extend WeekdaySet with @debug.Debug::{to_repr}

///|
let all_weekdays : Array[Weekday] = [Mon, Tue, Wed, Thu, Fri, Sat, Sun]

///|
fn bit_for(day : Weekday) -> Int {
  1 << day.index()
}

///|
/// The empty set, containing no weekdays; `Default::default()` returns it.
pub fn WeekdaySet::empty() -> WeekdaySet {
  { bits: 0, }
}

///|
/// The set containing all seven weekdays.
pub fn WeekdaySet::all() -> WeekdaySet {
  { bits: 0b111_1111, }
}

///|
/// A set containing exactly the given weekday; `single_day` reads it back.
pub fn WeekdaySet::single(day : Weekday) -> WeekdaySet {
  { bits: bit_for(day), }
}

///|
/// A set containing exactly the given weekdays.
pub fn WeekdaySet::from_array(days : Array[Weekday]) -> WeekdaySet {
  WeekdaySet::from_iter(days.iter())
}

///|
/// A set containing exactly the weekdays the iterator yields; repeated
/// weekdays count once and the order is irrelevant.
pub fn WeekdaySet::from_iter(days : Iter[Weekday]) -> WeekdaySet {
  let mut bits = 0
  for day in days {
    bits = bits | bit_for(day)
  }
  { bits, }
}

///|
/// `Some(day)` if the set contains exactly one weekday, `None` otherwise; the
/// inverse of `WeekdaySet::single`.
pub fn WeekdaySet::single_day(self : WeekdaySet) -> Weekday? {
  match self.bits {
    0b000_0001 => Some(Mon)
    0b000_0010 => Some(Tue)
    0b000_0100 => Some(Wed)
    0b000_1000 => Some(Thu)
    0b001_0000 => Some(Fri)
    0b010_0000 => Some(Sat)
    0b100_0000 => Some(Sun)
    _ => None
  }
}

///|
/// The set with `day` added, unchanged if it was already a member.
pub fn WeekdaySet::insert(self : WeekdaySet, day : Weekday) -> WeekdaySet {
  { bits: self.bits | bit_for(day), }
}

///|
/// The set with `day` removed, unchanged if it was not a member.
pub fn WeekdaySet::remove(self : WeekdaySet, day : Weekday) -> WeekdaySet {
  { bits: self.bits & bit_for(day).lnot(), }
}

///|
/// Whether the set contains `day`.
pub fn WeekdaySet::contains(self : WeekdaySet, day : Weekday) -> Bool {
  (self.bits & bit_for(day)) != 0
}

///|
/// Whether every weekday in `self` is also in `other`.
pub fn WeekdaySet::is_subset(self : WeekdaySet, other : WeekdaySet) -> Bool {
  self.intersection(other) == self
}

///|
/// Weekdays that are in both `self` and `other`.
pub fn WeekdaySet::intersection(
  self : WeekdaySet,
  other : WeekdaySet,
) -> WeekdaySet {
  { bits: self.bits & other.bits, }
}

///|
/// Weekdays that are in either `self` or `other`.
pub fn WeekdaySet::union(self : WeekdaySet, other : WeekdaySet) -> WeekdaySet {
  { bits: self.bits | other.bits, }
}

///|
/// Weekdays that are in `self` or `other`, but not in both.
pub fn WeekdaySet::symmetric_difference(
  self : WeekdaySet,
  other : WeekdaySet,
) -> WeekdaySet {
  { bits: self.bits ^ other.bits, }
}

///|
/// Weekdays that are in `self` but not in `other`.
pub fn WeekdaySet::difference(
  self : WeekdaySet,
  other : WeekdaySet,
) -> WeekdaySet {
  { bits: self.bits & other.bits.lnot(), }
}

///|
/// The earliest weekday in the set, starting from Monday.
pub fn WeekdaySet::first(self : WeekdaySet) -> Weekday? {
  for day in all_weekdays {
    if self.contains(day) {
      return Some(day)
    }
  }
  None
}

///|
/// The latest weekday in the set, starting from Sunday.
pub fn WeekdaySet::last(self : WeekdaySet) -> Weekday? {
  for i = all_weekdays.length() - 1; i >= 0; i = i - 1 {
    let day = all_weekdays[i]
    if self.contains(day) {
      return Some(day)
    }
  }
  None
}

///|
/// Whether the set contains no weekdays.
pub fn WeekdaySet::is_empty(self : WeekdaySet) -> Bool {
  self.bits == 0
}

///|
/// The number of weekdays in the set.
pub fn WeekdaySet::length(self : WeekdaySet) -> Int {
  let mut count = 0
  for day in all_weekdays {
    if self.contains(day) {
      count = count + 1
    }
  }
  count
}

///|
/// The weekdays in the set, in `Mon..Sun` order.
pub fn WeekdaySet::to_array(self : WeekdaySet) -> Array[Weekday] {
  let result = []
  for day in all_weekdays {
    if self.contains(day) {
      result.push(day)
    }
  }
  result
}
