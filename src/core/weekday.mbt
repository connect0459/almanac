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
/// The English name of the weekday.
pub fn Weekday::name(self : Weekday) -> String {
  match self {
    Mon => "Monday"
    Tue => "Tuesday"
    Wed => "Wednesday"
    Thu => "Thursday"
    Fri => "Friday"
    Sat => "Saturday"
    Sun => "Sunday"
  }
}

///|
pub impl Show for Weekday with fn output(self, logger) {
  logger.write_string(self.name())
}

///|
pub extend Weekday with Show::{to_string, output}

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
/// The `Weekday` whose `number_from_monday()` is `n` (ISO 8601 numbering:
/// `1` = `Mon`, `7` = `Sun`), or `None` if `n` is outside `1..=7`.
pub fn Weekday::from_number_from_monday(n : Int) -> Weekday? {
  Weekday::from_num_days_from_monday(n - 1)
}

///|
/// The `Weekday` whose `number_from_sunday()` is `n` (`1` = `Sun`,
/// `7` = `Sat`), or `None` if `n` is outside `1..=7`.
pub fn Weekday::from_number_from_sunday(n : Int) -> Weekday? {
  Weekday::from_num_days_from_sunday(n - 1)
}

///|
/// The `Weekday` whose `num_days_from_monday()` is `n` (`0` = `Mon`), or
/// `None` if `n` is outside `0..=6`.
pub fn Weekday::from_num_days_from_monday(n : Int) -> Weekday? {
  match n {
    0 => Some(Mon)
    1 => Some(Tue)
    2 => Some(Wed)
    3 => Some(Thu)
    4 => Some(Fri)
    5 => Some(Sat)
    6 => Some(Sun)
    _ => None
  }
}

///|
/// The `Weekday` whose `num_days_from_sunday()` is `n` (`0` = `Sun`), or
/// `None` if `n` is outside `0..=6`.
pub fn Weekday::from_num_days_from_sunday(n : Int) -> Weekday? {
  match n {
    0 => Some(Sun)
    1..=6 => Weekday::from_num_days_from_monday(n - 1)
    _ => None
  }
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
