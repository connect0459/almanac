///|
/// A date rule from a POSIX TZ string's DST transition rule, in one of the
/// three POSIX date formats.
priv enum RuleDate {
  /// `Jn`: the `n`-th day of the year, `1..=365`. February 29 is never
  /// counted, even in a leap year.
  JulianNoLeap(Int)
  /// `n`: the `n`-th day of the year, `0..=365`, 0-based. February 29 is
  /// counted in a leap year.
  JulianWithLeap(Int)
  /// `Mm.w.d`: the `w`-th occurrence of weekday `d` (`0` = Sunday) in
  /// month `m` (`w = 5` means "the last occurrence").
  MonthWeekDay(Int, Int, Int)
} derive(Eq, Hash, @debug.Debug)

///|
/// A POSIX TZ string's DST transition rule: when daylight saving starts
/// and ends, and at what local time of day.
priv struct DstRule {
  start : RuleDate
  /// Seconds after local midnight of `start`'s date, in standard time
  /// (the time in effect immediately before this transition).
  start_time : Int
  end : RuleDate
  /// Seconds after local midnight of `end`'s date, in daylight time (the
  /// time in effect immediately before this transition).
  end_time : Int
} derive(Eq, Hash, @debug.Debug)

///|
/// A parsed POSIX TZ string (the format used in a TZif footer and the
/// `TZ` environment variable), used to extrapolate offsets for instants
/// past a TZif file's last recorded transition.
pub struct PosixTz {
  priv std_offset : Int
  priv std_name : String
  priv dst_offset : Int?
  priv dst_name : String?
  priv rule : DstRule?
} derive(Eq, Hash, @debug.Debug)

///|
pub extend PosixTz with Eq::{equal}

///|
pub extend PosixTz with Eq::{not_equal}

///|
pub extend PosixTz with Hash::{hash, hash_combine}

///|
pub extend PosixTz with @debug.Debug::{to_repr}

///|
fn is_ascii_alpha(c : Char) -> Bool {
  (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')
}

///|
fn is_ascii_digit(c : Char) -> Bool {
  c >= '0' && c <= '9'
}

///|
fn parse_name(chars : Array[Char], pos : Int) -> (String, Int)? {
  if pos < chars.length() && chars[pos] == '<' {
    for i = pos + 1 {
      if i >= chars.length() {
        break None
      }
      if chars[i] == '>' {
        break Some((String::from_array(chars[pos + 1:i]), i + 1))
      }
      continue i + 1
    }
  } else {
    for i = pos {
      if i < chars.length() && is_ascii_alpha(chars[i]) {
        continue i + 1
      } else if i - pos >= 3 {
        break Some((String::from_array(chars[pos:i]), i))
      } else {
        break None
      }
    }
  }
}

///|
fn digits_to_int(chars : Array[Char], start : Int, end : Int) -> Int {
  for i = start, acc = 0 {
    if i >= end {
      break acc
    }
    continue i + 1, acc * 10 + (chars[i].to_int() - '0'.to_int())
  }
}

///|
fn parse_uint(chars : Array[Char], pos : Int) -> (Int, Int)? {
  for i = pos {
    if i < chars.length() && is_ascii_digit(chars[i]) {
      continue i + 1
    } else if i > pos {
      break Some((digits_to_int(chars, pos, i), i))
    } else {
      break None
    }
  }
}

///|
/// Parses a POSIX offset/time field: `[+-]hh[:mm[:ss]]`, seconds.
fn parse_offset_seconds(chars : Array[Char], pos : Int) -> (Int, Int)? {
  let (sign, p) = if pos < chars.length() && chars[pos] == '-' {
    (-1, pos + 1)
  } else if pos < chars.length() && chars[pos] == '+' {
    (1, pos + 1)
  } else {
    (1, pos)
  }
  match parse_uint(chars, p) {
    None => None
    Some((hh, p1)) => {
      let (mm, p2) = if p1 < chars.length() && chars[p1] == ':' {
        match parse_uint(chars, p1 + 1) {
          None => (0, p1)
          Some(pair) => pair
        }
      } else {
        (0, p1)
      }
      let (ss, p3) = if p2 < chars.length() && chars[p2] == ':' {
        match parse_uint(chars, p2 + 1) {
          None => (0, p2)
          Some(pair) => pair
        }
      } else {
        (0, p2)
      }
      Some((sign * (hh * 3600 + mm * 60 + ss), p3))
    }
  }
}

///|
fn parse_rule_date(chars : Array[Char], pos : Int) -> (RuleDate, Int)? {
  if pos >= chars.length() {
    None
  } else if chars[pos] == 'J' {
    match parse_uint(chars, pos + 1) {
      None => None
      Some((n, p)) => Some((JulianNoLeap(n), p))
    }
  } else if chars[pos] == 'M' {
    match parse_uint(chars, pos + 1) {
      None => None
      Some((m, p1)) =>
        if p1 < chars.length() && chars[p1] == '.' {
          match parse_uint(chars, p1 + 1) {
            None => None
            Some((w, p2)) =>
              if p2 < chars.length() && chars[p2] == '.' {
                match parse_uint(chars, p2 + 1) {
                  None => None
                  Some((d, p3)) => Some((MonthWeekDay(m, w, d), p3))
                }
              } else {
                None
              }
          }
        } else {
          None
        }
    }
  } else {
    match parse_uint(chars, pos) {
      None => None
      Some((n, p)) => Some((JulianWithLeap(n), p))
    }
  }
}

///|
/// The default transition time of day, `02:00:00`, used when a rule omits
/// an explicit `/time`.
const DEFAULT_RULE_TIME : Int = 7200

///|
fn parse_rule(chars : Array[Char], pos : Int) -> (DstRule, Int)? {
  match parse_rule_date(chars, pos) {
    None => None
    Some((start, p1)) => {
      let (start_time, p2) = if p1 < chars.length() && chars[p1] == '/' {
        match parse_offset_seconds(chars, p1 + 1) {
          None => (DEFAULT_RULE_TIME, p1)
          Some(pair) => pair
        }
      } else {
        (DEFAULT_RULE_TIME, p1)
      }
      if p2 >= chars.length() || chars[p2] != ',' {
        None
      } else {
        match parse_rule_date(chars, p2 + 1) {
          None => None
          Some((end, p3)) => {
            let (end_time, p4) = if p3 < chars.length() && chars[p3] == '/' {
              match parse_offset_seconds(chars, p3 + 1) {
                None => (DEFAULT_RULE_TIME, p3)
                Some(pair) => pair
              }
            } else {
              (DEFAULT_RULE_TIME, p3)
            }
            Some((DstRule::{ start, start_time, end, end_time, }, p4))
          }
        }
      }
    }
  }
}

///|
/// Parses a POSIX TZ string (e.g. `"EST5EDT,M3.2.0,M11.1.0"`, `"UTC0"`),
/// or `None` if it is malformed.
pub fn parse_posix_tz(s : String) -> PosixTz? {
  let chars = s.to_array()
  match parse_name(chars, 0) {
    None => None
    Some((std_name, p1)) =>
      match parse_offset_seconds(chars, p1) {
        None => None
        Some((std_posix_offset, p2)) => {
          let std_offset = -std_posix_offset
          if p2 >= chars.length() {
            Some(PosixTz::{
              std_offset,
              std_name,
              dst_offset: None,
              dst_name: None,
              rule: None,
            })
          } else {
            match parse_name(chars, p2) {
              None => None
              Some((dst_name, p3)) => {
                let (dst_posix_offset, p4) = match
                  parse_offset_seconds(chars, p3) {
                  None => (std_posix_offset - 3600, p3)
                  Some(pair) => pair
                }
                let dst_offset = -dst_posix_offset
                if p4 >= chars.length() || chars[p4] != ',' {
                  None
                } else {
                  match parse_rule(chars, p4 + 1) {
                    None => None
                    Some((rule, p5)) =>
                      if p5 == chars.length() {
                        Some(PosixTz::{
                          std_offset,
                          std_name,
                          dst_offset: Some(dst_offset),
                          dst_name: Some(dst_name),
                          rule: Some(rule),
                        })
                      } else {
                        None
                      }
                  }
                }
              }
            }
          }
        }
      }
  }
}

///|
/// The date the given rule falls on in `year`.
fn date_for_rule(date : RuleDate, year : Int) -> @core.NaiveDate {
  match date {
    JulianNoLeap(n) => {
      let ordinal = if @core.is_leap_year(year) && n > 59 { n + 1 } else { n }
      @core.NaiveDate::from_yo(year, ordinal).unwrap()
    }
    JulianWithLeap(n) => @core.NaiveDate::from_yo(year, n + 1).unwrap()
    MonthWeekDay(m, w, d) => {
      let first = @core.NaiveDate::from_ymd(year, m, 1).unwrap()
      let first_dow = first.weekday().num_days_from_sunday()
      let delta = (d - first_dow + 7) % 7
      let first_occurrence = first.add_days(delta)
      if w >= 5 {
        let candidate = first_occurrence.add_days(28)
        if candidate.month() == first.month() {
          candidate
        } else {
          candidate.add_days(-7)
        }
      } else {
        first_occurrence.add_days((w - 1) * 7)
      }
    }
  }
}

///|
/// The Unix instant for `date` at local midnight, plus `time_seconds`
/// (which may be negative or exceed a day, per POSIX's permissive time
/// field).
fn local_clock_value(date : @core.NaiveDate, time_seconds : Int) -> Int64 {
  let midnight = @core.NaiveDateTime::new(
    date,
    @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
  )
  midnight.timestamp() + time_seconds.to_int64()
}

///|
/// The UTC instants, in `year`, at which daylight saving starts and ends
/// under `rule`.
fn compute_transitions(
  rule : DstRule,
  std_offset : Int,
  dst_offset : Int,
  year : Int,
) -> (Int64, Int64) {
  let start_date = date_for_rule(rule.start, year)
  let end_date = date_for_rule(rule.end, year)
  let start_local = local_clock_value(start_date, rule.start_time)
  let end_local = local_clock_value(end_date, rule.end_time)
  (start_local - std_offset.to_int64(), end_local - dst_offset.to_int64())
}

///|
/// Whether daylight saving is in effect for the given UTC instant.
///
/// Unwrapping `dst_offset` is safe: `parse_posix_tz` only ever produces a
/// `PosixTz` with `rule` present exactly when `dst_offset` is present.
fn PosixTz::is_dst_at(self : PosixTz, utc_instant : Int64) -> Bool {
  match self.rule {
    None => false
    Some(rule) => {
      let dst_offset = self.dst_offset.unwrap()
      let year = @core.NaiveDateTime::from_timestamp(utc_instant, 0)
        .unwrap()
        .date()
        .year()
      let (start_utc, end_utc) = compute_transitions(
        rule,
        self.std_offset,
        dst_offset,
        year,
      )
      if start_utc < end_utc {
        utc_instant >= start_utc && utc_instant < end_utc
      } else {
        utc_instant >= start_utc || utc_instant < end_utc
      }
    }
  }
}

///|
/// The exact validity window `(start, end)` of the DST/standard-time
/// interval containing `utc_instant`, or `None` if this rule has no DST
/// component at all (`self.rule` is `None`: every instant then belongs to
/// the same unbounded interval, which this type alone cannot bound — the
/// caller knows where that interval actually began, e.g. a TZif file's
/// last recorded transition).
///
/// Recomputed exactly by bracketing `utc_instant` against the DST
/// start/end instants of the surrounding three calendar years (ample
/// margin regardless of hemisphere: a wraparound rule's two same-year
/// instants are not chronologically adjacent), rather than approximated
/// near a year boundary the way Go's own `tzset` documents itself as
/// doing.
pub fn PosixTz::bounds_at(
  self : PosixTz,
  utc_instant : Int64,
) -> (Int64, Int64)? {
  match self.rule {
    None => None
    Some(rule) => {
      let dst_offset = self.dst_offset.unwrap()
      let year = @core.NaiveDateTime::from_timestamp(utc_instant, 0)
        .unwrap()
        .date()
        .year()
      let (a0, b0) = compute_transitions(
        rule,
        self.std_offset,
        dst_offset,
        year - 1,
      )
      let (a1, b1) = compute_transitions(
        rule,
        self.std_offset,
        dst_offset,
        year,
      )
      let (a2, b2) = compute_transitions(
        rule,
        self.std_offset,
        dst_offset,
        year + 1,
      )
      let mut start = b0
      let mut end = a2
      for candidate in [a0, b0, a1, b1, a2, b2] {
        if candidate <= utc_instant && candidate > start {
          start = candidate
        }
        if candidate > utc_instant && candidate < end {
          end = candidate
        }
      }
      Some((start, end))
    }
  }
}

///|
/// The local time type (offset, DST flag, and abbreviation) in effect at
/// the given UTC instant.
///
/// Unwrapping `dst_name`/`dst_offset` is safe: `parse_posix_tz` only ever
/// produces a `PosixTz` with `rule` present exactly when both are
/// present too.
pub fn PosixTz::type_at(self : PosixTz, utc_instant : Int64) -> LocalTimeType {
  if self.is_dst_at(utc_instant) {
    LocalTimeType::new(self.dst_offset.unwrap(), true, self.dst_name.unwrap())
  } else {
    LocalTimeType::new(self.std_offset, false, self.std_name)
  }
}

///|
/// The UTC offset in effect at the given UTC instant.
pub fn PosixTz::offset_at(self : PosixTz, utc_instant : Int64) -> Int {
  self.type_at(utc_instant).utc_offset()
}

///|
/// Resolves the given local (wall-clock) naive datetime to its UTC
/// offset(s) under this POSIX TZ rule.
pub fn PosixTz::offset_from_local(
  self : PosixTz,
  naive_local : @core.NaiveDateTime,
) -> MappedLocalTime[FixedOffset] {
  match self.rule {
    None => Single(FixedOffset::east(self.std_offset).unwrap())
    Some(rule) => {
      let std_off = self.std_offset
      let dst_off = self.dst_offset.unwrap()
      let year = naive_local.date().year()
      let (start_utc, end_utc) = compute_transitions(
        rule, std_off, dst_off, year,
      )
      let local_ts = naive_local.timestamp()
      match resolve_transition(local_ts, start_utc, std_off, dst_off) {
        Some(result) => result
        None =>
          match resolve_transition(local_ts, end_utc, dst_off, std_off) {
            Some(result) => result
            None => {
              let via_dst = local_ts - dst_off.to_int64()
              let dst_active = if start_utc < end_utc {
                via_dst >= start_utc && via_dst < end_utc
              } else {
                via_dst >= start_utc || via_dst < end_utc
              }
              if dst_active {
                Single(FixedOffset::east(dst_off).unwrap())
              } else {
                Single(FixedOffset::east(std_off).unwrap())
              }
            }
          }
      }
    }
  }
}

///|
pub impl TimeZone for PosixTz with fn offset_from_utc(self, utc) {
  FixedOffset::east(self.offset_at(utc.timestamp())).unwrap()
}

///|
pub impl TimeZone for PosixTz with fn offset_from_local(self, naive_local) {
  PosixTz::offset_from_local(self, naive_local)
}

///|
pub impl TimeZone for PosixTz with fn tz_name(self, utc) {
  self.type_at(utc.timestamp()).abbreviation()
}

///|
pub extend PosixTz with TimeZone::{
  offset_from_utc,
  tz_name,
  from_utc_datetime,
  from_local_datetime,
}
