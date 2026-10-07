# `tz` package

Time zone support layered on top of `core`'s `NaiveDateTime`. Import `connect0459/almanac/tz` for the `TimeZone` trait, `Utc`, `FixedOffset`, `DateTime[Tz]`, and `Location` (IANA tzdata lookup by zone name, e.g. `"America/New_York"`).

## Key types

| Type | Description |
| :--- | :--- |
| `TimeZone` (trait) | Resolves a `NaiveDateTime` to a UTC offset; implemented by `Utc`, `FixedOffset`, `FixedZone`, and `Location` |
| `MappedLocalTime[T]` | The result of resolving a local (wall-clock) reading: `Single`, `Ambiguous` (DST fold), or `Absent` (DST gap); `T` is a `FixedOffset` or a `DateTime[Tz]` |
| `Utc` | The UTC zone: always offset zero |
| `FixedOffset` | A constant UTC offset, `±23:59:59` |
| `FixedZone` | A named zone with one constant offset; `zone_name`/`%Z` report the name |
| `DateTime[Tz]` | A `NaiveDateTime` paired with a time zone `Tz` |
| `Location` | A time zone backed by parsed IANA tzdata, resolving historical transitions and DST |
| `TransitionBounds` | The validity window (start/end) of a `Location`'s segment covering a given instant |

## Quick start

Attaching a time zone to a UTC instant and reading it back in local time:

```mbt check
///|
test {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(dt.offset(), @tz.FixedOffset::east(9 * 3600).unwrap())
  assert_eq(
    dt.naive_local(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(21, 0, 0).unwrap(),
    ),
  )
}
```

`DateTime::round`/`truncate` operate on the underlying UTC instant, not the offset-shifted local presentation — truncating to an hour boundary in UTC can still leave a non-zero local minute under a non-whole-hour `FixedOffset`:

```mbt check
///|
test {
  let naive = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
    @core.NaiveTime::from_hms(12, 15, 0).unwrap(),
  )
  let dt = @tz.DateTime::from_utc(
    naive,
    @tz.FixedOffset::east(9 * 3600 + 1800).unwrap(),
  )
  let truncated = dt.truncate(@core.TimeDelta::hours(1L).unwrap()).unwrap()
  assert_eq(
    truncated.naive_utc(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(12, 0, 0).unwrap(),
    ),
  )
  assert_eq(
    truncated.naive_local(),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 6, 15).unwrap(),
      @core.NaiveTime::from_hms(21, 30, 0).unwrap(),
    ),
  )
}
```

Looking up a real IANA zone by name and resolving its offset at a known DST transition:

```mbt check
///|
test {
  let ny = @tz.Location::load("America/New_York").unwrap()
  let dst_start_2024 = @core.NaiveDateTime::from_timestamp(1_710_054_000L, 0).unwrap()
  assert_eq(
    ny.offset_from_utc(dst_start_2024),
    @tz.FixedOffset::east(-14400).unwrap(),
  )
  assert_eq(ny.zone_name(dst_start_2024), "EDT")
}
```

## Embedded tz database

`Location::load` reads a snapshot of the IANA tz database compiled into the package: release **2026c**, 598 zones, taken from the compiled `rearguard` data of a macOS system (`/var/db/timezone/zoneinfo`). Zone rules change after a release, so a zone that changed later (a government altering its DST rule) keeps its old rules until the snapshot is regenerated. `Location::tzdata_version()` reports the release and `Location::zone_names()` lists the zones. The release is also named in the header of `tzdata_generated.mbt`.

To regenerate from another compiled zoneinfo tree, such as one built with `zic` from a specific release, run `just gen-tzdata <zoneinfo dir>`; the release is read from the tree's `+VERSION` file.

## API reference

### `TimeZone` trait

Implemented by `Utc`, `FixedOffset`, `FixedZone`, `Location`, and `PosixTz`. The trait is readonly: other packages can use `Tz : TimeZone` as a bound but cannot implement it, so these are the only zones. `DateTime[Tz]::offset`/`naive_local` require `Tz : TimeZone`.

Zone names have two roles with two spellings: `name()` (on `Location` and `FixedZone`) is the identifier that distinguishes the zone, such as the IANA id `"Asia/Tokyo"`, while `zone_name` (on every `TimeZone`, and on `DateTime`) is the name in effect at an instant, such as the abbreviation `"JST"` or `"EDT"`, `"UTC"`, or a bare `FixedOffset`'s offset text. `DateTime::timezone()` returns the zone value itself, as `with_timezone` takes one.

Every `NaiveDateTime` argument is a UTC reading except the one taken by `offset_from_local`, which is a local (wall-clock) reading. The type does not tell them apart, so pass `DateTime::naive_utc()` for the former and `DateTime::naive_local()` for the latter. To build a `DateTime` from either reading, use `DateTime::from_utc`/`DateTime::from_local`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | The offset in effect at a given UTC instant; never ambiguous |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | The offset(s) for a given local (wall-clock) instant, handling DST ambiguity/gaps |
| `zone_name(NaiveDateTime)` | `-> String` | The zone abbreviation/name in effect at a given UTC instant |
| `is_dst(NaiveDateTime)` | `-> Bool` | Whether daylight saving time is in effect at a given UTC instant; `false` by default, overridden by `Location`, `PosixTz` and `Local` |
| `transition_bounds(NaiveDateTime)` | `-> TransitionBounds` | The validity window of the offset in effect at a given UTC instant; unbounded on both sides by default, overridden by `Location` (its own `transition_bounds`), `PosixTz` and `Local` |
| `offset_from_abbreviation(String, NaiveDateTime)` | `-> FixedOffset?` | The offset a zone abbreviation (e.g. `"EST"`) denotes in this zone, resolved at a given UTC instant; `None` by default (`Utc`, `FixedOffset`), overridden by `Location` (see its own method), `PosixTz` (its standard and DST names) and `Local` |

---

### `MappedLocalTime[T]`

```mbt nocheck
///|
pub enum MappedLocalTime[T] {
  Single(T)
  Ambiguous(T, T) // a DST fold: two valid results, (earliest, latest)
  Absent // a DST gap: no valid result
}
```

`Absent` also covers components that do not form a valid reading (for example month 13) when the result is built from components (`DateTime::from_ymd_hms`, `DateTime::with_*`); to tell an invalid component from a gap, validate first with `NaiveDate::from_ymd`/`NaiveTime::from_hms`.

`Utc` and `FixedOffset` only ever produce `Single` (neither has daylight saving). A `Location` can produce all three around a real DST transition: `Ambiguous` when a local clock reading occurs twice (the fold at the end of DST), and `Absent` when a local clock reading never occurs (the gap at the start of DST). `T` is usually a `FixedOffset` (`TimeZone::offset_from_local`) or a `DateTime[Tz]` (`DateTime::from_local`/`from_ymd_hms`).

| Method | Signature | Description |
| :--- | :--- | :--- |
| `single()` | `-> T?` | The value, only when unambiguous; `None` for `Ambiguous`/`Absent` |
| `unwrap()` | `-> T` | The value when unambiguous; aborts, naming the reason, on `Ambiguous` or `Absent` |
| `earliest()` | `-> T?` | The earliest possible value (the sole value, or the first of an `Ambiguous` fold); `None` for `Absent` |
| `latest()` | `-> T?` | The latest possible value (the sole value, or the second of an `Ambiguous` fold); `None` for `Absent` |
| `map((T) -> U)` | `-> MappedLocalTime[U]` | Transform every value carried by `self`, preserving its shape |

`MappedLocalTime[T]` also implements `Eq` (when `T : Eq`).

There is deliberately no `and_then`. A step that itself returns a `MappedLocalTime`, applied to both sides of an `Ambiguous`, could yield up to four values with no obvious one to keep. Reduce to one value first with `single()`, `earliest()` or `latest()`, then continue; that choice stays with the caller:

```mbt check
///|
test {
  let dt = @tz.DateTime::from_ymd_hms(2024, 3, 5, 9, 0, 0, @tz.Utc::new()).unwrap()
  let moved = dt.with_hour(10).single().bind(d => d.with_minute(30).single())
  assert_eq(moved.map(d => d.hour() * 100 + d.minute()), Some(1030))
}
```

---

### `Utc`

The UTC zone, always offset zero.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Utc::new()` | `-> Self` | Construct the (zero-sized) UTC zone value |
| `Utc::now()` | `-> DateTime[Utc]` | The current UTC instant, read from the host's wall clock. Unlike every other function in this package, not a pure function of its arguments. Total: a host clock outside `NaiveDate`'s range (about 5.8 million years either side of 1970) is a broken environment, and aborts. The precision is at most one millisecond: the clock is read in whole milliseconds, so the sub-millisecond part is always zero, and a coarser host clock gives coarser values. |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | Always `FixedOffset::east(0)` |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | Always `Single(FixedOffset::east(0))` |
| `zone_name(NaiveDateTime)` | `-> String` | Always `"UTC"` |
| `to_string()` (`Show`) | `-> String` | `"UTC"`, the same text as `zone_name` |

`Utc` also implements `Eq` and `TimeZone`.

---

### `FixedOffset`

A constant UTC offset, in seconds, within `±23:59:59`.

Naming rule: a name with `offset` (`DateTime::offset`, `offset_from_utc`, `offset_from_local`) yields a `FixedOffset` value, while `utc_offset` and `local_minus_utc` yield the same quantity as a plain `Int` number of seconds.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `FixedOffset::east(Int)` | `-> Self?` | An offset east of UTC by the given seconds; `None` outside `±23:59:59` |
| `FixedOffset::west(Int)` | `-> Self?` | An offset west of UTC by the given seconds (negated internally); same range |
| `local_minus_utc()` | `-> Int` | The offset in seconds (negative for a western offset) |
| `utc_minus_local()` | `-> Int` | The sign-reversed offset in seconds (positive for a western offset) |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | Returns `self`, unchanged, regardless of the given instant |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | Always `Single(self)` |
| `zone_name(NaiveDateTime)` | `-> String` | Colon-separated sign, hour, and minute, e.g. `"+09:00"`; extended with a seconds component for a non-whole-minute offset, e.g. `"-04:56:02"` |
| `to_string()` (`Show`) | `-> String` | The same colon-separated text as `zone_name`, e.g. `"+09:00"` |

`FixedOffset` also implements `Eq` and `TimeZone`.

---

### `FixedZone`

A named zone with a constant offset and no daylight saving. Unlike a bare `FixedOffset`, whose `zone_name` is its own offset text (`"+09:00"`), a `FixedZone`'s `zone_name` (and so `%Z`) is the name it was given, or the offset text when the name is empty. Two zones are equal only when both the name and the offset match, so `FixedOffset`'s own equality and rendering are unaffected.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `FixedZone::new(String, FixedOffset)` | `-> Self` | A zone with the given name and constant offset |
| `name()` | `-> String` | The zone's name |
| `offset()` | `-> FixedOffset` | The zone's constant offset |
| `offset_from_utc(NaiveDateTime)` / `offset_from_local(NaiveDateTime)` | `-> FixedOffset` / `-> MappedLocalTime[FixedOffset]` | The constant offset; the local form is always `Single` |
| `zone_name(NaiveDateTime)` | `-> String` | The zone's name, or the offset text (`"+09:00"`) when the name is empty |
| `offset_from_abbreviation(String, NaiveDateTime)` | `-> FixedOffset?` | The offset when the abbreviation equals the text `zone_name` reports (the zone's name, or the offset text for an unnamed zone), else `None`, so `parse_date_time_in` can read a `%Z` name back |

### `DateTime[Tz]`

A `NaiveDateTime` paired with a time zone `Tz`. The UTC instant is stored directly; the local (wall-clock) representation is derived on demand.

`Eq`, `Hash` and `Compare` all identify the UTC instant and ignore the zone value, so the same instant in different zones is equal, hashes alike and compares as `0`; compare the zones themselves (or `naive_local()`) when the wall-clock reading matters. `Utc`, `FixedOffset`, `Location` and `TransitionBounds` implement `Hash` too, so all of them can key a `Map`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `DateTime::from_utc(NaiveDateTime, Tz)` | `-> Self[Tz]` | Wrap a UTC naive datetime with the given time zone |
| `DateTime::unix_epoch()` | `-> Self[Utc]` | The Unix epoch instant, `1970-01-01T00:00:00Z`; also the `Default` for `DateTime[Utc]` (no other zone has a natural default) |
| `DateTime::from_local(NaiveDateTime, Tz)` *(Tz : TimeZone)* | `-> MappedLocalTime[Self[Tz]]` | Build from a local (wall-clock) naive datetime, resolving DST ambiguity via `tz.offset_from_local` |
| `DateTime::from_local_lenient(NaiveDateTime, Tz)` *(Tz : TimeZone)* | `-> Self[Tz]` | Like `from_local` but always succeeds: an unambiguous reading resolves exactly; a fold takes its first occurrence (as `earliest()`); a gap is read with the offset in effect just before the transition, landing after the gap by its length (`02:30` in a `02:00`-`03:00` gap becomes `03:30`) |

The lenient rule is the library's only policy for a local reading that is repeated or skipped, and the calendar steps use it too. Other choices come from `from_local` (`.latest()` for the later occurrence of a fold, `.single()` to reject both cases). To build one from components, use `NaiveDateTime::from_ymd_hms(..)` and then `DateTime::from_local_lenient`.
| `DateTime::from_ymd_hms(Int, Int, Int, Int, Int, Int, Tz)` *(Tz : TimeZone)* | `-> MappedLocalTime[Self[Tz]]` | Build from local calendar/time-of-day components; `Absent` for an invalid date/time-of-day, in addition to the usual DST-gap case |
| `DateTime::from_timestamp(Int64, Int, Tz)` | `-> Self[Tz]?` | Build from a Unix timestamp (seconds + nanoseconds) through the given time zone; always unambiguous, `None` only on an out-of-range input |
| `DateTime::from_timestamp_millis(Int64, Tz)` / `from_timestamp_micros` / `from_timestamp_nanos` | `-> Self[Tz]?` | Build from a Unix timestamp in that unit through the given time zone; `None` if the instant is outside `NaiveDate`'s range (reachable only for milliseconds at `Int64` extremes) |
| `naive_utc()` | `-> NaiveDateTime` | The underlying naive datetime, in UTC |
| `timezone()` | `-> Tz` | The time zone value this datetime is expressed in |
| `offset()` *(Tz : TimeZone)* | `-> FixedOffset` | The UTC offset in effect at this instant |
| `naive_local()` *(Tz : TimeZone)* | `-> NaiveDateTime` | The UTC datetime shifted by `offset()` |
| `with_timezone(Tz2)` | `-> Self[Tz2]` | Re-express this datetime in `Tz2`, keeping the same UTC instant |
| `to_utc()` | `-> Self[Utc]` | Re-express the same instant in UTC |
| `fixed_offset()` | `-> Self[FixedOffset]` | Re-express the same instant with the offset in effect at that instant frozen (requires `Tz : TimeZone`); it no longer follows later DST changes |
| `add_signed(TimeDelta)` | `-> Self[Tz]` | Advance by a signed duration, keeping the same time zone |
| `sub_signed(TimeDelta)` | `-> Self[Tz]` | Move back by a signed duration |
| `add_offset(FixedOffset)` / `sub_offset(FixedOffset)` | `-> Self[Tz]` | Move the instant forward/backward by an offset's seconds (the opposite way for a west offset), keeping the same time zone; abort if the result leaves `NaiveDate`'s range |
| `checked_add_offset(FixedOffset)` / `checked_sub_offset(FixedOffset)` | `-> Self[Tz]?` | The same, but `None` instead of aborting when out of range |
| `add_months(Int)` *(Tz : TimeZone)* | `-> Self[Tz]` | Advance the local date by months, keeping the local time of day and the time zone; see `NaiveDate::add_months` (in `core`) for the day-of-month clamping rule. A result in a DST fold takes the earlier occurrence and one in a gap moves forward by the gap's length, as `from_local_lenient` does |
| `sub_months(Int)` | `-> Self[Tz]` | Move the date back by months |
| `add_years(Int)` *(Tz : TimeZone)* | `-> Self[Tz]` | Advance the local date by years, keeping the local time of day and the time zone; see `NaiveDate::add_years` (in `core`) for the clamping rule |
| `sub_years(Int)` | `-> Self[Tz]` | Move the date back by years |
| `add_days(Int)` *(Tz : TimeZone)* | `-> Self[Tz]` | Advance the local date by days, keeping the local time of day and the time zone, so a day across a DST change lasts 23 or 25 hours; fold and gap as for `add_months` |
| `sub_days(Int)` | `-> Self[Tz]` | Move the date back by days |
| `add_seconds(Int64)` / `sub_seconds(Int64)` | `-> Self[Tz]` | Move the instant by a whole number of seconds (backward if negative), keeping the same time zone; abort if the result leaves `NaiveDate`'s range |
| `checked_add_seconds(Int64)` / `checked_sub_seconds(Int64)` | `-> Self[Tz]?` | The same, but `None` instead of aborting when out of range |
| `checked_add_signed(TimeDelta)` / `checked_sub_signed(TimeDelta)` | `-> Self[Tz]?` | Like `add_signed`/`sub_signed`, but `None` instead of aborting when the result leaves `NaiveDate`'s range |
| `checked_add_months(Int)` / `checked_sub_months(Int)` / `checked_add_years(Int)` / `checked_sub_years(Int)` / `checked_add_days(Int)` / `checked_sub_days(Int)` | `-> Self[Tz]?` | Like the aborting forms above, but `None` instead of aborting when the date leaves `NaiveDate`'s range |
| `date()` / `time()` | `-> NaiveDate` / `-> NaiveTime` | The local calendar date / time of day |
| `year()` / `month()` / `day()` / `ordinal()` / `weekday()` / `iso_week()` | `-> Int` / `-> Month` / `-> Int` / `-> Int` / `-> Weekday` / `-> IsoWeek` | Local calendar components, derived from `naive_local()` (requires `Tz : TimeZone`) |
| `ymd()` / `hms()` | `-> (Int, Month, Int)` / `(Int, Int, Int)` | The local date and time components together |
| `leap_year()` | `-> Bool` | Whether the local calendar year is a leap year |
| `hour()` / `minute()` / `second()` / `nanosecond()` | `-> Int` | Local time-of-day components; a leap second reports `second() == 59` with `nanosecond() >= 1_000_000_000` |
| `month0()` / `day0()` / `ordinal0()` / `quarter()` / `num_days_in_month()` / `num_days_from_ce()` | `-> Int` | Further local calendar components (0-based month/day/ordinal, quarter `1..=4`, month length, days since the start of the Common Era) |
| `year_ce()` / `hour12()` | `-> YearCe` / `-> ClockHour12` | Local year as a Common Era flag plus a positive year; local hour as a PM flag plus an hour in `1..=12` (`@core.YearCe`, `@core.ClockHour12`) |
| `num_seconds_from_midnight()` | `-> Int` | Seconds since local midnight |
| `with_year(Int)` / `with_month(Int)` / `with_day(Int)` / `with_ordinal(Int)` / `with_hour(Int)` / `with_minute(Int)` / `with_second(Int)` / `with_nanosecond(Int)` | `-> MappedLocalTime[Self[Tz]]` | Replace one local component and re-resolve the wall-clock reading through the zone: `Absent` for an invalid value or a DST gap, `Ambiguous` inside a DST fold |
| `with_month0(Int)` / `with_day0(Int)` / `with_ordinal0(Int)` | `-> MappedLocalTime[Self[Tz]]` | 0-based counterparts of `with_month`/`with_day`/`with_ordinal`, resolved the same way |
| `with_date(NaiveDate)` | `-> MappedLocalTime[Self[Tz]]` | Replace the local date, keeping the local time of day; `Absent` inside a DST gap, `Ambiguous` inside a fold |
| `with_time(NaiveTime)` | `-> MappedLocalTime[Self[Tz]]` | Replace the local time of day, keeping the local date, resolved the same way as the `with_*` setters |
| `timestamp()` / `timestamp_millis()` | `-> Int64` | Non-leap seconds / milliseconds since the Unix epoch, flooring toward negative infinity; independent of the zone |
| `timestamp_micros()` / `timestamp_nanos()` | `-> Int64?` | Microseconds / nanoseconds since the Unix epoch; `None` if the instant overflows `Int64` |
| `timestamp_subsec_nanos()` / `timestamp_subsec_millis()` / `timestamp_subsec_micros()` | `-> Int` | The sub-second component of the instant in that unit |
| `signed_duration_since(Self[Tz2])` | `-> TimeDelta` | The signed duration from `other` to `self`, independent of either's time zone |
| `zone_name()` | `-> String` | The zone's name at this instant: an IANA abbreviation (`"EDT"`), a `FixedZone`'s name, `"UTC"`, or a bare `FixedOffset`'s offset text; the same text as `%Z` (requires `Tz : TimeZone`) |
| `is_dst()` | `-> Bool` | Whether daylight saving time is in effect at this instant (requires `Tz : TimeZone`) |
| `zone_bounds()` | `-> TransitionBounds` | The validity window of the offset in effect at this instant, either side `None` when unbounded (requires `Tz : TimeZone`); see `TransitionBounds` |
| `to_string()` (`Show`) | `-> String` | The local date-time and the zone's name at that instant joined by a space, e.g. `"2024-01-02 13:45:06.500 +09:00"`, `"... UTC"`, `"... EDT"` (requires `Tz : TimeZone`) |
| `years_since(Self[Tz2])` | `-> Int?` | Full calendar years elapsed from `base` (which may be in another time zone), reading both as local dates in the receiver's time zone and ignoring the time of day; `None` if `base` is later |
| `compare(Self[Tz])` / `<` / `>` / `<=` / `>=` | `-> Int` / `-> Bool` | Order by UTC instant, ignoring the zone value; consistent with `==` |
| `compare_instant(Self[Tz2])` | `-> Int` | Order by UTC instant against a datetime in a different time zone type |
| `round(TimeDelta)` | `-> Result[Self[Tz], @core.RoundingError]` | Round the underlying UTC instant to the nearest multiple of a granularity since the Unix epoch, keeping the same time zone; see `TimeDelta::round` (in `core`) for which granularities are supported |
| `round_up(TimeDelta)` | `-> Result[Self[Tz], @core.RoundingError]` | Round the underlying UTC instant up (toward positive infinity) to the next multiple of a granularity since the Unix epoch, unchanged if already a multiple, keeping the same time zone; see `NaiveDateTime::round_up` for the failure reasons |
| `truncate(TimeDelta)` | `-> Result[Self[Tz], @core.RoundingError]` | Truncate the underlying UTC instant toward the Unix epoch; see Quick start above for how this differs from truncating the local presentation |
| `round_subsecs(Int)` / `truncate_subsecs(Int)` | `-> Result[Self[Tz], @core.RoundingError]` / `-> Self[Tz]` | Round or truncate the underlying UTC instant to a number of fractional-second digits (`0..=9`; other values abort) |

Rounding acts on the UTC instant, not the local reading, so in a zone such as `+05:30` a one-hour truncation leaves a local time that is not on the hour. To round to a local boundary, round `naive_local()` and resolve the result with `DateTime::from_local`. Calendar steps (`add_days`, `add_months`, `add_years`) act on the local reading, while `add_signed`, `add_seconds` and the rounding methods act on the instant.

`DateTime[Tz]` also implements `Eq` (when `Tz : Eq`).

---

### `Location`

A time zone backed by parsed IANA tzdata (TZif binary format, plus a POSIX TZ string for extrapolating past the last recorded transition).

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Location::load(String)` | `-> Self?` | Look up an embedded IANA zone by name (e.g. `"Asia/Tokyo"`), following aliases; `None` if the name is unknown, including the empty string (which is not an alias for UTC); `"UTC"` resolves like any other zone; a zone is parsed once per name and reused by later calls |
| `Location::load_system(String)` | `-> Self?` | Like `Location::load`, but on `native` searches the directory named by `$ZONEINFO`, then the system zoneinfo directories (`/usr/share/zoneinfo`, `/usr/share/lib/zoneinfo`, `/usr/lib/locale/TZ`, `/etc/zoneinfo`), then the embedded database, so host tzdata newer than the embedded release takes effect. File names match as the host file system does (on a case-insensitive one, `"asia/tokyo"` is found, and `name()` keeps the given text), while the embedded database is case-sensitive. A file that is not TZif is skipped; `None` if no source has the zone or the name is empty, absolute, or contains `..`. On `js`, `wasm` and `wasm-gc` it is `Location::load`. `$ZONEINFO` must be a directory; zip archives are not supported. Reads live OS state |
| `Location::zone_names()` | `-> Array[String]` | The names of the embedded zones, ascending by string order; each loads through `Location::load`. Names the source tzdata tree linked to another zone are aliases and are not listed, though `load` accepts them. A new array on every call |
| `Location::tzdata_version()` | `-> String` | The IANA tz database release of the embedded snapshot (e.g. `"2026c"`), or `"unknown"` when the snapshot was generated from a tree without a `+VERSION` file. `Location::load_system` may read newer host data |
| `Location::utc()` | `-> Self` | The UTC zone as a `Location` (equal to `Location::load("UTC")`, `name()` is `Some("UTC")`), for APIs taking a `Location` rather than the separate `Utc` type |
| `Location::from_tzif_bytes(Bytes)` | `-> Self?` | Parse a zone directly from raw TZif bytes; `None` if malformed |
| `Location::from_tzif_bytes_named(String, Bytes)` | `-> Self?` | Like `from_tzif_bytes`, but `name()` reports the given name; any text is accepted as given, without validation |
| `name()` | `-> String?` | The IANA identifier this `Location` was loaded with (the name as given to `Location::load`, not canonicalized through an alias); `None` for one built via `from_tzif_bytes` |
| `to_string()` (`Show`) | `-> String` | `name()`, or an empty string for a `Location` without one |
| `offset_from_abbreviation(String, NaiveDateTime)` | `-> FixedOffset?` | The offset an abbreviation (e.g. `"EST"`) denotes: that of the type in effect at the given UTC instant if it matches, else of the first type in the zone's table with that abbreviation; `None` if none has it |
| `type_at(NaiveDateTime)` | `-> LocalTimeType` | The offset, DST flag, and abbreviation in effect at a given UTC instant |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | The offset in effect at a given UTC instant |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | The offset(s) for a given local instant, resolving DST folds and gaps |
| `zone_name(NaiveDateTime)` | `-> String` | The abbreviation in effect at a given instant, e.g. `"EDT"` |
| `transition_bounds(NaiveDateTime)` | `-> TransitionBounds` | The validity window of the segment covering a given instant; see `TransitionBounds` |

`Location` also implements `TimeZone`. `==` is structural: two `Location`s are equal when their parsed TZif data, POSIX rule and `name()` all match, so an alias (e.g. `"Japan"`) is unequal to its canonical zone (`"Asia/Tokyo"`) even though both resolve identically.

### `TransitionBounds`

The validity window of a `Location`'s segment covering a given instant, as returned by `Location::transition_bounds`: the local time type `type_at` reports is in effect from `start()` (inclusive) until `end()` (exclusive). `None` on either side means unbounded in that direction.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `start()` | `-> NaiveDateTime?` | The instant this segment began; `None` if unbounded (before the zone's first recorded transition, or for a zone with no transitions at all) |
| `end()` | `-> NaiveDateTime?` | The instant the next segment begins; `None` if unbounded (past the zone's last recorded transition, when no POSIX rule extrapolates further) |

Past the last recorded transition, the POSIX rule's own bounds are computed exactly (not approximated near a year boundary).

`TransitionBounds` also implements `Eq`.

### `LocalTimeType`

The offset, DST flag, and abbreviation for one segment of a `Location`'s timeline, as returned by `Location::type_at`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `LocalTimeType::new(Int, Bool, String)` | `-> Self?` | Construct from UTC offset (seconds), DST flag, and abbreviation; `None` if the offset is outside `±86399` (`±23:59:59`), so every `LocalTimeType` has an offset a `FixedOffset` can hold |
| `utc_offset()` | `-> Int` | UTC offset in seconds |
| `is_dst()` | `-> Bool` | Whether daylight saving is in effect |
| `abbreviation()` | `-> String` | The zone abbreviation, e.g. `"EST"`/`"EDT"` |

`LocalTimeType` also implements `Eq`.

### `Local`

The host's configured local time zone, available on every backend. Where it comes from depends on the backend:

| Backend | Source |
| :--- | :--- |
| `native` | `$TZ` or, when unset, `/etc/localtime` |
| `js` | The zone name reported by the runtime's `Intl`, resolved as a `$TZ` value would be (in practice an IANA name); `$TZ` is not read by this library, so whether it is honored is up to the runtime; `None` if the name is not in the embedded tz database |
| `wasm`, `wasm-gc` | `$TZ` alone; with `$TZ` unset there is nothing to fall back on, because these backends have no file access, so `Local::new()` is `None`; hosts that have no environment variables at all, such as a browser, therefore always give `None` |

The one place the host environment is read is `Local::new`; the rule it applies to `$TZ` is internal and not public API.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Local::new()` | `-> Self?` | Resolves the host's configured time zone; `None` if it could not be determined. Reads live host state — not a pure function of its arguments. |
| `Local::now()` | `-> DateTime[Local]?` | The current instant in the host's local zone, the counterpart of `Utc::now()`; `None` when `Local::new()` is `None`, that is, when the zone cannot be determined; the clock itself is read as in `Utc::now()`, so with the same precision of at most one millisecond |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | Delegates to the resolved zone |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | Delegates to the resolved zone |
| `zone_name(NaiveDateTime)` | `-> String` | Delegates to the resolved zone |

`Local` also implements `TimeZone`. Where `$TZ` is read (`native`, `wasm`, `wasm-gc`), one leading colon of it is ignored (`":Asia/Tokyo"` is `"Asia/Tokyo"`). The remainder may be an empty string (UTC, so a lone `":"` is UTC too), the absolute path of a TZif file (`"/usr/share/zoneinfo/Asia/Tokyo"`), an IANA zone name, or a bare POSIX TZ rule such as `"JST-9"` or `"FOO5BAR4,M3.2.0,M11.1.0"`; an IANA name takes precedence when a string is both (e.g. `"EST5EDT"`). A path (read on `native` only) that cannot be read as TZif data makes `Local::new()` return `None` rather than falling back to UTC; on `wasm` and `wasm-gc` an absolute path is always `None`. On `native`, an IANA name is searched as in `Location::load_system` (`$ZONEINFO`, the system zoneinfo directories, then the embedded database); on the other backends it is matched against the embedded tz database only.

---

### Advanced: low-level TZif and POSIX TZ parsing

Failure is reported as `None` throughout this package (`parse_tzif`, `parse_posix_tz`, `Location::from_tzif_bytes`, `Location::from_tzif_bytes_named`, `Location::load`), unlike `format`, whose parsers raise a `FormatError` naming the reason. These read machine data (TZif bytes, POSIX TZ strings, zone names), where a caller's response to any failure is the same, so no reason is carried; each function's documentation lists the conditions under which it returns `None` (a malformed structure, an offset beyond `±23:59:59`, or an unknown zone name).

These back `Location` and are not usually needed directly; use `Location::load`/`from_tzif_bytes` unless building a custom zone-data pipeline.

| Symbol | Signature | Description |
| :--- | :--- | :--- |
| `parse_tzif(Bytes)` | `-> TzifData?` | Parse raw TZif bytes (header, transition table, local-time-type table, leap seconds, POSIX TZ footer) |
| `parse_posix_tz(String)` | `-> PosixTz?` | Parse a POSIX TZ rule string (all three date-rule forms: `Jn`, `n`, `Mm.w.d`) |

| Type | Key methods | Description |
| :--- | :--- | :--- |
| `TzifData` | `transitions()`, `transition_types()`, `local_time_types()`, `leap_seconds()`, `posix_tz()` | The parsed contents of a TZif file; the array accessors return copies, and `posix_tz()` is the already-parsed `PosixTz?` footer (`None` when empty or absent; a malformed one makes `parse_tzif` return `None`) |
| `PosixTz` | `type_at(NaiveDateTime)` (a UTC reading, like `Location::type_at`), `offset_from_local(NaiveDateTime)` | An evaluated POSIX TZ rule, for extrapolating past a TZif file's last recorded transition; also a `TimeZone` in its own right (a constant offset when the rule has no DST part, e.g. `JST-9`) |
