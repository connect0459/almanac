# `tz` package

Time zone support layered on top of `core`'s `NaiveDateTime`. Import `connect0459/chrono/tz` for the `TimeZone` trait, `Utc`, `FixedOffset`, `DateTime[Tz]`, and `Location` (IANA tzdata lookup by zone name, e.g. `"America/New_York"`).

## Key types

| Type | Description |
| :--- | :--- |
| `TimeZone` (trait) | Resolves a `NaiveDateTime` to a UTC offset; implemented by `Utc`, `FixedOffset`, and `Location` |
| `MappedLocalTime[T]` | The result of resolving a local (wall-clock) reading: `Single`, `Ambiguous` (DST fold), or `Absent` (DST gap); `T` is a `FixedOffset` or a `DateTime[Tz]` |
| `Utc` | The UTC zone: always offset zero |
| `FixedOffset` | A constant UTC offset, `±23:59:59` |
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
  assert_eq(ny.tz_name(dst_start_2024), "EDT")
}
```

## API reference

### `TimeZone` trait

Implemented by `Utc`, `FixedOffset`, `Location`, and `PosixTz`. `DateTime[Tz]::offset`/`naive_local` require `Tz : TimeZone`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | The offset in effect at a given UTC instant; never ambiguous |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | The offset(s) for a given local (wall-clock) instant, handling DST ambiguity/gaps |
| `tz_name(NaiveDateTime)` | `-> String` | The zone abbreviation/name in effect at a given instant |
| `is_dst(NaiveDateTime)` | `-> Bool` | Whether daylight saving time is in effect at a given UTC instant; `false` by default, overridden by `Location`, `PosixTz` and `Local` |
| `transition_bounds(NaiveDateTime)` | `-> TransitionBounds` | The validity window of the offset in effect at a given UTC instant; unbounded on both sides by default, overridden by `Location` (its own `transition_bounds`), `PosixTz` and `Local` |
| `offset_from_abbreviation(String, NaiveDateTime)` | `-> FixedOffset?` | The offset a zone abbreviation (e.g. `"EST"`) denotes in this zone, resolved at a given UTC instant; `None` by default (`Utc`, `FixedOffset`), overridden by `Location` (see its own method), `PosixTz` (its standard and DST names) and `Local` |
| `from_utc_datetime(NaiveDateTime)` | `-> DateTime[Self]` | Interpret a naive datetime as UTC and express it in this zone; same as `DateTime::from_utc` (default implementation) |
| `from_local_datetime(NaiveDateTime)` | `-> MappedLocalTime[DateTime[Self]]` | Interpret a naive datetime as wall-clock time in this zone; same as `DateTime::from_local` (default implementation) |

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

`Utc` and `FixedOffset` only ever produce `Single` (neither has daylight saving). A `Location` can produce all three around a real DST transition: `Ambiguous` when a local clock reading occurs twice (the fold at the end of DST), and `Absent` when a local clock reading never occurs (the gap at the start of DST). `T` is usually a `FixedOffset` (`TimeZone::offset_from_local`) or a `DateTime[Tz]` (`DateTime::from_local`/`from_ymd_hms`).

| Method | Signature | Description |
| :--- | :--- | :--- |
| `single()` | `-> T?` | The value, only when unambiguous; `None` for `Ambiguous`/`Absent` |
| `earliest()` | `-> T?` | The earliest possible value (the sole value, or the first of an `Ambiguous` fold); `None` for `Absent` |
| `latest()` | `-> T?` | The latest possible value (the sole value, or the second of an `Ambiguous` fold); `None` for `Absent` |
| `map((T) -> U)` | `-> MappedLocalTime[U]` | Transform every value carried by `self`, preserving its shape |

`MappedLocalTime[T]` also implements `Eq` (when `T : Eq`).

---

### `Utc`

The UTC zone, always offset zero.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Utc::new()` | `-> Self` | Construct the (zero-sized) UTC zone value |
| `Utc::now()` | `-> DateTime[Utc]` | The current UTC instant, read from the host's wall clock. Unlike every other function in this package, not a pure function of its arguments. |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | Always `FixedOffset::east(0)` |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | Always `Single(FixedOffset::east(0))` |
| `tz_name(NaiveDateTime)` | `-> String` | Always `"UTC"` |
| `to_string()` (`Show`) | `-> String` | `"UTC"`, the same text as `tz_name` |

`Utc` also implements `Eq` and `TimeZone`.

---

### `FixedOffset`

A constant UTC offset, in seconds, within `±23:59:59`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `FixedOffset::east(Int)` | `-> Self?` | An offset east of UTC by the given seconds; `None` outside `±23:59:59` |
| `FixedOffset::west(Int)` | `-> Self?` | An offset west of UTC by the given seconds (negated internally); same range |
| `local_minus_utc()` | `-> Int` | The offset in seconds (negative for a western offset) |
| `utc_minus_local()` | `-> Int` | The sign-reversed offset in seconds (positive for a western offset) |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | Returns `self`, unchanged, regardless of the given instant |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | Always `Single(self)` |
| `tz_name(NaiveDateTime)` | `-> String` | Colon-separated sign, hour, and minute, e.g. `"+09:00"`; extended with a seconds component for a non-whole-minute offset, e.g. `"-04:56:02"` |
| `to_string()` (`Show`) | `-> String` | The same colon-separated text as `tz_name`, e.g. `"+09:00"` |

`FixedOffset` also implements `Eq` and `TimeZone`.

---

### `DateTime[Tz]`

A `NaiveDateTime` paired with a time zone `Tz`. The UTC instant is stored directly; the local (wall-clock) representation is derived on demand.

`Eq` and `Hash` cover the UTC instant and the zone value, so equal instants in different zones are unequal (see `compare_instant` for an instant-only comparison). `Utc`, `FixedOffset`, `Location` and `TransitionBounds` implement `Hash` too, so all of them can key a `Map`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `DateTime::from_utc(NaiveDateTime, Tz)` | `-> Self[Tz]` | Wrap a UTC naive datetime with the given time zone |
| `DateTime::from_local(NaiveDateTime, Tz)` *(Tz : TimeZone)* | `-> MappedLocalTime[Self[Tz]]` | Build from a local (wall-clock) naive datetime, resolving DST ambiguity via `tz.offset_from_local` |
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
| `add_months(Int)` | `-> Self[Tz]` | Advance the date by months, keeping the time of day and time zone; see `NaiveDate::add_months` (in `core`) for the day-of-month clamping rule |
| `sub_months(Int)` | `-> Self[Tz]` | Move the date back by months |
| `add_years(Int)` | `-> Self[Tz]` | Advance the date by years, keeping the time of day and time zone; see `NaiveDate::add_years` (in `core`) for the clamping rule |
| `sub_years(Int)` | `-> Self[Tz]` | Move the date back by years |
| `add_days(Int)` | `-> Self[Tz]` | Advance the date by days, keeping the time of day and time zone |
| `sub_days(Int)` | `-> Self[Tz]` | Move the date back by days |
| `date_naive()` / `time()` | `-> NaiveDate` / `-> NaiveTime` | The local calendar date / time of day |
| `year()` / `month()` / `day()` / `ordinal()` / `weekday()` / `iso_week()` | `-> Int` / `-> Month` / `-> Int` / `-> Int` / `-> Weekday` / `-> IsoWeek` | Local calendar components, derived from `naive_local()` (requires `Tz : TimeZone`) |
| `hour()` / `minute()` / `second()` / `nanosecond()` | `-> Int` | Local time-of-day components; a leap second reports `second() == 59` with `nanosecond() >= 1_000_000_000` |
| `month0()` / `day0()` / `ordinal0()` / `quarter()` / `num_days_in_month()` / `num_days_from_ce()` | `-> Int` | Further local calendar components (0-based month/day/ordinal, quarter `1..=4`, month length, days since the start of the Common Era) |
| `year_ce()` / `hour12()` | `-> (Bool, Int)` | Local year as a Common Era flag plus a positive year; local hour as a PM flag plus an hour in `1..=12` |
| `num_seconds_from_midnight()` | `-> Int` | Seconds since local midnight |
| `with_year(Int)` / `with_month(Int)` / `with_day(Int)` / `with_ordinal(Int)` / `with_hour(Int)` / `with_minute(Int)` / `with_second(Int)` / `with_nanosecond(Int)` | `-> MappedLocalTime[Self[Tz]]` | Replace one local component and re-resolve the wall-clock reading through the zone: `Absent` for an invalid value or a DST gap, `Ambiguous` inside a DST fold |
| `with_month0(Int)` / `with_day0(Int)` / `with_ordinal0(Int)` | `-> MappedLocalTime[Self[Tz]]` | 0-based counterparts of `with_month`/`with_day`/`with_ordinal`, resolved the same way |
| `with_time(NaiveTime)` | `-> MappedLocalTime[Self[Tz]]` | Replace the local time of day, keeping the local date, resolved the same way as the `with_*` setters |
| `timestamp()` / `timestamp_millis()` | `-> Int64` | Non-leap seconds / milliseconds since the Unix epoch, flooring toward negative infinity; independent of the zone |
| `timestamp_micros()` / `timestamp_nanos()` | `-> Int64?` | Microseconds / nanoseconds since the Unix epoch; `None` if the instant overflows `Int64` |
| `timestamp_subsec_nanos()` / `timestamp_subsec_millis()` / `timestamp_subsec_micros()` | `-> Int` | The sub-second component of the instant in that unit |
| `signed_duration_since(Self[Tz2])` | `-> TimeDelta` | The signed duration from `other` to `self`, independent of either's time zone |
| `is_dst()` | `-> Bool` | Whether daylight saving time is in effect at this instant (requires `Tz : TimeZone`) |
| `zone_bounds()` | `-> TransitionBounds` | The validity window of the offset in effect at this instant, either side `None` when unbounded (requires `Tz : TimeZone`); see `TransitionBounds` |
| `to_string()` (`Show`) | `-> String` | The local date-time and the zone's name at that instant joined by a space, e.g. `"2024-01-02 13:45:06.500 +09:00"`, `"... UTC"`, `"... EDT"` (requires `Tz : TimeZone`) |
| `years_since(Self[Tz])` | `-> Int?` | Full calendar years elapsed from `base`, comparing local dates and ignoring the time of day; `None` if `base` is later |
| `compare(Self[Tz])` / `<` / `>` / `<=` / `>=` | `-> Int` / `-> Bool` | Order by UTC instant, ignoring the zone value (requires `Tz : Eq`); equal instants in different zones compare as `0` yet are unequal under `==` (intentional: `==`/`Hash` also cover the zone; to test for the same instant, use `compare_instant(other) == 0`) |
| `compare_instant(Self[Tz2])` | `-> Int` | Order by UTC instant against a datetime in a different time zone type |
| `round(TimeDelta)` | `-> Result[Self[Tz], @core.RoundingError]` | Round the underlying UTC instant to the nearest multiple of a granularity since the Unix epoch, keeping the same time zone; see `TimeDelta::round` (in `core`) for which granularities are supported |
| `truncate(TimeDelta)` | `-> Result[Self[Tz], @core.RoundingError]` | Truncate the underlying UTC instant toward the Unix epoch; see Quick start above for how this differs from truncating the local presentation |
| `round_subsecs(Int)` / `truncate_subsecs(Int)` | `-> Result[Self[Tz], @core.RoundingError]` / `-> Self[Tz]` | Round or truncate the underlying UTC instant to a number of fractional-second digits (`0..=9`; other values abort) |

`DateTime[Tz]` also implements `Eq` (when `Tz : Eq`).

---

### `Location`

A time zone backed by parsed IANA tzdata (TZif binary format, plus a POSIX TZ string for extrapolating past the last recorded transition).

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Location::load(String)` | `-> Self?` | Look up an embedded IANA zone by name (e.g. `"Asia/Tokyo"`), following aliases; `None` if the name is unknown |
| `Location::from_tzif_bytes(Bytes)` | `-> Self?` | Parse a zone directly from raw TZif bytes; `None` if malformed |
| `Location::from_tzif_bytes_named(String, Bytes)` | `-> Self?` | Like `from_tzif_bytes`, but `name()` reports the given name; any text is accepted as given, without validation |
| `name()` | `-> String?` | The IANA identifier this `Location` was loaded with (the name as given to `Location::load`, not canonicalized through an alias); `None` for one built via `from_tzif_bytes` |
| `to_string()` (`Show`) | `-> String` | `name()`, or an empty string for a `Location` without one |
| `offset_from_abbreviation(String, NaiveDateTime)` | `-> FixedOffset?` | The offset an abbreviation (e.g. `"EST"`) denotes: that of the type in effect at the given UTC instant if it matches, else of the first type in the zone's table with that abbreviation; `None` if none has it |
| `type_at(NaiveDateTime)` | `-> LocalTimeType` | The offset, DST flag, and abbreviation in effect at a given UTC instant |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | The offset in effect at a given UTC instant |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | The offset(s) for a given local instant, resolving DST folds and gaps |
| `tz_name(NaiveDateTime)` | `-> String` | The abbreviation in effect at a given instant, e.g. `"EDT"` |
| `transition_bounds(NaiveDateTime)` | `-> TransitionBounds` | The validity window of the segment covering a given instant; see `TransitionBounds` |

`Location` also implements `TimeZone`. `==` is structural: two `Location`s are equal when their parsed TZif data, POSIX rule and `name()` all match, so an alias (e.g. `"Japan"`) is unequal to its canonical zone (`"Asia/Tokyo"`) even though both resolve identically. This also lets `DateTime[Location]` use `==` and the ordering operators.

### `TransitionBounds`

The validity window of a `Location`'s segment covering a given instant, as returned by `Location::transition_bounds`: the local time type `type_at` reports is in effect from `start()` (inclusive) until `end()` (exclusive). Mirrors Go's `Time.ZoneBounds`, using `Option` instead of a zero-value sentinel for "unbounded."

| Method | Signature | Description |
| :--- | :--- | :--- |
| `start()` | `-> NaiveDateTime?` | The instant this segment began; `None` if unbounded (before the zone's first recorded transition, or for a zone with no transitions at all) |
| `end()` | `-> NaiveDateTime?` | The instant the next segment begins; `None` if unbounded (past the zone's last recorded transition, when no POSIX rule extrapolates further) |

Past the last recorded transition, the POSIX rule's own bounds are computed exactly (not approximated near a year boundary, unlike Go's own `tzset`, which documents itself as doing so).

`TransitionBounds` also implements `Eq`.

### `LocalTimeType`

The offset, DST flag, and abbreviation for one segment of a `Location`'s timeline, as returned by `Location::type_at`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `LocalTimeType::new(Int, Bool, String)` | `-> Self` | Construct from UTC offset (seconds), DST flag, and abbreviation |
| `utc_offset()` | `-> Int` | UTC offset in seconds |
| `is_dst()` | `-> Bool` | Whether daylight saving is in effect |
| `abbreviation()` | `-> String` | The zone abbreviation, e.g. `"EST"`/`"EDT"` |

`LocalTimeType` also implements `Eq`.

### `Local` (native only)

The OS-configured local time zone, resolved from `$TZ` or, when unset, `/etc/localtime`. Only compiled for the `native` backend: resolving it requires file I/O that `js`/`wasm`/`wasm-gc` have no host-provided access to.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Local::new()` | `-> Self?` | Resolves the host's configured time zone; `None` if it could not be determined. Reads live OS state — not a pure function of its arguments. |
| `Local::resolve(String?, Bytes?)` | `-> Self?` | The pure resolution logic `new()` wraps: given the `TZ` environment variable and `/etc/localtime`'s bytes, applies POSIX `TZ` precedence (empty `TZ` → UTC, a named zone via `Location::load`, else a bare POSIX rule via `parse_posix_tz`; when `TZ` is unset, the given bytes via `Location::from_tzif_bytes`) |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | Delegates to the resolved zone |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime[FixedOffset]` | Delegates to the resolved zone |
| `tz_name(NaiveDateTime)` | `-> String` | Delegates to the resolved zone |

`Local` also implements `TimeZone`. `$TZ` may be an IANA zone name, an empty string (UTC), or a bare POSIX TZ rule such as `"JST-9"` or `"FOO5BAR4,M3.2.0,M11.1.0"`; an IANA name takes precedence when a string is both (e.g. `"EST5EDT"`). The leading-colon form (`":Asia/Tokyo"`) is not handled.

---

### Advanced: low-level TZif and POSIX TZ parsing

These back `Location` and are not usually needed directly; use `Location::load`/`from_tzif_bytes` unless building a custom zone-data pipeline.

| Symbol | Signature | Description |
| :--- | :--- | :--- |
| `parse_tzif(Bytes)` | `-> TzifData?` | Parse raw TZif bytes (header, transition table, local-time-type table, leap seconds, POSIX TZ footer) |
| `parse_posix_tz(String)` | `-> PosixTz?` | Parse a POSIX TZ rule string (all three date-rule forms: `Jn`, `n`, `Mm.w.d`) |
| `resolve_tzdata_bytes(Map[String, Bytes], Map[String, String], String)` | `-> Bytes?` | Resolve a zone name to its embedded TZif bytes, following an alias table |

| Type | Key methods | Description |
| :--- | :--- | :--- |
| `TzifData` | `transitions()`, `transition_types()`, `local_time_types()`, `leap_seconds()`, `posix_tz()` | The parsed contents of a TZif file |
| `PosixTz` | `type_at(Int64)`, `offset_at(Int64)`, `offset_from_local(NaiveDateTime)` | An evaluated POSIX TZ rule, for extrapolating past a TZif file's last recorded transition; also a `TimeZone` in its own right (a constant offset when the rule has no DST part, e.g. `JST-9`) |
