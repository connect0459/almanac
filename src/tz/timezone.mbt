///|
/// The result of resolving a local (wall-clock) reading against a time
/// zone: it can map to a single result, to two results (the "fold" at a
/// backward DST transition, where the same wall-clock reading occurs
/// twice), or to no result at all (the "gap" at a forward DST transition,
/// where that wall-clock reading never occurs). `T` is usually a
/// `FixedOffset` (see `TimeZone::offset_from_local`) or a `DateTime[Tz]`
/// (see `DateTime::from_local`).
///
/// `Absent` also reports components that do not form a valid reading at all
/// (for example month 13) when a `MappedLocalTime` is built from
/// components, as `DateTime::from_ymd_hms` and `DateTime::with_*` do; a
/// caller that must tell the two apart validates the components first with
/// `NaiveDate::from_ymd` and `NaiveTime::from_hms`.
pub(all) enum MappedLocalTime[T] {
  Single(T)
  Ambiguous(T, T)
  Absent
} derive(Eq, @debug.Debug)

///|
pub extend MappedLocalTime with Eq::{equal}

///|
pub extend MappedLocalTime with Eq::{not_equal}

///|
pub extend MappedLocalTime with @debug.Debug::{to_repr}

///|
/// The value, only when `self` is unambiguous (`Single`); `None` for
/// `Ambiguous` or `Absent`.
pub fn[T] MappedLocalTime::single(self : MappedLocalTime[T]) -> T? {
  match self {
    Single(value) => Some(value)
    Ambiguous(_, _) | Absent => None
  }
}

///|
/// The value of an unambiguous (`Single`) local time.
///
/// Aborts, naming the reason, on `Ambiguous` (the reading occurs twice) or
/// `Absent` (the reading never occurs); use `single`, `earliest` or `latest`
/// to handle those cases instead.
pub fn[T] MappedLocalTime::unwrap(self : MappedLocalTime[T]) -> T {
  match self {
    Single(value) => value
    Ambiguous(_, _) =>
      abort("MappedLocalTime::unwrap: the local time is ambiguous")
    Absent => abort("MappedLocalTime::unwrap: the local time does not exist")
  }
}

///|
/// The earliest value `self` could resolve to: the sole value for
/// `Single`, the first (earlier-UTC-instant) value of an `Ambiguous`
/// fold, or `None` for `Absent`.
pub fn[T] MappedLocalTime::earliest(self : MappedLocalTime[T]) -> T? {
  match self {
    Single(value) => Some(value)
    Ambiguous(earliest, _) => Some(earliest)
    Absent => None
  }
}

///|
/// The latest value `self` could resolve to: the sole value for
/// `Single`, the second (later-UTC-instant) value of an `Ambiguous`
/// fold, or `None` for `Absent`.
pub fn[T] MappedLocalTime::latest(self : MappedLocalTime[T]) -> T? {
  match self {
    Single(value) => Some(value)
    Ambiguous(_, latest) => Some(latest)
    Absent => None
  }
}

///|
/// Applies `f` to every value carried by `self`, preserving its shape
/// (`Single`/`Ambiguous`/`Absent`).
pub fn[T, U] MappedLocalTime::map(
  self : MappedLocalTime[T],
  f : (T) -> U,
) -> MappedLocalTime[U] {
  match self {
    Single(value) => Single(f(value))
    Ambiguous(earliest, latest) => Ambiguous(f(earliest), f(latest))
    Absent => Absent
  }
}

///|
/// Resolves whether `local_ts` (a local wall-clock reading, as a naive
/// Unix instant) falls in the gap or fold around a single transition from
/// `offset_before` to `offset_after` at `transition_utc`. Returns `None`
/// if this transition is not relevant to `local_ts` (a normal single
/// resolution should be used instead).
fn resolve_transition(
  local_ts : Int64,
  transition_utc : Int64,
  offset_before : Int,
  offset_after : Int,
) -> MappedLocalTime[FixedOffset]? {
  let local_start = transition_utc + offset_before.to_int64()
  let local_end = transition_utc + offset_after.to_int64()
  if offset_after > offset_before {
    if local_ts >= local_start && local_ts < local_end {
      Some(Absent)
    } else {
      None
    }
  } else if offset_after < offset_before {
    if local_ts >= local_end && local_ts < local_start {
      Some(
        Ambiguous(
          FixedOffset::east(offset_before).unwrap(),
          FixedOffset::east(offset_after).unwrap(),
        ),
      )
    } else {
      None
    }
  } else {
    None
  }
}

///|
/// A time zone: given a naive datetime, resolves it to a concrete UTC
/// offset.
///
/// The trait is readonly: code outside this package can use it as a bound
/// but cannot implement it, so the zones are the ones this package provides
/// (`Utc`, `FixedOffset`, `FixedZone`, `Location`, `PosixTz` and, on
/// native, `Local`).
///
/// Every `NaiveDateTime` argument is a UTC reading except the one taken by
/// `offset_from_local`, which is a local (wall-clock) reading; the type does
/// not distinguish them, so pass `DateTime::naive_utc` for the former and
/// `DateTime::naive_local` for the latter.
pub trait TimeZone {
  /// The offset in effect for the given UTC naive datetime. Always a
  /// single answer: UTC has no daylight saving, so this mapping is never
  /// ambiguous or absent.
  fn offset_from_utc(Self, @core.NaiveDateTime) -> FixedOffset
  /// The offset(s) in effect for the given local (wall-clock) naive
  /// datetime. See `MappedLocalTime`.
  fn offset_from_local(Self, @core.NaiveDateTime) -> MappedLocalTime[
    FixedOffset,
  ]
  /// The name in effect for the given UTC naive datetime: an IANA zone's
  /// abbreviation (e.g. `"EDT"`), `Utc`'s fixed `"UTC"`, or a bare
  /// `FixedOffset`'s own offset string (e.g. `"+09:00"`), since a fixed
  /// offset carries no name distinct from its offset.
  fn zone_name(Self, @core.NaiveDateTime) -> String
  /// Whether daylight saving time is in effect at the given UTC naive
  /// datetime. `false` by default: a zone with no daylight saving (`Utc`,
  /// `FixedOffset`) never observes it.
  fn is_dst(Self, @core.NaiveDateTime) -> Bool = _
  /// The validity window of the offset in effect at the given UTC naive
  /// datetime. Unbounded on both sides by default: a zone with a single
  /// fixed offset (`Utc`, `FixedOffset`) never changes it.
  fn transition_bounds(Self, @core.NaiveDateTime) -> TransitionBounds = _
  /// The offset a zone abbreviation (e.g. `"EST"`) denotes in this zone,
  /// resolved against the given UTC naive datetime, or `None` if the zone
  /// does not know it. `None` by default: `Utc` and `FixedOffset` carry no
  /// abbreviation of their own to look up.
  fn offset_from_abbreviation(Self, String, @core.NaiveDateTime) -> FixedOffset? = _
}

///|
impl TimeZone with fn is_dst(_self, _utc) {
  false
}

///|
impl TimeZone with fn offset_from_abbreviation(_self, _abbreviation, _near) {
  None
}

///|
impl TimeZone with fn transition_bounds(_self, _utc) {
  TransitionBounds::{ start: None, end: None, }
}
