///|
/// A proleptic Gregorian calendar date, without a time-of-day or time zone.
///
/// Internally represented as a day count relative to the Unix epoch
/// (`1970-01-01` is day `0`).
pub struct NaiveDate {
  priv days : Int
} derive(Eq, @debug.Debug)

///|
pub extend NaiveDate with Eq::{equal}

///|
pub extend NaiveDate with Eq::{not_equal}

///|
pub extend NaiveDate with @debug.Debug::{to_repr}

///|
/// Constructs the date for a given proleptic Gregorian `(year, month, day)`,
/// or `None` if `month` is outside `1..=12` or `day` is outside the range of
/// days in that month.
pub fn NaiveDate::from_ymd(year : Int, month : Int, day : Int) -> NaiveDate? {
  match month_from_number(month) {
    None => None
    Some(m) =>
      if day >= 1 && day <= m.num_days(year) {
        Some(NaiveDate::{ days: days_from_civil(year, month, day), })
      } else {
        None
      }
  }
}

///|
/// Constructs the date for a given `year` and 1-based day-of-year `ordinal`,
/// or `None` if `ordinal` is outside `1..=365` (`1..=366` in a leap year).
pub fn NaiveDate::from_yo(year : Int, ordinal : Int) -> NaiveDate? {
  let days_in_year = if is_leap_year(year) { 366 } else { 365 }
  if ordinal >= 1 && ordinal <= days_in_year {
    Some(NaiveDate::{ days: days_from_civil(year, 1, 1) + ordinal - 1, })
  } else {
    None
  }
}

///|
/// The number of ISO 8601 weeks (52 or 53) in the given ISO week-numbering
/// `year`.
fn nisoweeks(year : Int) -> Int {
  let jan1_weekday = weekday_from_days(days_from_civil(year, 1, 1))
  if jan1_weekday == Thu || (is_leap_year(year) && jan1_weekday == Wed) {
    53
  } else {
    52
  }
}

///|
/// Constructs the date for a given ISO 8601 week date (ISO year, 1-based
/// week number, and weekday), or `None` if `week` does not exist in that ISO
/// year. The resulting date's calendar year may differ from `year` (a week
/// near a year boundary can belong to the adjoining calendar year).
pub fn NaiveDate::from_isoywd(
  year : Int,
  week : Int,
  weekday : Weekday,
) -> NaiveDate? {
  if week < 1 || week > nisoweeks(year) {
    return None
  }
  let jan4 = days_from_civil(year, 1, 4)
  let week1_monday = jan4 - weekday_from_days(jan4).num_days_from_monday()
  let days = week1_monday + (week - 1) * 7 + weekday.num_days_from_monday()
  Some(NaiveDate::{ days, })
}

///|
/// The proleptic Gregorian calendar year.
pub fn NaiveDate::year(self : NaiveDate) -> Int {
  let (year, _, _) = civil_from_days(self.days)
  year
}

///|
/// The month of the year.
pub fn NaiveDate::month(self : NaiveDate) -> Month {
  let (_, month, _) = civil_from_days(self.days)
  month_from_number(month).unwrap()
}

///|
/// The day of the month.
pub fn NaiveDate::day(self : NaiveDate) -> Int {
  let (_, _, day) = civil_from_days(self.days)
  day
}

///|
/// The 1-based day of the year.
pub fn NaiveDate::ordinal(self : NaiveDate) -> Int {
  let (year, _, _) = civil_from_days(self.days)
  self.days - days_from_civil(year, 1, 1) + 1
}

///|
/// The day of the week.
pub fn NaiveDate::weekday(self : NaiveDate) -> Weekday {
  weekday_from_days(self.days)
}

///|
/// Whether the date's calendar year is a leap year.
pub fn NaiveDate::leap_year(self : NaiveDate) -> Bool {
  is_leap_year(self.year())
}

///|
/// The ISO 8601 week-numbering year and week this date falls in. Computed
/// as the calendar year and day-of-year of the Thursday in this date's
/// week, since the ISO week containing a year's first Thursday is always
/// that year's week 1.
pub fn NaiveDate::iso_week(self : NaiveDate) -> IsoWeek {
  let thursday_offset = 4 - self.weekday().number_from_monday()
  let thursday_days = self.days + thursday_offset
  let (thursday_year, _, _) = civil_from_days(thursday_days)
  let yday = thursday_days - days_from_civil(thursday_year, 1, 1) + 1
  IsoWeek::{ year: thursday_year, week: (yday - 1) / 7 + 1, }
}

///|
/// The date with the year replaced by `year`, or `None` if the current
/// month and day do not exist in `year` (e.g. moving February 29 into a
/// year that is not a leap year).
pub fn NaiveDate::with_year(self : NaiveDate, year : Int) -> NaiveDate? {
  let (_, month, day) = civil_from_days(self.days)
  NaiveDate::from_ymd(year, month, day)
}

///|
/// The date with the month replaced by `month`, or `None` if `month` is
/// outside `1..=12` or the current day does not exist in that month.
pub fn NaiveDate::with_month(self : NaiveDate, month : Int) -> NaiveDate? {
  let (year, _, day) = civil_from_days(self.days)
  NaiveDate::from_ymd(year, month, day)
}

///|
/// The date with the day-of-month replaced by `day`, or `None` if `day` is
/// outside the current month's length.
pub fn NaiveDate::with_day(self : NaiveDate, day : Int) -> NaiveDate? {
  let (year, month, _) = civil_from_days(self.days)
  NaiveDate::from_ymd(year, month, day)
}

///|
/// The date with the day-of-year replaced by `ordinal`, or `None` if
/// `ordinal` is outside `1..=365` (`1..=366` in a leap year).
pub fn NaiveDate::with_ordinal(self : NaiveDate, ordinal : Int) -> NaiveDate? {
  let (year, _, _) = civil_from_days(self.days)
  NaiveDate::from_yo(year, ordinal)
}

///|
/// The next calendar day.
pub fn NaiveDate::succ(self : NaiveDate) -> NaiveDate {
  self.add_days(1)
}

///|
/// The previous calendar day.
pub fn NaiveDate::pred(self : NaiveDate) -> NaiveDate {
  self.sub_days(1)
}

///|
/// The date `days` days after this one (or before it, if `days` is
/// negative).
pub fn NaiveDate::add_days(self : NaiveDate, days : Int) -> NaiveDate {
  NaiveDate::{ days: self.days + days, }
}

///|
/// The date `days` days before this one (or after it, if `days` is
/// negative).
pub fn NaiveDate::sub_days(self : NaiveDate, days : Int) -> NaiveDate {
  NaiveDate::{ days: self.days - days, }
}

///|
/// The date `months` months after this one (or before it, if `months` is
/// negative). The day-of-month is clamped to the target month's length
/// when it doesn't exist there (e.g. Jan 31 + 1 month becomes Feb 28 or
/// Feb 29).
pub fn NaiveDate::add_months(self : NaiveDate, months : Int) -> NaiveDate {
  let (year, month, day) = civil_from_days(self.days)
  let total = year * 12 + (month - 1) + months
  let new_year = floor_div(total, 12)
  let new_month = floor_mod(total, 12) + 1
  let max_day = month_from_number(new_month).unwrap().num_days(new_year)
  let clamped_day = if day > max_day { max_day } else { day }
  NaiveDate::{ days: days_from_civil(new_year, new_month, clamped_day), }
}

///|
/// The date `months` months before this one (or after it, if `months` is
/// negative). See `add_months` for the day-of-month clamping rule.
pub fn NaiveDate::sub_months(self : NaiveDate, months : Int) -> NaiveDate {
  self.add_months(-months)
}
