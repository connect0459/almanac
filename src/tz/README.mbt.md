# `tz` package

Time zone support layered on top of `core`'s `NaiveDateTime`. Import `connect0459/chrono/tz` for the `TimeZone` trait, `Utc`, `FixedOffset`, `DateTime[Tz]`, and `Location` (IANA tzdata lookup by zone name, e.g. `"America/New_York"`).

## Key types

| Type | Description |
| :--- | :--- |
| `TimeZone` (trait) | Resolves a `NaiveDateTime` to a UTC offset; implemented by `Utc`, `FixedOffset`, and `Location` |
| `MappedLocalTime` | The result of resolving a local (wall-clock) time: `Single`, `Ambiguous` (DST fold), or `Absent` (DST gap) |
| `Utc` | The UTC zone: always offset zero |
| `FixedOffset` | A constant UTC offset, `±23:59:59` |
| `DateTime[Tz]` | A `NaiveDateTime` paired with a time zone `Tz` |
| `Location` | A time zone backed by parsed IANA tzdata, resolving historical transitions and DST |

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

Implemented by `Utc`, `FixedOffset`, and `Location`. `DateTime[Tz]::offset`/`naive_local` require `Tz : TimeZone`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | The offset in effect at a given UTC instant; never ambiguous |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime` | The offset(s) for a given local (wall-clock) instant, handling DST ambiguity/gaps |
| `tz_name(NaiveDateTime)` | `-> String` | The zone abbreviation/name in effect at a given instant |

---

### `MappedLocalTime`

```mbt nocheck
///|
pub enum MappedLocalTime {
  Single(FixedOffset)
  Ambiguous(FixedOffset, FixedOffset) // a DST fold: two valid offsets
  Absent // a DST gap: no valid offset
}
```

`Utc` and `FixedOffset` only ever produce `Single` (neither has daylight saving). A `Location` can produce all three around a real DST transition: `Ambiguous` when a local clock reading occurs twice (the fold at the end of DST), and `Absent` when a local clock reading never occurs (the gap at the start of DST).

`MappedLocalTime` also implements `Eq`.

---

### `Utc`

The UTC zone, always offset zero.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Utc::new()` | `-> Self` | Construct the (zero-sized) UTC zone value |
| `Utc::now()` | `-> DateTime[Utc]` | The current UTC instant, read from the host's wall clock. Unlike every other function in this package, not a pure function of its arguments. |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | Always `FixedOffset::east(0)` |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime` | Always `Single(FixedOffset::east(0))` |
| `tz_name(NaiveDateTime)` | `-> String` | Always `"UTC"` |

`Utc` also implements `Eq` and `TimeZone`.

---

### `FixedOffset`

A constant UTC offset, in seconds, within `±23:59:59`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `FixedOffset::east(Int)` | `-> Self?` | An offset east of UTC by the given seconds; `None` outside `±23:59:59` |
| `FixedOffset::west(Int)` | `-> Self?` | An offset west of UTC by the given seconds (negated internally); same range |
| `local_minus_utc()` | `-> Int` | The offset in seconds (negative for a western offset) |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | Returns `self`, unchanged, regardless of the given instant |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime` | Always `Single(self)` |
| `tz_name(NaiveDateTime)` | `-> String` | Colon-separated sign, hour, and minute, e.g. `"+09:00"`; extended with a seconds component for a non-whole-minute offset, e.g. `"-04:56:02"` |

`FixedOffset` also implements `Eq` and `TimeZone`.

---

### `DateTime[Tz]`

A `NaiveDateTime` paired with a time zone `Tz`. The UTC instant is stored directly; the local (wall-clock) representation is derived on demand.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `DateTime::from_utc(NaiveDateTime, Tz)` | `-> Self[Tz]` | Wrap a UTC naive datetime with the given time zone |
| `naive_utc()` | `-> NaiveDateTime` | The underlying naive datetime, in UTC |
| `timezone()` | `-> Tz` | The time zone value this datetime is expressed in |
| `offset()` *(Tz : TimeZone)* | `-> FixedOffset` | The UTC offset in effect at this instant |
| `naive_local()` *(Tz : TimeZone)* | `-> NaiveDateTime` | The UTC datetime shifted by `offset()` |
| `with_timezone(Tz2)` | `-> Self[Tz2]` | Re-express this datetime in `Tz2`, keeping the same UTC instant |
| `add_signed(TimeDelta)` | `-> Self[Tz]` | Advance by a signed duration, keeping the same time zone |
| `sub_signed(TimeDelta)` | `-> Self[Tz]` | Move back by a signed duration |
| `signed_duration_since(Self[Tz2])` | `-> TimeDelta` | The signed duration from `other` to `self`, independent of either's time zone |
| `round(TimeDelta)` | `-> Self[Tz]?` | Round the underlying UTC instant to the nearest multiple of a granularity since the Unix epoch, keeping the same time zone; see `TimeDelta::round` (in `core`) for which granularities are supported |
| `truncate(TimeDelta)` | `-> Self[Tz]?` | Truncate the underlying UTC instant toward the Unix epoch; see Quick start above for how this differs from truncating the local presentation |

`DateTime[Tz]` also implements `Eq` (when `Tz : Eq`).

---

### `Location`

A time zone backed by parsed IANA tzdata (TZif binary format, plus a POSIX TZ string for extrapolating past the last recorded transition).

| Method | Signature | Description |
| :--- | :--- | :--- |
| `Location::load(String)` | `-> Self?` | Look up an embedded IANA zone by name (e.g. `"Asia/Tokyo"`), following aliases; `None` if the name is unknown |
| `Location::from_tzif_bytes(Bytes)` | `-> Self?` | Parse a zone directly from raw TZif bytes; `None` if malformed |
| `type_at(NaiveDateTime)` | `-> LocalTimeType` | The offset, DST flag, and abbreviation in effect at a given UTC instant |
| `offset_from_utc(NaiveDateTime)` | `-> FixedOffset` | The offset in effect at a given UTC instant |
| `offset_from_local(NaiveDateTime)` | `-> MappedLocalTime` | The offset(s) for a given local instant, resolving DST folds and gaps |
| `tz_name(NaiveDateTime)` | `-> String` | The abbreviation in effect at a given instant, e.g. `"EDT"` |

`Location` also implements `TimeZone`.

### `LocalTimeType`

The offset, DST flag, and abbreviation for one segment of a `Location`'s timeline, as returned by `Location::type_at`.

| Method | Signature | Description |
| :--- | :--- | :--- |
| `LocalTimeType::new(Int, Bool, String)` | `-> Self` | Construct from UTC offset (seconds), DST flag, and abbreviation |
| `utc_offset()` | `-> Int` | UTC offset in seconds |
| `is_dst()` | `-> Bool` | Whether daylight saving is in effect |
| `abbreviation()` | `-> String` | The zone abbreviation, e.g. `"EST"`/`"EDT"` |

`LocalTimeType` also implements `Eq`.

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
| `PosixTz` | `type_at(Int64)`, `offset_at(Int64)`, `offset_from_local(NaiveDateTime)` | An evaluated POSIX TZ rule, for extrapolating past a TZif file's last recorded transition |
