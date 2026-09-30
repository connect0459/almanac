///|
/// A month of the year.
pub(all) enum Month {
  Jan
  Feb
  Mar
  Apr
  May
  Jun
  Jul
  Aug
  Sep
  Oct
  Nov
  Dec
} derive(Eq, Compare, Hash, @debug.Debug)

///|
pub extend Month with Eq::{equal}

///|
pub extend Month with Eq::{not_equal}

///|
pub extend Month with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub extend Month with Hash::{hash, hash_combine}

///|
pub extend Month with @debug.Debug::{to_repr}

///|
/// The next month, wrapping from `Dec` back to `Jan`.
pub fn Month::succ(self : Month) -> Month {
  match self {
    Jan => Feb
    Feb => Mar
    Mar => Apr
    Apr => May
    May => Jun
    Jun => Jul
    Jul => Aug
    Aug => Sep
    Sep => Oct
    Oct => Nov
    Nov => Dec
    Dec => Jan
  }
}

///|
/// The month `n` months after `self` (before it, for a negative `n`),
/// wrapping around the year in either direction.
pub fn Month::add(self : Month, n : Int) -> Month {
  let index = (self.number_from_month() - 1 + n % 12 + 12) % 12
  Month::from_number(index + 1).unwrap()
}

///|
/// The previous month, wrapping from `Jan` back to `Dec`.
pub fn Month::pred(self : Month) -> Month {
  match self {
    Jan => Dec
    Feb => Jan
    Mar => Feb
    Apr => Mar
    May => Apr
    Jun => May
    Jul => Jun
    Aug => Jul
    Sep => Aug
    Oct => Sep
    Nov => Oct
    Dec => Nov
  }
}

///|
/// Month-of-year number counting from `Jan = 1`.
pub fn Month::number_from_month(self : Month) -> Int {
  match self {
    Jan => 1
    Feb => 2
    Mar => 3
    Apr => 4
    May => 5
    Jun => 6
    Jul => 7
    Aug => 8
    Sep => 9
    Oct => 10
    Nov => 11
    Dec => 12
  }
}

///|
/// The English name of the month.
pub fn Month::name(self : Month) -> String {
  match self {
    Jan => "January"
    Feb => "February"
    Mar => "March"
    Apr => "April"
    May => "May"
    Jun => "June"
    Jul => "July"
    Aug => "August"
    Sep => "September"
    Oct => "October"
    Nov => "November"
    Dec => "December"
  }
}

///|
pub impl Show for Month with fn output(self, logger) {
  logger.write_string(self.name())
}

///|
pub extend Month with Show::{to_string, output}

///|
/// The month named by `name`: its full English name (`"January"`) or its
/// three-letter abbreviation (`"Jan"`), ignoring ASCII letter case, or
/// `None` for anything else (including a prefix, an abbreviation of another
/// length such as `"Sept"`, surrounding whitespace, or non-ASCII text).
pub fn Month::from_name(name : String) -> Month? {
  let key = ascii_lower(name)
  for number in 1..<=12 {
    let month = Month::from_number(number).unwrap()
    if key == ascii_lower(month.name()) ||
      key == ascii_lower(month.short_name()) {
      return Some(month)
    }
  }
  None
}

///|
/// The month for a 1-based month-of-year number, or `None` if `n` is
/// outside `1..=12`.
pub fn Month::from_number(n : Int) -> Month? {
  match n {
    1 => Some(Jan)
    2 => Some(Feb)
    3 => Some(Mar)
    4 => Some(Apr)
    5 => Some(May)
    6 => Some(Jun)
    7 => Some(Jul)
    8 => Some(Aug)
    9 => Some(Sep)
    10 => Some(Oct)
    11 => Some(Nov)
    12 => Some(Dec)
    _ => None
  }
}

///|
/// The number of days in the month for the given (proleptic Gregorian)
/// `year`, accounting for leap years in `Feb`.
pub fn Month::num_days(self : Month, year : Int) -> Int {
  match self {
    Jan => 31
    Feb => if is_leap_year(year) { 29 } else { 28 }
    Mar => 31
    Apr => 30
    May => 31
    Jun => 30
    Jul => 31
    Aug => 31
    Sep => 30
    Oct => 31
    Nov => 30
    Dec => 31
  }
}
