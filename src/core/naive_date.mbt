///|
/// A proleptic Gregorian calendar date, without a time-of-day or time zone.
///
/// Internally represented as a day count relative to the Unix epoch
/// (`1970-01-01` is day `0`).
pub struct NaiveDate {
  priv days : Int
} derive(Eq, Compare, Hash, @debug.Debug)

///|
pub extend NaiveDate with Eq::{equal}

///|
pub extend NaiveDate with Eq::{not_equal}

///|
pub extend NaiveDate with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
pub extend NaiveDate with Hash::{hash, hash_combine}

///|
/// The Unix epoch date, `1970-01-01`.
pub impl Default for NaiveDate with fn default() {
  NaiveDate::{ days: 0, }
}

///|
pub extend NaiveDate with Default::{default}

///|
pub extend NaiveDate with @debug.Debug::{to_repr}

///|
/// Renders as `YYYY-MM-DD`; a year outside `0..=9999` gets an explicit sign
/// (`-0001-12-31`, `+10000-01-01`).
pub impl Show for NaiveDate with fn output(self, logger) {
  logger.write_string(
    year_text(self.year()) +
    "-" +
    pad_zero(self.month().number(), 2) +
    "-" +
    pad_zero(self.day(), 2),
  )
}

///|
pub extend NaiveDate with Show::{to_string, output}

///|
/// Constructs the date for a given proleptic Gregorian `(year, month, day)`,
/// or `None` if `month` is outside `1..=12` or `day` is outside the range of
/// days in that month.
pub fn NaiveDate::from_ymd(year : Int, month : Int, day : Int) -> NaiveDate? {
  match Month::from_number(month) {
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
  Month::from_number(month).unwrap()
}

///|
/// The year, month, and day of month together.
pub fn NaiveDate::ymd(self : NaiveDate) -> (Int, Month, Int) {
  (self.year(), self.month(), self.day())
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
/// The month of the year, counting from `0` (`Jan` is `0`, `Dec` is `11`).
pub fn NaiveDate::month0(self : NaiveDate) -> Int {
  self.month().number() - 1
}

///|
/// The day of the month, counting from `0` (`0..=30`).
pub fn NaiveDate::day0(self : NaiveDate) -> Int {
  self.day() - 1
}

///|
/// The day of the year, counting from `0` (`0..=365`).
pub fn NaiveDate::ordinal0(self : NaiveDate) -> Int {
  self.ordinal() - 1
}

///|
/// The year split into a Common Era flag and a positive year number: year
/// `1` and later are `(true, year)`, and year `0` and earlier are
/// `(false, 1 - year)`, so year `0` is `(false, 1)` and year `-1` is
/// `(false, 2)`.
pub fn NaiveDate::year_ce(self : NaiveDate) -> (Bool, Int) {
  let year = self.year()
  if year >= 1 {
    (true, year)
  } else {
    (false, 1 - year)
  }
}

///|
/// The number of days in this date's month, accounting for leap years; see
/// `Month::num_days` for a month and a year given separately.
pub fn NaiveDate::num_days_in_month(self : NaiveDate) -> Int {
  self.month().num_days(self.year())
}

///|
/// The number of days between this date and `other`, always non-negative
/// regardless of which is earlier.
pub fn NaiveDate::abs_diff(self : NaiveDate, other : NaiveDate) -> Int64 {
  let diff = self.days.to_int64() - other.days.to_int64()
  if diff < 0L {
    -diff
  } else {
    diff
  }
}

///|
/// Like `with_month`, but taking a `0`-based month (`0..=11`).
pub fn NaiveDate::with_month0(self : NaiveDate, month0 : Int) -> NaiveDate? {
  self.with_month(month0 + 1)
}

///|
/// Like `with_day`, but taking a `0`-based day of the month.
pub fn NaiveDate::with_day0(self : NaiveDate, day0 : Int) -> NaiveDate? {
  self.with_day(day0 + 1)
}

///|
/// Like `with_ordinal`, but taking a `0`-based day of the year.
pub fn NaiveDate::with_ordinal0(self : NaiveDate, ordinal0 : Int) -> NaiveDate? {
  self.with_ordinal(ordinal0 + 1)
}

///|
/// The next calendar day.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `succ_opt` to get `None` instead.
pub fn NaiveDate::succ(self : NaiveDate) -> NaiveDate {
  expect_in_range(self.succ_opt(), "NaiveDate::succ")
}

///|
const CE_TO_EPOCH_DAYS : Int64 = 719_163L

///|
fn NaiveDate::from_epoch_days64(days : Int64) -> NaiveDate? {
  if days > MAX_ABS_EPOCH_DAYS || days < -MAX_ABS_EPOCH_DAYS {
    None
  } else {
    Some(NaiveDate::{ days: days.to_int(), })
  }
}

///|
/// The number of days since the Unix epoch (`1970-01-01` is day `0`;
/// earlier dates are negative).
pub fn NaiveDate::epoch_days(self : NaiveDate) -> Int {
  self.days
}

///|
/// The date `days` days after the Unix epoch (`1970-01-01` is day `0`), or
/// `None` if `days` falls outside `NaiveDate`'s representable range.
pub fn NaiveDate::from_epoch_days(days : Int) -> NaiveDate? {
  NaiveDate::from_epoch_days64(days.to_int64())
}

///|
/// The number of days since the start of the Common Era, counting
/// `0001-01-01` as day `1` (so `0000-12-31` is day `0`).
pub fn NaiveDate::num_days_from_ce(self : NaiveDate) -> Int {
  self.days + CE_TO_EPOCH_DAYS.to_int()
}

///|
/// The date whose `num_days_from_ce()` is `days`, or `None` if `days`
/// falls outside `NaiveDate`'s representable range.
pub fn NaiveDate::from_num_days_from_ce(days : Int) -> NaiveDate? {
  NaiveDate::from_epoch_days64(days.to_int64() - CE_TO_EPOCH_DAYS)
}

///|
/// The datetime at `time` on this date.
pub fn NaiveDate::and_time(self : NaiveDate, time : NaiveTime) -> NaiveDateTime {
  NaiveDateTime::new(self, time)
}

///|
/// The datetime at `hour:min:sec` on this date, or `None` if any time
/// component is out of range (see `NaiveTime::from_hms`).
pub fn NaiveDate::and_hms(
  self : NaiveDate,
  hour : Int,
  min : Int,
  sec : Int,
) -> NaiveDateTime? {
  NaiveTime::from_hms(hour, min, sec).map(time => self.and_time(time))
}

///|
/// The datetime at `hour:min:sec` plus `milli` milliseconds on this date,
/// or `None` if any time component is out of range (see
/// `NaiveTime::from_hms_milli`).
pub fn NaiveDate::and_hms_milli(
  self : NaiveDate,
  hour : Int,
  min : Int,
  sec : Int,
  milli : Int,
) -> NaiveDateTime? {
  NaiveTime::from_hms_milli(hour, min, sec, milli).map(time => {
    self.and_time(time)
  })
}

///|
/// The datetime at `hour:min:sec` plus `micro` microseconds on this date,
/// or `None` if any time component is out of range (see
/// `NaiveTime::from_hms_micro`).
pub fn NaiveDate::and_hms_micro(
  self : NaiveDate,
  hour : Int,
  min : Int,
  sec : Int,
  micro : Int,
) -> NaiveDateTime? {
  NaiveTime::from_hms_micro(hour, min, sec, micro).map(time => {
    self.and_time(time)
  })
}

///|
/// The datetime at `hour:min:sec` plus `nano` nanoseconds on this date, or
/// `None` if any time component is out of range (see
/// `NaiveTime::from_hms_nano`).
pub fn NaiveDate::and_hms_nano(
  self : NaiveDate,
  hour : Int,
  min : Int,
  sec : Int,
  nano : Int,
) -> NaiveDateTime? {
  NaiveTime::from_hms_nano(hour, min, sec, nano).map(time => self.and_time(time))
}

///|
const MAX_ABS_EPOCH_DAYS : Int64 = 2_147_483_647L - 719_468L

///|
/// The date `delta`'s whole days after this one. A sub-day remainder of
/// `delta` is discarded (truncation toward zero), since a date carries no
/// time-of-day.
///
/// Aborts if the day count falls outside `NaiveDate`'s representable range;
/// use `checked_add_signed` to get `None` instead.
pub fn NaiveDate::add_signed(self : NaiveDate, delta : TimeDelta) -> NaiveDate {
  expect_in_range(self.checked_add_signed(delta), "NaiveDate::add_signed")
}

///|
/// The date `delta`'s whole days before this one. A sub-day remainder of
/// `delta` is discarded (truncation toward zero).
///
/// Aborts if the day count falls outside `NaiveDate`'s representable range;
/// use `checked_sub_signed` to get `None` instead.
pub fn NaiveDate::sub_signed(self : NaiveDate, delta : TimeDelta) -> NaiveDate {
  expect_in_range(self.checked_sub_signed(delta), "NaiveDate::sub_signed")
}

///|
/// Like `add_signed`, but `None` if the day count falls outside
/// `NaiveDate`'s representable range.
pub fn NaiveDate::checked_add_signed(
  self : NaiveDate,
  delta : TimeDelta,
) -> NaiveDate? {
  NaiveDate::from_epoch_days64(self.days.to_int64() + delta.num_days())
}

///|
/// Like `sub_signed`, but `None` if the day count falls outside
/// `NaiveDate`'s representable range.
pub fn NaiveDate::checked_sub_signed(
  self : NaiveDate,
  delta : TimeDelta,
) -> NaiveDate? {
  self.checked_add_signed(delta.neg())
}

///|
/// The duration from `other` to this date, always a whole number of days.
/// Total: `NaiveDate`'s day range is far narrower than `TimeDelta`'s.
pub fn NaiveDate::signed_duration_since(
  self : NaiveDate,
  other : NaiveDate,
) -> TimeDelta {
  TimeDelta::days(self.days.to_int64() - other.days.to_int64()).unwrap()
}

///|
/// The previous calendar day.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `pred_opt` to get `None` instead.
pub fn NaiveDate::pred(self : NaiveDate) -> NaiveDate {
  expect_in_range(self.pred_opt(), "NaiveDate::pred")
}

///|
/// The date `days` days after this one (or before it, if `days` is
/// negative).
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_days` to get `None` instead.
pub fn NaiveDate::add_days(self : NaiveDate, days : Int) -> NaiveDate {
  expect_in_range(self.checked_add_days(days), "NaiveDate::add_days")
}

///|
/// The date `days` days after this one (or before it, if `days` is
/// negative), or `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn NaiveDate::checked_add_days(self : NaiveDate, days : Int) -> NaiveDate? {
  self.checked_add_days64(days.to_int64())
}

///|
/// The date `days` days before this one (or after it, if `days` is
/// negative), or `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn NaiveDate::checked_sub_days(self : NaiveDate, days : Int) -> NaiveDate? {
  self.checked_add_days64(-days.to_int64())
}

///|
fn NaiveDate::checked_add_days64(self : NaiveDate, days : Int64) -> NaiveDate? {
  NaiveDate::from_epoch_days64(self.days.to_int64() + days)
}

///|
/// The next calendar day, or `None` if this is the last representable
/// date.
pub fn NaiveDate::succ_opt(self : NaiveDate) -> NaiveDate? {
  self.checked_add_days(1)
}

///|
/// The previous calendar day, or `None` if this is the first representable
/// date.
pub fn NaiveDate::pred_opt(self : NaiveDate) -> NaiveDate? {
  self.checked_sub_days(1)
}

///|
/// The date `days` days before this one (or after it, if `days` is
/// negative).
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_days` to get `None` instead.
pub fn NaiveDate::sub_days(self : NaiveDate, days : Int) -> NaiveDate {
  expect_in_range(self.checked_sub_days(days), "NaiveDate::sub_days")
}

///|
/// The date `months` months after this one (or before it, if `months` is
/// negative). The day-of-month is clamped to the target month's length
/// when it doesn't exist there (e.g. Jan 31 + 1 month becomes Feb 28 or
/// Feb 29).
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_months` to get `None` instead.
pub fn NaiveDate::add_months(self : NaiveDate, months : Int) -> NaiveDate {
  expect_in_range(self.checked_add_months(months), "NaiveDate::add_months")
}

///|
/// The date `months` months after this one (or before it, if `months` is
/// negative), or `None` if the result falls outside `NaiveDate`'s
/// representable range. See `add_months` for the day-of-month clamping
/// rule.
pub fn NaiveDate::checked_add_months(
  self : NaiveDate,
  months : Int,
) -> NaiveDate? {
  self.checked_add_months64(months.to_int64())
}

///|
/// The date `months` months before this one (or after it, if `months` is
/// negative), or `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn NaiveDate::checked_sub_months(
  self : NaiveDate,
  months : Int,
) -> NaiveDate? {
  self.checked_add_months64(-months.to_int64())
}

///|
fn NaiveDate::checked_add_months64(
  self : NaiveDate,
  months : Int64,
) -> NaiveDate? {
  let (year, month, day) = civil_from_days(self.days)
  let total = year.to_int64() * 12L + (month - 1).to_int64() + months
  let new_year = floor_div64(total, 12L)
  let new_month = floor_mod64(total, 12L).to_int() + 1
  let max_day = Month::from_number(new_month)
    .unwrap()
    .num_days(new_year.to_int())
  let clamped_day = if day > max_day { max_day } else { day }
  NaiveDate::from_epoch_days64(
    days_from_civil64(new_year, new_month, clamped_day),
  )
}

///|
/// The date `months` months before this one (or after it, if `months` is
/// negative). See `add_months` for the day-of-month clamping rule.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_months` to get `None` instead.
pub fn NaiveDate::sub_months(self : NaiveDate, months : Int) -> NaiveDate {
  expect_in_range(self.checked_sub_months(months), "NaiveDate::sub_months")
}

///|
/// The date `years` years after this one (or before it, if `years` is
/// negative), keeping the month and clamping the day of month to the target
/// month's length when it doesn't exist there (February 29 becomes
/// February 28 in a non-leap year). Equivalent to `add_months(12 * years)`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_years` to get `None` instead.
pub fn NaiveDate::add_years(self : NaiveDate, years : Int) -> NaiveDate {
  expect_in_range(self.checked_add_years(years), "NaiveDate::add_years")
}

///|
/// The date `years` years before this one (or after it, if `years` is
/// negative). See `add_years` for the day-of-month clamping rule.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_years` to get `None` instead.
pub fn NaiveDate::sub_years(self : NaiveDate, years : Int) -> NaiveDate {
  expect_in_range(self.checked_sub_years(years), "NaiveDate::sub_years")
}

///|
/// The date `years` years after this one, or `None` if the result falls
/// outside `NaiveDate`'s representable range. See `add_years`.
pub fn NaiveDate::checked_add_years(
  self : NaiveDate,
  years : Int,
) -> NaiveDate? {
  self.checked_add_months64(years.to_int64() * 12L)
}

///|
/// The date `years` years before this one, or `None` if the result falls
/// outside `NaiveDate`'s representable range. See `add_years`.
pub fn NaiveDate::checked_sub_years(
  self : NaiveDate,
  years : Int,
) -> NaiveDate? {
  self.checked_add_months64(-years.to_int64() * 12L)
}

///|
/// The calendar week containing this date, with weeks starting on `start`.
pub fn NaiveDate::week(self : NaiveDate, start : Weekday) -> NaiveWeek {
  let start_days = start.num_days_from_monday()
  let ref_days = self.weekday().num_days_from_monday()
  let offset = start_days -
    ref_days -
    (if start_days > ref_days { 7 } else { 0 })
  NaiveWeek::{ first_day: self.add_days(offset), start, }
}

///|
/// The number of full calendar years elapsed from `base` to `self` (e.g.
/// someone born on `base` turns this many years old on `self`), or `None`
/// if `self` is before `base`. A year only counts once `self`'s month and
/// day have both reached (or passed) `base`'s.
pub fn NaiveDate::years_since(self : NaiveDate, base : NaiveDate) -> Int? {
  let mut years = self.year() - base.year()
  if self.month().number() < base.month().number() ||
    (self.month() == base.month() && self.day() < base.day()) {
    years -= 1
  }
  if years >= 0 {
    Some(years)
  } else {
    None
  }
}

///|
/// The `n`-th occurrence (1-indexed) of `weekday` within the given month,
/// e.g. `NaiveDate::from_weekday_of_month(2017, 3, Fri, 2)` is the 2nd
/// Friday of March 2017. `None` if `n` is not positive, `year`/`month` is
/// invalid, or that occurrence doesn't exist in the month (e.g. a 5th
/// Monday in a month that only has four).
pub fn NaiveDate::from_weekday_of_month(
  year : Int,
  month : Int,
  weekday : Weekday,
  n : Int,
) -> NaiveDate? {
  if n <= 0 {
    None
  } else {
    match NaiveDate::from_ymd(year, month, 1) {
      None => None
      Some(first) => {
        let first_to_dow = (
            7 +
            weekday.number_from_monday() -
            first.weekday().number_from_monday()
          ) %
          7
        let day = (n - 1) * 7 + first_to_dow + 1
        NaiveDate::from_ymd(year, month, day)
      }
    }
  }
}

///|
/// The calendar quarter, `1..=4`.
pub fn NaiveDate::quarter(self : NaiveDate) -> Int {
  (self.month().number() - 1) / 3 + 1
}

///|
/// A lazy, bounded, double-ended iterator over successive dates starting
/// from this one, stepping by one day, up to and including a conservative
/// practical upper bound (`+275760-09-13`, matching the well-known
/// ECMAScript `Date` representable range). See `NaiveDateDaysIterator`.
pub fn NaiveDate::iter_days(self : NaiveDate) -> NaiveDateDaysIterator {
  NaiveDateDaysIterator::{
    value: self,
    end: NaiveDate::{ days: ITER_BOUND_DAYS, },
  }
}

///|
/// A lazy, bounded, double-ended iterator over successive dates starting
/// from this one, stepping by one week, aligned so its upper bound is the
/// last date of the form `self + 7k` that doesn't exceed `iter_days`'s own
/// practical upper bound. See `NaiveDateWeeksIterator`.
pub fn NaiveDate::iter_weeks(self : NaiveDate) -> NaiveDateWeeksIterator {
  let weeks = floor_div(ITER_BOUND_DAYS - self.days, 7)
  NaiveDateWeeksIterator::{
    value: self,
    end: NaiveDate::{ days: self.days + weeks * 7, },
  }
}
