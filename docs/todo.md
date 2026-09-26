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
- [ ] `NaiveDate` "with" methods (clamp-or-fail semantics, not silent clamp): `with_year`, `with_month`, `with_day`, `with_ordinal`
- [ ] `NaiveDate` arithmetic: `succ`/`pred`, `add_days`/`sub_days`, `add_months`/`sub_months` (day-of-month clamped to the target month's length when it doesn't exist, e.g. Jan 31 + 1 month)
- [x] `IsoWeek` value object: `year`, `week`, `week0`
- [ ] Tests: leap-year sweep across 4-, 100-, 400-year boundaries (1900 non-leap, 2000 leap, 2100 non-leap); `with_year` rejecting Feb 29 into a non-leap year; `with_month`/`with_day` across varying month lengths

## Phase 2: Time-of-Day (`src/core`)

Reference: chrono's naive time-of-day type.

- [ ] `NaiveTime` value object: hour/minute/second/nanosecond, internal representation as nanoseconds-since-midnight (or seconds + nanos)
- [ ] Constructors: `from_hms`, `from_hms_milli`, `from_hms_micro`, `from_hms_nano`, `from_num_seconds_from_midnight`, all `Option`-returning
- [ ] Accessors: `hour`, `minute`, `second`, `nanosecond`, `hour12`
- [ ] Arithmetic with day overflow: `add_signed`/`sub_signed` against a `TimeDelta`, returning both the wrapped time and the number of days overflowed (chrono's `overflowing_add_signed` pattern) — needed by `NaiveDateTime` to carry day rollover
- [ ] Decide whether leap seconds (second value 60) are representable at this layer; if not, document why and where the constraint is enforced
- [ ] Tests: midnight/end-of-day boundary arithmetic, nanosecond precision round-trip, day-overflow reporting on add/sub

## Phase 3: Duration (`src/core`)

Reference: chrono's `TimeDelta`, Go's `Duration`.

- [ ] `TimeDelta` value object: signed duration, `{seconds, nanoseconds}` or a single `i64` nanosecond count — decide range needed (chrono uses `i64` seconds + `u32` nanos to exceed a pure-nanosecond `i64`'s range; confirm whether this project needs that range before choosing)
- [ ] Constructors: `weeks`, `days`, `hours`, `minutes`, `seconds`, `milliseconds`, `microseconds`, `nanoseconds`, each with a checked (`Option`-returning) variant
- [ ] Accessors: `num_weeks`, `num_days`, `num_hours`, `num_minutes`, `num_seconds`, `num_milliseconds`, `num_microseconds`, `num_nanoseconds`, `subsec_*`
- [ ] Arithmetic: `add`, `sub`, `mul`, `div` (checked, `Option`-returning), `abs`, `is_zero`, `min_value`/`max_value`/`zero`
- [ ] Tests: overflow at range boundaries, sign handling for `abs`/negative durations, round-trip through each unit constructor

## Phase 4: Naive DateTime (`src/core`)

Reference: chrono's `NaiveDateTime`.

- [ ] `NaiveDateTime` value object composing `NaiveDate` + `NaiveTime`
- [ ] Constructors: `new(date, time)`, `from_timestamp` (Unix seconds + nanos), `from_timestamp_millis`/`_micros`/`_nanos`
- [ ] Accessors: `date()`, `time()`, `timestamp()`, `timestamp_millis`/`_micros`/`_nanos`, `timestamp_subsec_*`
- [ ] Arithmetic: `add_signed`/`sub_signed` (`TimeDelta`, propagating day overflow from `NaiveTime` into `NaiveDate`), `add_months`/`sub_months`, `add_days`/`sub_days`, `signed_duration_since`
- [ ] Tests: arithmetic crossing a day boundary (both directions), arithmetic crossing a month/year boundary, `signed_duration_since` symmetry (`a.signed_duration_since(b) == -b.signed_duration_since(a)`)

## Phase 5: Offset & UTC (`src/tz`, part 1)

Reference: chrono's `Utc`/`FixedOffset`/`TimeZone`/`Offset` traits, Go's `Location`/`FixedZone`.

- [ ] `Offset`/`TimeZone` abstract interface (MoonBit trait): given a naive datetime, resolve to a concrete UTC offset; must be able to represent the three DST-transition outcomes (single valid offset / ambiguous — DST fold / none — DST gap), matching chrono's `MappedLocalTime`
- [ ] `Utc` zero-sized implementation of the offset interface
- [ ] `FixedOffset` implementation: constant offset in seconds, ±23:59:59 range, `east`/`west` constructors
- [ ] `DateTime` wrapper generic over an offset-provider: `NaiveDateTime` + resolved offset, `with_timezone`, delegates arithmetic to the inner naive datetime
- [ ] Tests: `FixedOffset` range validation (reject offsets outside ±23:59:59), `DateTime<Utc>` arithmetic parity with plain `NaiveDateTime`

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
