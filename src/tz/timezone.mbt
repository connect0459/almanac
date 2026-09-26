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
) -> MappedLocalTime? {
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
pub trait TimeZone {
  /// The offset in effect for the given UTC naive datetime. Always a
  /// single answer: UTC has no daylight saving, so this mapping is never
  /// ambiguous or absent.
  fn offset_from_utc(Self, @core.NaiveDateTime) -> FixedOffset
  /// The offset(s) in effect for the given local (wall-clock) naive
  /// datetime. See `MappedLocalTime`.
  fn offset_from_local(Self, @core.NaiveDateTime) -> MappedLocalTime
}
