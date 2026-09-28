///|
/// A datetime with an associated time zone.
///
/// Internally stores the UTC naive datetime plus the zone value `tz`; the
/// local (wall-clock) representation is derived on demand via
/// `tz.offset_from_utc`, never stored redundantly.
pub struct DateTime[Tz] {
  priv datetime : @core.NaiveDateTime
  priv tz : Tz
} derive(Eq, @debug.Debug)

///|
pub extend DateTime with Eq::{equal}

///|
pub extend DateTime with Eq::{not_equal}

///|
pub extend DateTime with @debug.Debug::{to_repr}

///|
/// Wraps a UTC naive datetime with the given time zone.
pub fn[Tz] DateTime::from_utc(
  datetime : @core.NaiveDateTime,
  tz : Tz,
) -> DateTime[Tz] {
  DateTime::{ datetime, tz, }
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
/// The naive local (wall-clock) datetime, i.e. the UTC datetime shifted by
/// `offset()`. Always succeeds: an offset is at most `±23:59:59`, far
/// within `TimeDelta`'s representable range.
pub fn[Tz : TimeZone] DateTime::naive_local(
  self : DateTime[Tz],
) -> @core.NaiveDateTime {
  let shift = @core.TimeDelta::seconds(
    self.offset().local_minus_utc().to_int64(),
  ).unwrap()
  self.datetime.add_signed(shift)
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
/// This datetime advanced by the signed duration `delta`, keeping the same
/// time zone. Delegates to `NaiveDateTime::add_signed` on the underlying
/// UTC instant.
pub fn[Tz] DateTime::add_signed(
  self : DateTime[Tz],
  delta : @core.TimeDelta,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.add_signed(delta), tz: self.tz, }
}

///|
/// This datetime moved back by the signed duration `delta`. See
/// `add_signed`.
pub fn[Tz] DateTime::sub_signed(
  self : DateTime[Tz],
  delta : @core.TimeDelta,
) -> DateTime[Tz] {
  DateTime::{ datetime: self.datetime.sub_signed(delta), tz: self.tz, }
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
/// This datetime's underlying UTC instant truncated toward the Unix epoch
/// to the nearest multiple of `granularity`, keeping the same time zone.
/// Operates on the absolute UTC instant, not the offset-shifted local
/// presentation: truncating to an hour granularity may still report a
/// non-zero local minute, depending on the time zone's offset (mirrors
/// Go's `Time.Truncate` and chrono's `DurationRound`). See
/// `@core.NaiveDateTime::truncate` for the conditions under which
/// `granularity` is rejected (returning `None`).
pub fn[Tz] DateTime::truncate(
  self : DateTime[Tz],
  granularity : @core.TimeDelta,
) -> DateTime[Tz]? {
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
) -> DateTime[Tz]? {
  self.datetime
  .round(granularity)
  .map(datetime => DateTime::{ datetime, tz: self.tz, })
}
