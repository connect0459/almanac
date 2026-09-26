# Chrono.mbt Implementation Plan

Reference target: **chrono/time**-equivalent functionality (calendar arithmetic, `Duration`/`Span` types, IANA timezone database support), studied from two reference implementations:

- the Rust `chrono` crate
- the Go standard library `time` package

## Architecture Decisions (confirmed with the user)

- **Package layout**: start coarse, three packages under `src/`, split further only when a package's file count or independent test surface justifies it:
  - `src/core` — `Weekday`, `Month`, `IsoWeek`, `NaiveDate`, `NaiveTime`, `TimeDelta`, `NaiveDateTime`, the day-count/leap-year algorithm
  - `src/tz` — `Offset`/`TimeZone` abstraction, `Utc`, `FixedOffset`, the TZif parser, embedded tzdata asset, `Location` lookup
  - `src/format` — strftime-style formatting and parsing engine
- **Timezone strategy**: not yet decided — gated on a spike (first task of Phase 6) confirming whether MoonBit has, or can be given, a mechanism for embedding a binary asset at compile time (Go `time/tzdata`-style). The embedded-only vs. embedded-plus-OS-read choice is made after that spike reports back, not before.
- **Format/parse design**: strftime-style `%`-specifier engine (chrono-style), not Go's reference-time-layout style. Rationale: a `%`-token scanner is simpler to implement correctly than reference-layout matching (which must disambiguate numeric substrings like `1` as month vs. day by position in the reference string).
- **Cross-package `moon.pkg` imports**: declared only when a package's code actually references the dependency (`tz` importing `core` at the start of Phase 5, `format` importing `core`/`tz` at the start of Phase 7), not upfront when the package layout is created. Rationale: `moon check --deny-warn` (used by `just verify`) treats an unused import as an error, so declaring a dependency before any symbol from it is used would break CI immediately.

## Phase 0: Project Setup

- [x] Establish `src/` as the library package (`connect0459/chrono`)
- [x] Define package layout — see Architecture Decisions above
- [ ] Discuss coverage targets and test strategy with the user before each phase below begins implementation (recurring gate, not a one-time task)
- [x] Create the `core`, `tz`, `format` sub-packages under `src/` (`moon.pkg` dependency declarations added per-phase as each package starts consuming another — see Architecture Decisions above)
- [x] Remove the placeholder `src/chrono.mbt`, `src/chrono_test.mbt`, `src/chrono_wbtest.mbt` once real packages exist

## Phase 1: Calendar Primitives (`src/core`)

Reference: `Weekday`/`Month` types, the naive-date internal algorithm module, Go's `time.go` (`dateToAbsDays`/`absDays.date`/`absDays.split`).

Coverage target (confirmed with the user): 100%. These are pure, low-branching functions (enums, leap-year predicate, day-count conversion), so full coverage is realistic; `moon coverage analyze` gaps block moving to Phase 2.

- [x] `Weekday` enum (Mon..Sun) with `succ`/`pred`, `number_from_monday`/`number_from_sunday` (1-based), `num_days_from_monday`/`num_days_from_sunday` (0-based), `days_since`
- [x] `Month` enum (Jan..Dec) with `succ`/`pred`, `number_from_month`, `name()`, `num_days(year)`
- [x] Leap-year predicate (`is_leap_year`, standard 4/100/400 rule)
- [x] Day-count ↔ (year, month, day) conversion using the Neri–Schneider closed-form algorithm (Go's approach — no static lookup table, prefer this over chrono's 400-entry `YearFlags` table for simpler porting)
- [x] `NaiveDate` value object: internal representation as a day count since an epoch (e.g. proleptic Gregorian day number)
- [x] `NaiveDate` constructors: `from_ymd`, `from_yo` (ordinal date), `from_isoywd` (ISO week date), all `Option`-returning for invalid input
- [x] `NaiveDate` accessors: `year`, `month`, `day`, `ordinal`, `weekday`, `iso_week`, `leap_year`
- [x] `NaiveDate` "with" methods (clamp-or-fail semantics, not silent clamp): `with_year`, `with_month`, `with_day`, `with_ordinal`
- [x] `NaiveDate` arithmetic: `succ`/`pred`, `add_days`/`sub_days`, `add_months`/`sub_months` (day-of-month clamped to the target month's length when it doesn't exist, e.g. Jan 31 + 1 month)
- [x] `IsoWeek` value object: `year`, `week`, `week0`
- [x] Tests: leap-year sweep across 4-, 100-, 400-year boundaries (1900 non-leap, 2000 leap, 2100 non-leap); `with_year` rejecting Feb 29 into a non-leap year; `with_month`/`with_day` across varying month lengths

## Phase 2: Time-of-Day (`src/core`)

Reference: chrono's naive time-of-day type.

Coverage target (confirmed with the user): 100%.

Implementation order note (confirmed with the user): `NaiveTime`'s day-overflow
arithmetic depends on `TimeDelta`, so Phase 3 was implemented first, and this
phase's arithmetic bullet was completed afterward using it.

- [x] `NaiveTime` value object: hour/minute/second/nanosecond, internal representation as seconds-since-midnight (`0..=86399`) plus a nanosecond component (`0..=1_999_999_999`, see leap-second note below)
- [x] Constructors: `from_hms`, `from_hms_milli`, `from_hms_micro`, `from_hms_nano`, `from_num_seconds_from_midnight`, all `Option`-returning
- [x] Accessors: `hour`, `minute`, `second`, `nanosecond`, `hour12`, `num_seconds_from_midnight`
- [x] Arithmetic with day overflow: `overflowing_add_signed`/`overflowing_sub_signed` against a `TimeDelta`, returning both the wrapped time and the number of days overflowed (chrono's `overflowing_add_signed` pattern) — needed by `NaiveDateTime` to carry day rollover
- [x] Leap seconds (confirmed with the user, full chrono-style support): representable via a nanosecond component `>= 1_000_000_000` at `second() == 59` (`second()` never reports `60`; use `nanosecond()` to detect it, matching chrono). Arithmetic rule (derived and confirmed with the user after finding the naive "always fold forward" approach was not monotonic): a zero `TimeDelta` returns the time unchanged, exactly preserving a leap second; any nonzero `TimeDelta` resolves the arithmetic assuming no day has a leap second, since `NaiveTime` has no calendar context to know which day actually has one — the leap second's extra elapsed second is treated as consumed once time moves away from it in either direction.
- [x] Tests: midnight/end-of-day boundary arithmetic, nanosecond precision round-trip, day-overflow reporting on add/sub, leap-second construction/accessors/arithmetic

## Phase 3: Duration (`src/core`)

Reference: chrono's `TimeDelta`, Go's `Duration`.

Coverage target (confirmed with the user): 100%.

- [x] `TimeDelta` value object: `{seconds: Int64, nanoseconds: Int}` (confirmed with the user — needed to cover `NaiveDate`'s existing day-count range, which a single `Int64` nanosecond count cannot). `nanoseconds` is always normalized to `0..=999_999_999`; sign is carried entirely by `seconds`. The representable `seconds` range is `±9_223_372_036_854_774` (`Int64::max_value / 1000`, with headroom): chosen so `num_milliseconds` always fits in `Int64` while still exceeding `NaiveDate`'s range by several orders of magnitude, and so the range is symmetric (making `abs`/`neg` total, never `Option`).
- [x] Constructors: `weeks`, `days`, `hours`, `minutes`, `seconds`, `milliseconds`, `microseconds`, `nanoseconds` — all uniformly `Option`-returning (diverges from this bullet's original "checked variant" phrasing in favor of the `Option`-everywhere convention already established by `NaiveDate` et al.)
- [x] Accessors: `num_weeks`, `num_days`, `num_hours`, `num_minutes`, `num_seconds`, `num_milliseconds`, `num_microseconds`, `num_nanoseconds`, `subsec_nanoseconds`/`subsec_milliseconds`/`subsec_microseconds`. `num_microseconds`/`num_nanoseconds` are `Option`-returning (can overflow `Int64` at the type's range boundaries); the rest are total.
- [x] Arithmetic: `add`, `sub`, `mul`, `div` (checked, `Option`-returning; `mul`/`div` take an `Int` scalar, matching chrono's own `i32`-scalar choice, which also keeps `div`'s remainder-folding arithmetic overflow-free), `abs`, `neg`, `is_zero`, `min_value`/`max_value`/`zero` (the latter group and `abs`/`neg` are total, not `Option`, given the symmetric range above)
- [x] Tests: overflow at range boundaries, sign handling for `abs`/negative durations, round-trip through each unit constructor

## Phase 4: Naive DateTime (`src/core`)

Reference: chrono's `NaiveDateTime`.

Coverage target (confirmed with the user): 100%.

- [x] `NaiveDateTime` value object composing `NaiveDate` + `NaiveTime`
- [x] Constructors: `new(date, time)` (total), `from_timestamp` (Unix seconds + nanos, `Option`-returning — nanos outside `0..=1_999_999_999` is rejected), `from_timestamp_millis`/`_micros`/`_nanos` (all `Option`-returning). Reuse the existing public `days_from_civil`/`civil_from_days` functions for the epoch-day conversion rather than adding a raw day-count constructor to `NaiveDate`'s public API.
- [x] Accessors: `date()`, `time()`, `timestamp()`, `timestamp_millis` (total — stays within `Int64` across `NaiveDate`'s full range), `timestamp_micros`/`timestamp_nanos` (`Option`-returning — can overflow `Int64` for a date far from the epoch, mirroring `TimeDelta::num_microseconds`/`num_nanoseconds`), `timestamp_subsec_nanos`/`_millis`/`_micros`
- [x] Arithmetic: `add_signed`/`sub_signed` (`TimeDelta`, propagating day overflow from `NaiveTime` into `NaiveDate`), `add_months`/`sub_months`, `add_days`/`sub_days`, `signed_duration_since` — all total (not `Option`): each composes operations already proven total on `NaiveDate`/`NaiveTime`, and `signed_duration_since`'s `TimeDelta` construction is proven to never overflow given `NaiveDate`'s much narrower day range than `TimeDelta`'s representable range.
- [x] Tests: arithmetic crossing a day boundary (both directions), arithmetic crossing a month/year boundary, `signed_duration_since` symmetry (`a.signed_duration_since(b) == b.signed_duration_since(a).neg()`)

## Phase 5: Offset & UTC (`src/tz`, part 1)

Reference: chrono's `Utc`/`FixedOffset`/`TimeZone`/`Offset` traits, Go's `Location`/`FixedZone`.

Coverage target (confirmed with the user): 100%.

`tz`'s dependency on `core` is now declared in `moon.pkg` (see Architecture Decisions above).

- [x] `TimeZone` abstract interface (MoonBit trait, no associated type — MoonBit traits don't have Rust-style associated types, so every implementor resolves directly to `FixedOffset` rather than to a per-implementor `Offset` type): given a naive datetime, resolve to a concrete UTC offset; represents the three DST-transition outcomes (single valid offset / ambiguous — DST fold / none — DST gap) via a monomorphic `MappedLocalTime` enum (`Single`/`Ambiguous`/`Absent`; `Absent` rather than chrono's `None` to avoid colliding with `Option`'s `None`), matching chrono's `MappedLocalTime`. `offset_from_utc` is plain (`FixedOffset`, never ambiguous — UTC has no daylight saving); `offset_from_local` returns `MappedLocalTime`.
- [x] `Utc` zero-sized implementation of `TimeZone`, always offset zero
- [x] `FixedOffset` implementation: constant offset in seconds, ±23:59:59 range, `east`/`west` constructors (`Option`-returning)
- [x] `DateTime[Tz]` wrapper generic over `Tz : TimeZone`: stores the UTC `NaiveDateTime` plus the `Tz` value; `offset()`/`naive_local()` are derived on demand (not stored redundantly), `with_timezone` re-expresses the same UTC instant in a different zone, and `add_signed`/`sub_signed`/`signed_duration_since` delegate to the inner naive datetime
- [x] Tests: `FixedOffset` range validation (reject offsets outside ±23:59:59), `DateTime<Utc>` arithmetic parity with plain `NaiveDateTime`

## Phase 6: IANA Timezone Database (`src/tz`, part 2)

Reference: chrono's local tz-info parser/rule modules, Go's TZif reader and its tzdata embed mechanism.

- [ ] Spike: confirm whether MoonBit has (or needs a build-step-generated) mechanism for shipping a binary blob alongside compiled code, equivalent to Go's `go:embed zoneinfo.zip` — this gates the timezone-strategy decision above
- [ ] TZif binary parser (v1/v2/v3): header (magic `"TZif"`, version byte, counts), local-time-type table (UTC offset, DST flag, abbreviation), transition-time table, transition → local-time-type index mapping, leap-second table (parsed for fidelity; not applied to civil arithmetic — matches Go's approach), POSIX TZ footer string for extrapolating past the last recorded transition
- [ ] `Location`/`TimeZone` type backed by parsed TZif data: resolve a Unix instant to `(offset, is_dst, abbreviation)`; resolve a naive datetime to an offset (mirrors Phase 5's `Offset` interface, producing the single/ambiguous/none result around DST transitions)
- [ ] Mock boundary: the embedded-asset *read* is the only external-boundary point (Detroit-school — everything else, including TZif parsing, is pure and tested with real byte buffers, not mocks)
- [ ] Tests: parse a real IANA zone's TZif bytes and assert known transition instants/offsets (e.g. a zone with DST vs. one without); DST gap and fold resolution at a real historical transition

## Phase 7: Formatting & Parsing (`src/format`)

Reference: chrono's strftime/parse/parsed modules.

- [ ] Format-string tokenizer: parse a `%`-specifier string into a sequence of literal/specifier items
- [ ] Formatting: render `NaiveDate`/`NaiveTime`/`NaiveDateTime`/`DateTime` against a token sequence — start with a minimal specifier set (date: `%Y %m %d %j %A %a`; time: `%H %M %S %f`; timezone: `%Z %z`; compound: `%F %T`), expand later phases as needed
- [ ] A hand-coded RFC 3339 fast path for both formatting and strict parsing, bypassing the general token engine (mirrors Go's dedicated RFC 3339 path — the common case shouldn't pay for full specifier interpretation)
- [ ] Parsing: walk the same token sequence against an input string, filling a partial/optional field accumulator, then resolve into a concrete date/time (reject inconsistent or incomplete fields)
- [ ] Tests: format → parse round-trip for each supported specifier combination; RFC 3339 fast-path output byte-identical to the general engine's output for the same instant; parse rejection of out-of-range/inconsistent fields

## Phase 8: Rounding & Truncation

Reference: chrono's `Round`/`SubsecRound` traits, Go's `Time.Round`/`Time.Truncate`/`Duration.Round`/`Duration.Truncate`.

- [ ] Round/truncate a `NaiveDateTime`/`DateTime` to an arbitrary `TimeDelta` granularity since the epoch (prefer Go's general single-`div`-helper approach over chrono's two-trait split — simpler, and not limited to decimal subsecond digits)
- [ ] Round/truncate a `TimeDelta` itself to a multiple of another `TimeDelta`
- [ ] Tests: half-value rounds away from zero; truncation always rounds toward the epoch; round/truncate by a duration larger than the value itself

## Phase 9: Documentation & Release Polish

- [ ] `README.mbt.md` per package: API reference tables, key types, usage examples (kept in sync with each phase as it lands, not deferred to the end)
- [ ] Run `moon info` after each phase; review the `.mbti` diff for unintended public-surface changes
- [ ] `moon fmt` and `pre-commit run --all-files` clean
- [ ] `just verify` green across `js`, `wasm`, `wasm-gc`, `native`
- [ ] Update the top-level `apm.yml`/`moon.mod` `description` and `keywords` once the public API stabilizes
