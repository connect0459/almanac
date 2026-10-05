///|
/// A schedule of whole-second instants described by a cron expression, read
/// by `Cron::parse` and evaluated in the wall clock of the zone of the value
/// it is asked about.
///
/// When both day-of-month and day-of-week are restricted, a day matches if
/// either does (`0 0 13 * 5` fires on every 13th and every Friday); when
/// either begins with `*` or is `?`, a day must match both.
///
/// A fire time inside a spring-forward gap does not exist and is skipped. A
/// fire time inside a fall-back fold fires once, at the earlier occurrence.
pub struct Cron {
  priv seconds : Int64
  priv minutes : Int64
  priv hours : Int64
  priv days : Int64
  priv months : Int64
  priv weekdays : Int64
  priv day_star : Bool
  priv weekday_star : Bool
} derive(Eq, Hash, @debug.Debug)

///|
pub extend Cron with Eq::{equal}

///|
pub extend Cron with Eq::{not_equal}

///|
pub extend Cron with Hash::{hash, hash_combine}

///|
pub extend Cron with @debug.Debug::{to_repr}

///|
fn Cron::day_matches(self : Cron, date : @core.NaiveDate) -> Bool {
  let in_month = has_bit(self.days, date.day())
  let in_week = has_bit(self.weekdays, date.weekday().num_days_from_sunday())
  if self.day_star || self.weekday_star {
    in_month && in_week
  } else {
    in_month || in_week
  }
}

///|
fn Cron::wall_clock_matches(self : Cron, reading : @core.NaiveDateTime) -> Bool {
  let time = reading.time()
  let date = reading.date()
  has_bit(self.seconds, time.second()) &&
  has_bit(self.minutes, time.minute()) &&
  has_bit(self.hours, time.hour()) &&
  has_bit(self.months, date.month().number()) &&
  self.day_matches(date)
}

///|
fn whole_second(reading : @core.NaiveDateTime) -> @core.NaiveDateTime {
  let (hour, minute, second) = reading.time().hms()
  @core.NaiveDateTime::new(
    reading.date(),
    @core.NaiveTime::from_hms(hour, minute, second).unwrap(),
  )
}

///|
/// Whether `dt` is an instant at which this schedule fires. A fractional
/// second is ignored, and within a fall-back fold only the earlier
/// occurrence of a wall-clock reading matches, as `next` would return it.
pub fn[Tz : @tz.TimeZone] Cron::matches(
  self : Cron,
  dt : @tz.DateTime[Tz],
) -> Bool {
  let reading = whole_second(dt.naive_local())
  if !self.wall_clock_matches(reading) {
    return false
  }
  @tz.DateTime::from_local(reading, dt.timezone())
  .earliest()
  .map(fire => fire.timestamp()) ==
  Some(dt.timestamp())
}

///|
fn Cron::first_time_from(
  self : Cron,
  start : (Int, Int, Int),
) -> @core.NaiveTime? {
  let (start_hour, start_minute, start_second) = start
  for hour in start_hour..<=23 {
    if !has_bit(self.hours, hour) {
      continue
    }
    let minute_from = if hour == start_hour { start_minute } else { 0 }
    for minute in minute_from..<=59 {
      if !has_bit(self.minutes, minute) {
        continue
      }
      let second_from = if hour == start_hour && minute == start_minute {
        start_second
      } else {
        0
      }
      for second in second_from..<=59 {
        if has_bit(self.seconds, second) {
          return @core.NaiveTime::from_hms(hour, minute, second)
        }
      }
    }
  }
  None
}

///|
fn first_of_next_month(date : @core.NaiveDate) -> @core.NaiveDate? {
  date.checked_add_days(date.num_days_in_month() - date.day() + 1)
}

///|
fn Cron::next_wall_clock(
  self : Cron,
  from : @core.NaiveDateTime,
  last_year : Int,
) -> @core.NaiveDateTime? {
  let mut date = from.date()
  let mut start = from.time().hms()
  while date.year() <= last_year {
    if !has_bit(self.months, date.month().number()) {
      match first_of_next_month(date) {
        Some(next_date) => date = next_date
        None => return None
      }
      start = (0, 0, 0)
      continue
    }
    if self.day_matches(date) {
      match self.first_time_from(start) {
        Some(time) => return Some(@core.NaiveDateTime::new(date, time))
        None => ()
      }
    }
    match date.checked_add_days(1) {
      Some(next_date) => date = next_date
      None => return None
    }
    start = (0, 0, 0)
  }
  None
}

///|
/// The first instant strictly after `dt` at which this schedule fires, in
/// the zone of `dt`, with a whole-second time. `None` if the expression
/// names no day within the 400 years after `dt` (`0 0 30 2 *`, a day that
/// never exists) or the search leaves the representable dates.
pub fn[Tz : @tz.TimeZone] Cron::next(
  self : Cron,
  dt : @tz.DateTime[Tz],
) -> @tz.DateTime[Tz]? {
  let start = whole_second(dt.naive_local())
  let last_year = start.date().year() + 400
  let mut from = start.checked_add_seconds(1L)
  while from is Some(current) {
    match self.next_wall_clock(current, last_year) {
      None => return None
      Some(candidate) => {
        match @tz.DateTime::from_local(candidate, dt.timezone()) {
          Single(fire) | Ambiguous(fire, _) =>
            if fire.timestamp() > dt.timestamp() {
              return Some(fire)
            }
          Absent => ()
        }
        from = candidate.checked_add_seconds(1L)
      }
    }
  }
  None
}
