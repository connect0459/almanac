///|
/// The result of resolving a local (wall-clock) `NaiveDateTime` to a UTC
/// offset. Mirrors chrono's `MappedLocalTime`: a local time can map to a
/// single offset, to two offsets (the "fold" at a backward DST
/// transition, where the same wall-clock time occurs twice), or to no
/// offset at all (the "gap" at a forward DST transition, where that
/// wall-clock time never occurs).
pub(all) enum MappedLocalTime {
  Single(FixedOffset)
  Ambiguous(FixedOffset, FixedOffset)
  Absent
} derive(Eq, @debug.Debug)

///|
pub extend MappedLocalTime with Eq::{equal}

///|
pub extend MappedLocalTime with Eq::{not_equal}

///|
pub extend MappedLocalTime with @debug.Debug::{to_repr}

///|
/// A time zone: given a naive datetime, resolves it to a concrete UTC
/// offset.
pub trait TimeZone {
  /// The offset in effect for the given UTC naive datetime. Always a
  /// single answer: UTC has no daylight saving, so this mapping is never
  /// ambiguous or absent.
  fn offset_from_utc(Self, @core.NaiveDateTime) -> FixedOffset
  /// The offset(s) in effect for the given local (wall-clock) naive
  /// datetime. See `MappedLocalTime`.
  fn offset_from_local(Self, @core.NaiveDateTime) -> MappedLocalTime
}
