///|
/// A datetime with an associated time zone.
///
/// Internally stores the UTC naive datetime plus the zone value `tz`; the
/// local (wall-clock) representation is derived on demand via
/// `tz.offset_from_utc`, never stored redundantly.
///
/// Identity is the UTC instant: `Eq`, `Hash` and `Compare` all ignore the
/// zone value, so the same instant expressed in different zones is equal,
/// hashes alike and compares as `0`.
pub struct DateTime[Tz] {
  priv datetime : @core.NaiveDateTime
  priv tz : Tz
} derive(@debug.Debug)

///|
pub impl[Tz] Eq for DateTime[Tz] with fn equal(self, other) {
  self.datetime == other.datetime
}

///|
pub extend DateTime with Eq::{equal, not_equal}

///|
pub impl[Tz] Hash for DateTime[Tz] with fn hash_combine(self, hasher) {
  self.datetime.hash_combine(hasher)
}

///|
pub extend DateTime with Hash::{hash, hash_combine}

///|
pub extend DateTime with @debug.Debug::{to_repr}

///|
/// Renders as the local date-time and the zone's name at this instant,
/// joined by a space, e.g. `2024-01-02 13:45:06.500 +09:00`, `... UTC` or
/// `... EDT`; see `NaiveDateTime`'s `Show` and `TimeZone::tz_name`.
pub impl[Tz : TimeZone] Show for DateTime[Tz] with fn output(self, logger) {
  logger.write_string(
    self.naive_local().to_string() + " " + self.tz.tz_name(self.datetime),
  )
}

///|
pub extend DateTime with Show::{to_string, output}

///|
/// Wraps a UTC naive datetime with the given time zone.
pub fn[Tz] DateTime::from_utc(
  datetime : @core.NaiveDateTime,
  tz : Tz,
) -> DateTime[Tz] {
  DateTime::{ datetime, tz, }
}

///|
pub extend DateTime with Compare::{compare, op_lt, op_gt, op_le, op_ge}

///|
/// Orders two datetimes by their UTC instant, ignoring the time zone value,
/// consistently with `Eq`.
pub impl[Tz] Compare for DateTime[Tz] with fn compare(self, other) {
  self.datetime.compare(other.datetime)
}

///|
/// Orders this datetime against one in a possibly different time zone type,
/// by UTC instant alone: `-1` if `self` is earlier, `0` if both are the same
/// instant, `1` if `self` is later.
pub fn[Tz, Tz2] DateTime::compare_instant(
  self : DateTime[Tz],
  other : DateTime[Tz2],
) -> Int {
  self.datetime.compare(other.datetime)
}

///|
/// Builds a `DateTime[Tz]` from a local (wall-clock) naive datetime and a
/// time zone, resolving DST ambiguity via `tz.offset_from_local`: `Single`
/// for an unambiguous reading, `Ambiguous(earliest, latest)` within a
/// fall-back fold, or `Absent` within a spring-forward gap.
pub fn[Tz : TimeZone] DateTime::from_local(
  naive_local : @core.NaiveDateTime,
  tz : Tz,
) -> MappedLocalTime[DateTime[Tz]] {
  tz
  .offset_from_local(naive_local)
  .map(offset => {
    DateTime::from_utc(
      naive_local.sub_seconds(offset.local_minus_utc().to_int64()),
      tz,
    )
  })
}

///|
/// The offset in effect just before the transition whose gap contains the
/// local reading `reading`, or `None` if no transition's gap contains it.
///
/// Walks the zone's transitions backward from the latest one that could
/// hold `reading` (a transition's instant is within a day and a bit of the
/// reading taken as UTC, since offsets stay within `±23:59:59`), stopping
/// once a transition's local times lie entirely at or before `reading`.
fn[Tz : TimeZone] offset_before_gap(
  tz : Tz,
  reading : @core.NaiveDateTime,
) -> FixedOffset? {
  for probe = reading.add_seconds(27 * 3600) {
    match tz.transition_bounds(probe).start() {
      None => break None
      Some(transition) => {
        let before = tz.offset_from_utc(transition.sub_seconds(1))
        let after = tz.offset_from_utc(transition)
        let gap_start = transition.add_seconds(
          before.local_minus_utc().to_int64(),
        )
        let gap_end = transition.add_seconds(after.local_minus_utc().to_int64())
        if reading >= gap_start && reading < gap_end {
          break Some(before)
        }
        if reading >= gap_start && reading >= gap_end {
          break None
        }
        continue transition.sub_seconds(1)
      }
    }
  }
}

///|
/// Builds a `DateTime[Tz]` from a local (wall-clock) naive datetime and a
/// time zone, always succeeding: unlike `from_local`, no reading is left
/// unresolved.
///
/// - An unambiguous reading resolves exactly as `from_local` does.
/// - A reading repeated by a fall-back fold takes its first occurrence (the
///   earlier UTC instant), as `MappedLocalTime::earliest` does.
/// - A reading skipped by a spring-forward gap is interpreted with the
///   offset in effect just before the transition, so the result lands
///   after the gap by the gap's length (e.g. `02:30` in a gap from `02:00`
///   to `03:00` becomes `03:30`).
///
/// A zone that reports a gap but exposes no transition bounds to find the
/// earlier offset from resolves the reading with its offset at that reading
/// taken as a UTC instant.
pub fn[Tz : TimeZone] DateTime::from_local_lenient(
  naive_local : @core.NaiveDateTime,
  tz : Tz,
) -> DateTime[Tz] {
  match DateTime::from_local(naive_local, tz).earliest() {
    Some(dt) => dt
    None => {
      let offset = match offset_before_gap(tz, naive_local) {
        Some(offset) => offset
        None => tz.offset_from_utc(naive_local)
      }
      DateTime::from_utc(
        naive_local.sub_seconds(offset.local_minus_utc().to_int64()),
        tz,
      )
    }
  }
}

///|
/// Builds a `DateTime[Tz]` from local calendar/time-of-day components and
/// a time zone (the proleptic Gregorian calendar, year 0 being 1 BCE).
/// `Absent` for an invalid date or time-of-day, in addition to the usual
/// DST-gap case — see `from_local`.
pub fn[Tz : TimeZone] DateTime::from_ymd_hms(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  min : Int,
  sec : Int,
  tz : Tz,
) -> MappedLocalTime[DateTime[Tz]] {
  match @core.NaiveDate::from_ymd(year, month, day) {
    None => Absent
    Some(date) =>
      match @core.NaiveTime::from_hms(hour, min, sec) {
        None => Absent
        Some(time) =>
          DateTime::from_local(@core.NaiveDateTime::new(date, time), tz)
      }
  }
}

///|
/// Builds a `DateTime[Tz]` from the number of non-leap seconds since the
/// Unix epoch plus a nanosecond component, and a time zone. Always
/// unambiguous (a UTC instant, unlike `from_local`): `None` only when
/// `secs`/`nanos` themselves are out of range — see
/// `@core.NaiveDateTime::from_timestamp`.
pub fn[Tz] DateTime::from_timestamp(
  secs : Int64,
  nanos : Int,
  tz : Tz,
) -> DateTime[Tz]? {
  @core.NaiveDateTime::from_timestamp(secs, nanos).map(utc => {
    DateTime::from_utc(utc, tz)
  })
}

///|
/// Builds a `DateTime[Tz]` from the number of non-leap milliseconds since the Unix
/// epoch and a time zone; see `from_timestamp`. `None` if the instant is
/// outside `NaiveDate`'s representable range.
pub fn[Tz] DateTime::from_timestamp_millis(
  millis : Int64,
  tz : Tz,
) -> DateTime[Tz]? {
  @core.NaiveDateTime::from_timestamp_millis(millis).map(utc => {
    DateTime::from_utc(utc, tz)
  })
}

///|
/// Builds a `DateTime[Tz]` from the number of non-leap microseconds since the Unix
/// epoch and a time zone; see `from_timestamp`. `None` if the instant is
/// outside `NaiveDate`'s representable range.
pub fn[Tz] DateTime::from_timestamp_micros(
  micros : Int64,
  tz : Tz,
) -> DateTime[Tz]? {
  @core.NaiveDateTime::from_timestamp_micros(micros).map(utc => {
    DateTime::from_utc(utc, tz)
  })
}

///|
/// Builds a `DateTime[Tz]` from the number of non-leap nanoseconds since the Unix
/// epoch and a time zone; see `from_timestamp`. `None` if the instant is
/// outside `NaiveDate`'s representable range.
pub fn[Tz] DateTime::from_timestamp_nanos(
  nanos : Int64,
  tz : Tz,
) -> DateTime[Tz]? {
  @core.NaiveDateTime::from_timestamp_nanos(nanos).map(utc => {
    DateTime::from_utc(utc, tz)
  })
}

///|
/// The underlying naive datetime, in UTC.
pub fn[Tz] DateTime::naive_utc(self : DateTime[Tz]) -> @core.NaiveDateTime {
  self.datetime
}

///|
/// The time zone this datetime is expressed in.
pub fn[Tz] DateTime::timezone(self : DateTime[Tz]) -> Tz {
  self.tz
}

///|
/// The UTC offset in effect at this instant.
pub fn[Tz : TimeZone] DateTime::offset(self : DateTime[Tz]) -> FixedOffset {
  self.tz.offset_from_utc(self.datetime)
}

///|
/// The name of the zone in effect at this instant: an IANA zone's
/// abbreviation (e.g. `"EDT"`), a `FixedZone`'s name, `"UTC"`, or a bare
/// `FixedOffset`'s offset text. The same text as `%Z` and the end of `Show`.
pub fn[Tz : TimeZone] DateTime::zone_name(self : DateTime[Tz]) -> String {
  self.tz.tz_name(self.datetime)
}

///|
/// The name (see `zone_name`) and UTC offset in effect at this instant.
pub fn[Tz : TimeZone] DateTime::zone(
  self : DateTime[Tz],
) -> (String, FixedOffset) {
  (self.zone_name(), self.offset())
}

///|
/// The Unix epoch instant, `1970-01-01T00:00:00Z`: timestamp zero, in UTC.
/// `Default::default()` returns it.
pub fn DateTime::unix_epoch() -> DateTime[Utc] {
  DateTime::{ datetime: @core.NaiveDateTime::unix_epoch(), tz: Utc::new(), }
}

///|
/// The Unix epoch instant; see `unix_epoch`. Only UTC has a natural default
/// zone, so `Default` is not provided for other zones.
pub impl Default for DateTime[Utc] with fn default() {
  DateTime::unix_epoch()
}

///|
pub extend DateTime with Default::{default}

///|
/// The naive local (wall-clock) datetime, i.e. the UTC datetime shifted by
/// `offset()`. Always succeeds: an offset is at most `±23:59:59`, far
/// within `TimeDelta`'s representable range.
pub fn[Tz : TimeZone] DateTime::naive_local(
  self : DateTime[Tz],
) -> @core.NaiveDateTime {
  self.datetime.add_seconds(self.offset().local_minus_utc().to_int64())
}

///|
/// The local calendar date.
pub fn[Tz : TimeZone] DateTime::date(self : DateTime[Tz]) -> @core.NaiveDate {
  self.naive_local().date()
}

///|
/// The local time of day.
pub fn[Tz : TimeZone] DateTime::time(self : DateTime[Tz]) -> @core.NaiveTime {
  self.naive_local().time()
}

///|
/// The local calendar year (proleptic Gregorian, year 0 being 1 BCE).
pub fn[Tz : TimeZone] DateTime::year(self : DateTime[Tz]) -> Int {
  self.naive_local().year()
}

///|
/// The local month.
pub fn[Tz : TimeZone] DateTime::month(self : DateTime[Tz]) -> @core.Month {
  self.naive_local().month()
}

///|
/// The local day of the month, `1..=31`.
pub fn[Tz : TimeZone] DateTime::day(self : DateTime[Tz]) -> Int {
  self.naive_local().day()
}

///|
/// The local day of the year, `1..=366`.
pub fn[Tz : TimeZone] DateTime::ordinal(self : DateTime[Tz]) -> Int {
  self.naive_local().ordinal()
}

///|
/// The local day of the week.
pub fn[Tz : TimeZone] DateTime::weekday(self : DateTime[Tz]) -> @core.Weekday {
  self.naive_local().weekday()
}

///|
/// The local ISO 8601 week.
pub fn[Tz : TimeZone] DateTime::iso_week(self : DateTime[Tz]) -> @core.IsoWeek {
  self.naive_local().iso_week()
}

///|
/// The local hour, `0..=23`.
pub fn[Tz : TimeZone] DateTime::hour(self : DateTime[Tz]) -> Int {
  self.naive_local().hour()
}

///|
/// The local minute, `0..=59`.
pub fn[Tz : TimeZone] DateTime::minute(self : DateTime[Tz]) -> Int {
  self.naive_local().minute()
}

///|
/// The local second, `0..=59`; a leap second reports `59` with `nanosecond()` at or above `1_000_000_000`.
pub fn[Tz : TimeZone] DateTime::second(self : DateTime[Tz]) -> Int {
  self.naive_local().second()
}

///|
/// The local nanosecond within the second, `0..=1_999_999_999`.
pub fn[Tz : TimeZone] DateTime::nanosecond(self : DateTime[Tz]) -> Int {
  self.naive_local().nanosecond()
}

///|
/// This datetime with the local calendar year replaced, keeping the rest of the local
/// wall-clock reading and re-resolving it through the time zone: `Absent`
/// for a value that does not form a valid local reading (see
/// `@core.NaiveDateTime::with_year`) or a reading inside a DST gap, and
/// `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_year(
  self : DateTime[Tz],
  year : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_year(year) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// This datetime with the local month (`1..=12`) replaced, keeping the rest of the local
/// wall-clock reading and re-resolving it through the time zone: `Absent`
/// for a value that does not form a valid local reading (see
/// `@core.NaiveDateTime::with_month`) or a reading inside a DST gap, and
/// `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_month(
  self : DateTime[Tz],
  month : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_month(month) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// This datetime with the local day of the month replaced, keeping the rest of the local
/// wall-clock reading and re-resolving it through the time zone: `Absent`
/// for a value that does not form a valid local reading (see
/// `@core.NaiveDateTime::with_day`) or a reading inside a DST gap, and
/// `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_day(
  self : DateTime[Tz],
  day : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_day(day) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// This datetime with the local day of the year replaced, keeping the rest of the local
/// wall-clock reading and re-resolving it through the time zone: `Absent`
/// for a value that does not form a valid local reading (see
/// `@core.NaiveDateTime::with_ordinal`) or a reading inside a DST gap, and
/// `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_ordinal(
  self : DateTime[Tz],
  ordinal : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_ordinal(ordinal) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// This datetime with the local hour replaced, keeping the rest of the local
/// wall-clock reading and re-resolving it through the time zone: `Absent`
/// for a value that does not form a valid local reading (see
/// `@core.NaiveDateTime::with_hour`) or a reading inside a DST gap, and
/// `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_hour(
  self : DateTime[Tz],
  hour : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_hour(hour) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// This datetime with the local minute replaced, keeping the rest of the local
/// wall-clock reading and re-resolving it through the time zone: `Absent`
/// for a value that does not form a valid local reading (see
/// `@core.NaiveDateTime::with_minute`) or a reading inside a DST gap, and
/// `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_minute(
  self : DateTime[Tz],
  minute : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_minute(minute) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// This datetime with the local second replaced, keeping the rest of the local
/// wall-clock reading and re-resolving it through the time zone: `Absent`
/// for a value that does not form a valid local reading (see
/// `@core.NaiveDateTime::with_second`) or a reading inside a DST gap, and
/// `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_second(
  self : DateTime[Tz],
  second : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_second(second) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// This datetime with the local nanosecond replaced, keeping the rest of the local
/// wall-clock reading and re-resolving it through the time zone: `Absent`
/// for a value that does not form a valid local reading (see
/// `@core.NaiveDateTime::with_nanosecond`) or a reading inside a DST gap, and
/// `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_nanosecond(
  self : DateTime[Tz],
  nanosecond : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_nanosecond(nanosecond) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// The local month, counting from `0`.
pub fn[Tz : TimeZone] DateTime::month0(self : DateTime[Tz]) -> Int {
  self.naive_local().month0()
}

///|
/// The local day of the month, counting from `0`.
pub fn[Tz : TimeZone] DateTime::day0(self : DateTime[Tz]) -> Int {
  self.naive_local().day0()
}

///|
/// The local day of the year, counting from `0`.
pub fn[Tz : TimeZone] DateTime::ordinal0(self : DateTime[Tz]) -> Int {
  self.naive_local().ordinal0()
}

///|
/// The local quarter of the year, `1..=4`.
pub fn[Tz : TimeZone] DateTime::quarter(self : DateTime[Tz]) -> Int {
  self.naive_local().quarter()
}

///|
/// The local year as a Common Era flag and a positive year number. See `@core.NaiveDate::year_ce`.
pub fn[Tz : TimeZone] DateTime::year_ce(self : DateTime[Tz]) -> (Bool, Int) {
  self.naive_local().year_ce()
}

///|
/// The number of days from the start of the Common Era to the local date, counting `0001-01-01` as day `1`.
pub fn[Tz : TimeZone] DateTime::num_days_from_ce(self : DateTime[Tz]) -> Int {
  self.naive_local().num_days_from_ce()
}

///|
/// The number of days in the local month.
pub fn[Tz : TimeZone] DateTime::num_days_in_month(self : DateTime[Tz]) -> Int {
  self.naive_local().num_days_in_month()
}

///|
/// The local hour on a 12-hour clock as a PM flag and an hour in `1..=12`.
pub fn[Tz : TimeZone] DateTime::hour12(self : DateTime[Tz]) -> (Bool, Int) {
  self.naive_local().hour12()
}

///|
/// The number of seconds since local midnight.
pub fn[Tz : TimeZone] DateTime::num_seconds_from_midnight(
  self : DateTime[Tz],
) -> Int {
  self.naive_local().num_seconds_from_midnight()
}

///|
/// Like `with_month`, but taking the local month counting from `0`.
pub fn[Tz : TimeZone] DateTime::with_month0(
  self : DateTime[Tz],
  month0 : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_month0(month0) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// Like `with_day`, but taking the local day of the month counting from `0`.
pub fn[Tz : TimeZone] DateTime::with_day0(
  self : DateTime[Tz],
  day0 : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_day0(day0) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// Like `with_ordinal`, but taking the local day of the year counting from `0`.
pub fn[Tz : TimeZone] DateTime::with_ordinal0(
  self : DateTime[Tz],
  ordinal0 : Int,
) -> MappedLocalTime[DateTime[Tz]] {
  match self.naive_local().with_ordinal0(ordinal0) {
    None => Absent
    Some(naive) => DateTime::from_local(naive, self.tz)
  }
}

///|
/// The number of non-leap seconds since the Unix epoch, flooring toward negative infinity. Independent of the time zone.
pub fn[Tz] DateTime::timestamp(self : DateTime[Tz]) -> Int64 {
  self.datetime.timestamp()
}

///|
/// The number of non-leap milliseconds since the Unix epoch. Independent of the time zone.
pub fn[Tz] DateTime::timestamp_millis(self : DateTime[Tz]) -> Int64 {
  self.datetime.timestamp_millis()
}

///|
/// The number of non-leap microseconds since the Unix epoch; `None` if it overflows `Int64`. Independent of the time zone.
pub fn[Tz] DateTime::timestamp_micros(self : DateTime[Tz]) -> Int64? {
  self.datetime.timestamp_micros()
}

///|
/// The number of non-leap nanoseconds since the Unix epoch; `None` if it overflows `Int64`. Independent of the time zone.
pub fn[Tz] DateTime::timestamp_nanos(self : DateTime[Tz]) -> Int64? {
  self.datetime.timestamp_nanos()
}

///|
/// The nanosecond component of the instant within its second. Independent of the time zone.
pub fn[Tz] DateTime::timestamp_subsec_nanos(self : DateTime[Tz]) -> Int {
  self.datetime.timestamp_subsec_nanos()
}

///|
/// The millisecond component of the instant within its second. Independent of the time zone.
pub fn[Tz] DateTime::timestamp_subsec_millis(self : DateTime[Tz]) -> Int {
  self.datetime.timestamp_subsec_millis()
}

///|
/// The microsecond component of the instant within its second. Independent of the time zone.
pub fn[Tz] DateTime::timestamp_subsec_micros(self : DateTime[Tz]) -> Int {
  self.datetime.timestamp_subsec_micros()
}

///|
/// This datetime with its local time of day replaced by `time`, keeping the
/// local date and re-resolving the wall-clock reading through the time zone:
/// `Absent` inside a DST gap, `Ambiguous` inside a DST fold.
pub fn[Tz : TimeZone] DateTime::with_time(
  self : DateTime[Tz],
  time : @core.NaiveTime,
) -> MappedLocalTime[DateTime[Tz]] {
  DateTime::from_local(@core.NaiveDateTime::new(self.date(), time), self.tz)
}

///|
/// The number of full calendar years elapsed from `base` to this datetime,
/// or `None` if `base` is later. `base` may be in a different time zone;
/// both are read as local dates in this datetime's time zone, ignoring the
/// time of day. See `@core.NaiveDate::years_since`.
pub fn[Tz : TimeZone, Tz2] DateTime::years_since(
  self : DateTime[Tz],
  base : DateTime[Tz2],
) -> Int? {
  self.date().years_since(base.with_timezone(self.tz).date())
}

///|
/// This datetime re-expressed in `tz`, keeping the same underlying UTC
/// instant.
pub fn[Tz, Tz2] DateTime::with_timezone(
  self : DateTime[Tz],
  tz : Tz2,
) -> DateTime[Tz2] {
  DateTime::{ datetime: self.datetime, tz, }
}

///|
/// Whether daylight saving time is in effect at this instant, according to
/// the time zone.
pub fn[Tz : TimeZone] DateTime::is_dst(self : DateTime[Tz]) -> Bool {
  self.tz.is_dst(self.datetime)
}

///|
/// The validity window of the offset in effect at this instant: from the
/// transition that began it until the next one, either side `None` when
/// unbounded. See `TransitionBounds`.
pub fn[Tz : TimeZone] DateTime::zone_bounds(
  self : DateTime[Tz],
) -> TransitionBounds {
  self.tz.transition_bounds(self.datetime)
}

///|
/// This datetime re-expressed in UTC, keeping the same underlying instant.
pub fn[Tz] DateTime::to_utc(self : DateTime[Tz]) -> DateTime[Utc] {
  self.with_timezone(Utc::new())
}

///|
/// This datetime re-expressed with a fixed offset equal to the one in effect
/// at its instant, keeping the same underlying instant. The result no longer
/// follows the original zone's later offset changes (e.g. DST transitions).
pub fn[Tz : TimeZone] DateTime::fixed_offset(
  self : DateTime[Tz],
) -> DateTime[FixedOffset] {
  self.with_timezone(self.offset())
}

///|
/// This datetime advanced by the signed duration `delta`, keeping the same
/// time zone. Delegates to `NaiveDateTime::add_signed` on the underlying
/// UTC instant.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_signed` to get `None` instead.
pub fn[Tz] DateTime::add_signed(
  self : DateTime[Tz],
  delta : @core.TimeDelta,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.add_signed(delta), tz: self.tz, }
}

///|
/// This datetime moved back by the signed duration `delta`. See
/// `add_signed`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_signed` to get `None` instead.
pub fn[Tz] DateTime::sub_signed(
  self : DateTime[Tz],
  delta : @core.TimeDelta,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.sub_signed(delta), tz: self.tz, }
}

///|
/// This datetime with its date advanced by `months` (or moved back, if
/// `months` is negative), keeping the time of day and time zone unchanged.
/// See `@core.NaiveDateTime::add_months` for the day-of-month clamping
/// rule.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_months` to get `None` instead.
pub fn[Tz] DateTime::add_months(
  self : DateTime[Tz],
  months : Int,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.add_months(months), tz: self.tz, }
}

///|
/// This datetime with its date moved back by `months`. See `add_months`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_months` to get `None` instead.
pub fn[Tz] DateTime::sub_months(
  self : DateTime[Tz],
  months : Int,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.sub_months(months), tz: self.tz, }
}

///|
/// This datetime with its date advanced by `years` (or moved back, if
/// `years` is negative), keeping the time of day and time zone unchanged.
/// See `@core.NaiveDate::add_years` for the day-of-month clamping rule.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_years` to get `None` instead.
pub fn[Tz] DateTime::add_years(
  self : DateTime[Tz],
  years : Int,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.add_years(years), tz: self.tz, }
}

///|
/// This datetime with its date moved back by `years`. See `add_years`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_years` to get `None` instead.
pub fn[Tz] DateTime::sub_years(
  self : DateTime[Tz],
  years : Int,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.sub_years(years), tz: self.tz, }
}

///|
/// This datetime with its date advanced by `days` (or moved back, if
/// `days` is negative), keeping the time of day and time zone unchanged.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_days` to get `None` instead.
pub fn[Tz] DateTime::add_days(self : DateTime[Tz], days : Int) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.add_days(days), tz: self.tz, }
}

///|
/// This datetime with its date moved back by `days`. See `add_days`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_days` to get `None` instead.
pub fn[Tz] DateTime::sub_days(self : DateTime[Tz], days : Int) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.sub_days(days), tz: self.tz, }
}

///|
/// Like `add_signed`, but `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn[Tz] DateTime::checked_add_signed(
  self : DateTime[Tz],
  delta : @core.TimeDelta,
) -> DateTime[Tz]? {
  self.datetime
  .checked_add_signed(delta)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// Like `sub_signed`, but `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn[Tz] DateTime::checked_sub_signed(
  self : DateTime[Tz],
  delta : @core.TimeDelta,
) -> DateTime[Tz]? {
  self.datetime
  .checked_sub_signed(delta)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// Like `add_months`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn[Tz] DateTime::checked_add_months(
  self : DateTime[Tz],
  months : Int,
) -> DateTime[Tz]? {
  self.datetime
  .checked_add_months(months)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// Like `sub_months`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn[Tz] DateTime::checked_sub_months(
  self : DateTime[Tz],
  months : Int,
) -> DateTime[Tz]? {
  self.datetime
  .checked_sub_months(months)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// Like `add_years`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn[Tz] DateTime::checked_add_years(
  self : DateTime[Tz],
  years : Int,
) -> DateTime[Tz]? {
  self.datetime
  .checked_add_years(years)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// Like `sub_years`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn[Tz] DateTime::checked_sub_years(
  self : DateTime[Tz],
  years : Int,
) -> DateTime[Tz]? {
  self.datetime
  .checked_sub_years(years)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// Like `add_days`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn[Tz] DateTime::checked_add_days(
  self : DateTime[Tz],
  days : Int,
) -> DateTime[Tz]? {
  self.datetime
  .checked_add_days(days)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// Like `sub_days`, but `None` if the resulting date falls outside
/// `NaiveDate`'s representable range.
pub fn[Tz] DateTime::checked_sub_days(
  self : DateTime[Tz],
  days : Int,
) -> DateTime[Tz]? {
  self.datetime
  .checked_sub_days(days)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// The signed duration from `other` to `self` (positive if `self` is
/// later), independent of either datetime's time zone (both are compared
/// via their underlying UTC instant).
pub fn[Tz, Tz2] DateTime::signed_duration_since(
  self : DateTime[Tz],
  other : DateTime[Tz2],
) -> @core.TimeDelta {
  self.datetime.signed_duration_since(other.datetime)
}

///|
/// This datetime's instant moved forward by `offset`'s seconds (backward for
/// a west offset), keeping the same time zone. Delegates to
/// `@core.NaiveDateTime::add_seconds` on the underlying UTC datetime.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_add_offset` to get `None` instead.
pub fn[Tz] DateTime::add_offset(
  self : DateTime[Tz],
  offset : FixedOffset,
) -> DateTime[Tz] {
  DateTime::{
    datetime: self.datetime.add_seconds(offset.local_minus_utc().to_int64()),
    tz: self.tz,
  }
}

///|
/// This datetime's instant moved backward by `offset`'s seconds (forward for
/// a west offset), keeping the same time zone. See `add_offset`.
///
/// Aborts if the result falls outside `NaiveDate`'s representable range; use
/// `checked_sub_offset` to get `None` instead.
pub fn[Tz] DateTime::sub_offset(
  self : DateTime[Tz],
  offset : FixedOffset,
) -> DateTime[Tz] {
  DateTime::{
    datetime: self.datetime.sub_seconds(offset.local_minus_utc().to_int64()),
    tz: self.tz,
  }
}

///|
/// Like `add_offset`, but `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn[Tz] DateTime::checked_add_offset(
  self : DateTime[Tz],
  offset : FixedOffset,
) -> DateTime[Tz]? {
  self.datetime
  .checked_add_seconds(offset.local_minus_utc().to_int64())
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// Like `sub_offset`, but `None` if the result falls outside `NaiveDate`'s
/// representable range.
pub fn[Tz] DateTime::checked_sub_offset(
  self : DateTime[Tz],
  offset : FixedOffset,
) -> DateTime[Tz]? {
  self.datetime
  .checked_sub_seconds(offset.local_minus_utc().to_int64())
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// This datetime's underlying UTC instant truncated toward the Unix epoch
/// to the nearest multiple of `granularity`, keeping the same time zone.
/// Operates on the absolute UTC instant, not the offset-shifted local
/// presentation: truncating to an hour granularity may still report a
/// non-zero local minute, depending on the time zone's offset. See
/// `@core.NaiveDateTime::truncate` for the conditions under which
/// `granularity` is rejected.
pub fn[Tz] DateTime::truncate(
  self : DateTime[Tz],
  granularity : @core.TimeDelta,
) -> Result[DateTime[Tz], @core.RoundingError] {
  self.datetime
  .truncate(granularity)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// This datetime's underlying UTC instant rounded to the nearest multiple
/// of `granularity` since the Unix epoch, ties breaking away from the
/// epoch, keeping the same time zone. See `truncate` for how this operates
/// on the absolute UTC instant rather than the local presentation.
pub fn[Tz] DateTime::round(
  self : DateTime[Tz],
  granularity : @core.TimeDelta,
) -> Result[DateTime[Tz], @core.RoundingError] {
  self.datetime
  .round(granularity)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// This datetime's underlying UTC instant rounded up (toward positive
/// infinity) to the nearest multiple of `granularity` since the Unix epoch:
/// unchanged if already a multiple, otherwise the next one after it, keeping
/// the same time zone. See `@core.NaiveDateTime::round_up` for the failure
/// reasons and `truncate` for how this operates on the absolute UTC instant
/// rather than the local presentation.
pub fn[Tz] DateTime::round_up(
  self : DateTime[Tz],
  granularity : @core.TimeDelta,
) -> Result[DateTime[Tz], @core.RoundingError] {
  self.datetime
  .round_up(granularity)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}

///|
/// This datetime's underlying UTC instant truncated to `digits`
/// fractional-second digits (`0..=9`), keeping the same time zone. See
/// `@core.NaiveDateTime::truncate_subsecs`; aborts if `digits` is outside
/// `0..=9`.
pub fn[Tz] DateTime::truncate_subsecs(
  self : DateTime[Tz],
  digits : Int,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.truncate_subsecs(digits), tz: self.tz, }
}

///|
/// This datetime's underlying UTC instant rounded to `digits`
/// fractional-second digits (`0..=9`), keeping the same time zone. See
/// `@core.NaiveDateTime::round_subsecs`; aborts if `digits` is outside
/// `0..=9`.
pub fn[Tz] DateTime::round_subsecs(
  self : DateTime[Tz],
  digits : Int,
) -> Result[DateTime[Tz], @core.RoundingError] {
  self.datetime
  .round_subsecs(digits)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}
