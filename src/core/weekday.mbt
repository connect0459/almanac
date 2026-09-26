///|
/// A day of the week.
///
/// The variant order below has no calendar meaning by itself; use
/// `number_from_monday`, `number_from_sunday`, `num_days_from_monday`, or
/// `num_days_from_sunday` to get a day-of-week number in a specific
/// counting convention.
pub(all) enum Weekday {
  Mon
  Tue
  Wed
  Thu
  Fri
  Sat
  Sun
} derive(Eq, @debug.Debug)

///|
pub extend Weekday with Eq::{equal}

///|
pub extend Weekday with Eq::{not_equal}

///|
pub extend Weekday with @debug.Debug::{to_repr}

///|
fn Weekday::index(self : Weekday) -> Int {
  match self {
    Mon => 0
    Tue => 1
    Wed => 2
    Thu => 3
    Fri => 4
    Sat => 5
    Sun => 6
  }
}

///|
/// The next day, wrapping from `Sun` back to `Mon`.
pub fn Weekday::succ(self : Weekday) -> Weekday {
  match self {
    Mon => Tue
    Tue => Wed
    Wed => Thu
    Thu => Fri
    Fri => Sat
    Sat => Sun
    Sun => Mon
  }
}

///|
/// The previous day, wrapping from `Mon` back to `Sun`.
pub fn Weekday::pred(self : Weekday) -> Weekday {
  match self {
    Mon => Sun
    Tue => Mon
    Wed => Tue
    Thu => Wed
    Fri => Thu
    Sat => Fri
    Sun => Sat
  }
}

///|
/// Day-of-week number counting from `Mon = 0`.
pub fn Weekday::num_days_from_monday(self : Weekday) -> Int {
  self.index()
}

///|
/// Day-of-week number counting from `Sun = 0`.
pub fn Weekday::num_days_from_sunday(self : Weekday) -> Int {
  (self.index() + 1) % 7
}

///|
/// ISO 8601 day-of-week number, counting from `Mon = 1`.
pub fn Weekday::number_from_monday(self : Weekday) -> Int {
  self.num_days_from_monday() + 1
}

///|
/// Day-of-week number counting from `Sun = 1`.
pub fn Weekday::number_from_sunday(self : Weekday) -> Int {
  self.num_days_from_sunday() + 1
}

///|
/// The number of days elapsed since `other`, wrapping forward through the
/// week (always in `0..=6`).
pub fn Weekday::days_since(self : Weekday, other : Weekday) -> Int {
  (self.index() - other.index() + 7) % 7
}

///|
/// The weekday of the given day count relative to the Unix epoch
/// (`1970-01-01`, day `0`, was a `Thu`).
fn weekday_from_days(days : Int) -> Weekday {
  match floor_mod(days + 3, 7) {
    0 => Mon
    1 => Tue
    2 => Wed
    3 => Thu
    4 => Fri
    5 => Sat
    _ => Sun
  }
}
