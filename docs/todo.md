# Chrono.mbt Implementation Plan

Reference target: **chrono/time**-equivalent functionality (calendar arithmetic, `Duration`/`Span` types, IANA timezone database support), studied from two reference implementations:

- the Rust `chrono` crate
- the Go standard library `time` package

## Architecture Decisions (confirmed with the user)

- **Package layout**: start coarse, three packages under `src/`, split further only when a package's file count or independent test surface justifies it:
  - `src/core` — `Weekday`, `Month`, `IsoWeek`, `NaiveDate`, `NaiveTime`, `TimeDelta`, `NaiveDateTime`, the day-count/leap-year algorithm
  - `src/tz` — `Offset`/`TimeZone` abstraction, `Utc`, `FixedOffset`, the TZif parser, embedded tzdata asset, `Location` lookup
  - `src/format` — strftime-style formatting and parsing engine
- **Timezone strategy** (confirmed with the user after the Phase 6 spike): full IANA tzdata embedding, Go `time/tzdata`-style, via a standalone `scripts/gen_tzdata.py` that codegens `src/tz/tzdata_generated.mbt` as a `Bytes` array literal per zone (`([0xAA, 0xBB, ...] : Bytes)`), invoked manually (`just gen-tzdata <zoneinfo dir>`), not on every build. A feasibility spike first measured this scale (macOS `/var/db/timezone/zoneinfo`, 604 zones, ~840KB raw binary → ~5.2MB generated source) at ~1 second to `moon build`/`moon check --deny-warn` from a cold build on each of `native`/`wasm-gc`/`js` — no need for a more compact encoding (e.g. base64 + runtime decode). Implementation order: the TZif parser and `Location` type were implemented first against a handful of hand-picked real zones (as test fixtures); the codegen script embedding the full database came after, as a separate step within Phase 6.
  - **Correction found after this was first written**: MoonBit *does* have a native compile-time asset-embedding mechanism after all — `moon tool embed --binary` (invocable per-file from a package's `moon.pkg` via an `options."pre-build"` `":embed"` entry, as demonstrated by e.g. `connect0459/starlark-mbt`'s `src/internal/starlarktest/moon.pkg`). The original spike missed it by checking only `moon build --help`/`moonc --help`, not `moon tool --help`'s subcommands. Re-checked at the same 598-zone scale before deciding whether to switch: pre-build `:embed` outputs must live in the same package directory as the `moon.pkg` that declares them (no subdirectories), so using it here would mean restructuring the embedded zones into their own sub-package with 598 individual `.tzif` files plus a 598-entry generated `moon.pkg`, and it measured ~7x slower to build (~7s vs. ~1s) than the single-generated-file approach already implemented and tested. Kept the existing script-generated single file rather than switching, given it already works, is simpler structurally, and builds faster; a future switch to the native mechanism remains straightforward if those tradeoffs change.
- **Format/parse design**: strftime-style `%`-specifier engine (chrono-style), not Go's reference-time-layout style. Rationale: a `%`-token scanner is simpler to implement correctly than reference-layout matching (which must disambiguate numeric substrings like `1` as month vs. day by position in the reference string).
- **Cross-package `moon.pkg` imports**: declared only when a package's code actually references the dependency (`tz` importing `core` at the start of Phase 5, `format` importing `core`/`tz` at the start of Phase 7), not upfront when the package layout is created. Rationale: `moon check --deny-warn` (used by `just verify`) treats an unused import as an error, so declaring a dependency before any symbol from it is used would break CI immediately.
- **`TimeZone` trait gained a `tz_name` method** (confirmed with the user during Phase 7), so `format`'s `DateTime[Tz]` rendering can support `%Z` generically across every implementor: `Utc` → `"UTC"`, `FixedOffset` → its own offset string (`"+09:00"`, colon-separated, extended to `"+09:00:30"` for a non-whole-minute historical offset — mirrors chrono's `FixedOffset` `Display`), `Location` → the IANA abbreviation in effect at that instant (via the existing `type_at`). `%z` is rendered independently in `format` from the same offset, in strftime's plain `+HHMM` form (no colon, no sub-minute seconds) — distinct from `FixedOffset::tz_name`'s colon form, since `%z` and `%Z` are different specifiers with different conventional formats.

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

- [x] Spike: confirm whether MoonBit has (or needs a build-step-generated) mechanism for shipping a binary blob alongside compiled code, equivalent to Go's `go:embed zoneinfo.zip` — this gates the timezone-strategy decision above. Result: no native mechanism; a generated `Bytes`-literal source file, measured feasible at full-tzdata scale. See the Timezone strategy entry in Architecture Decisions above.
- [x] TZif binary parser (v1/v2/v3): header (magic `"TZif"`, version byte, counts), local-time-type table (UTC offset, DST flag, abbreviation), transition-time table, transition → local-time-type index mapping, leap-second table (parsed for fidelity; not applied to civil arithmetic — matches Go's approach), POSIX TZ footer string for extrapolating past the last recorded transition. Also includes a full POSIX TZ string parser/evaluator (`PosixTz`, all three date rule formats: `Jn`, `n`, `Mm.w.d`), confirmed with the user rather than deferring extrapolation.
- [x] `Location`/`TimeZone` type backed by parsed TZif data: resolve a Unix instant to `(offset, is_dst, abbreviation)` via `type_at` (offset alone via `offset_from_utc`, the `TimeZone` trait method); resolve a naive datetime to an offset via `offset_from_local`, producing the single/ambiguous/none result around DST transitions (mirrors Phase 5's `TimeZone` interface). Before the first recorded transition, uses RFC 8536's rule (first non-DST type, else the first type); past the last one, delegates to the POSIX rule when present, else clamps to the last transition's type (matching a version-1-only file's behavior, which has no POSIX footer to fall back on).
- [x] Mock boundary: the embedded-asset *read* is the only external-boundary point (Detroit-school — everything else, including TZif parsing, is pure and tested with real byte buffers, not mocks). In practice this phase never needed an embedded asset at all yet — see the codegen/embedding follow-up note below.
- [x] Tests: parse a real IANA zone's TZif bytes and assert known transition instants/offsets (a DST zone, America/New_York, vs. a non-DST one, Asia/Tokyo/UTC); DST gap and fold resolution at a real historical transition, including a fold in a positive-offset zone (Australia/Sydney) to cover the case a negative-offset zone's test can't reach. Local-time resolution is done by checking whether each of a transition's three neighboring segments is truly a valid candidate (converting the local reading back to UTC via that segment's own offset must land within that segment's own range) rather than trusting a first-guess lookup — an earlier version that only checked the segment immediately before/after a naive guess got an exact post-gap boundary wrong.

- [x] Follow-up: `scripts/gen_tzdata.py` codegens `src/tz/tzdata_generated.mbt`, embedding the full IANA tzdata (per the Architecture Decisions entry above, including the native-`:embed`-mechanism correction found while doing this). `Location::load(name)` looks a zone up by name (following aliases) and constructs it via `Location::from_tzif_bytes`; `just gen-tzdata <zoneinfo dir>` re-runs the script. `Location::from_tzif_bytes` and everything else in this phase already worked against caller-supplied bytes regardless, so this was purely a shipping/convenience concern layered on top, not a prerequisite for anything above.

## Phase 7: Formatting & Parsing (`src/format`)

Reference: chrono's strftime/parse/parsed modules.

Coverage target (confirmed with the user): 100%.

- [x] Format-string tokenizer: parse a `%`-specifier string into a sequence of literal/specifier items
- [x] Formatting: render `NaiveDate`/`NaiveTime`/`NaiveDateTime`/`DateTime[Tz]` against a token sequence — start with a minimal specifier set (date: `%Y %m %d %j %A %a`; time: `%H %M %S %f`; timezone: `%Z %z`; compound: `%F %T`), expand later phases as needed. `format_date`/`format_time`/`format_date_time` raise `MissingField` for `%Z`/`%z` (no zone to draw from); `format_date_time_tz` (generic over `Tz : TimeZone`, added along with `TimeZone::tz_name` — see Architecture Decisions above) renders both.
- [x] A hand-coded RFC 3339 fast path for both formatting and strict parsing, bypassing the general token engine (mirrors Go's dedicated RFC 3339 path — the common case shouldn't pay for full specifier interpretation). `to_rfc3339` (generic over `Tz : TimeZone`, total — never raises) renders `YYYY-MM-DDTHH:MM:SS[.fraction](Z|±HH:MM)`: a zero offset as `Z` (confirmed with the user), fractional seconds only when nonzero and with trailing zeros trimmed (confirmed with the user — chrono/Go's `RFC3339Nano` convention, not a fixed 9 digits), and a leap second as `:60` (reusing `NaiveTime`'s existing `second() + nanosecond() / 1_000_000_000` convention). `parse_rfc3339` is a hand-written positional scanner (mirrors `posix_tz.mbt`'s `(chars, pos) -> (value, newPos)?` threading style rather than the general tokenizer), strict per RFC 3339 (`T`/`t` and `Z`/`z` case-insensitive per the grammar; a fractional-second field beyond 9 digits is truncated, not rejected; all range validation delegates to `NaiveDate`/`NaiveTime`/`FixedOffset`'s own constructors rather than re-validating in the parser), returning `DateTime[FixedOffset]` and raising the `ParseError` suberror's new `InvalidRfc3339` variant (a single catch-all, not per-field detail — narrower than the general parsing engine's future error reporting) on any mismatch.
- [x] Parsing: walk the same token sequence against an input string, filling a partial/optional field accumulator, then resolve into a concrete date/time (reject inconsistent or incomplete fields). `parse_date`/`parse_time`/`parse_date_time`/`parse_date_time_tz` share a private `Parsed` accumulator (all fields `Option`, merged via a generic `merge_field` that raises on disagreement between two occurrences of the same field, e.g. a duplicate specifier or a redundant `%j` alongside `%m`/`%d`) and a position-threading walker (`(items, input) -> Parsed`, mirroring `rfc3339.mbt`/`posix_tz.mbt`'s style over the general tokenizer's `Item` sequence rather than reference-layout matching). `%Y` is the only variable-width numeric field (greedy, optionally signed); every other numeric specifier parses exactly its render width. `%Z` always raises `InputMismatch` when parsed — mirrors chrono's own documented behavior, since a zone name has no generically parseable shape. All range/consistency validation (invalid calendar dates, out-of-range hour, mismatched weekday, out-of-range offset magnitude) delegates to `NaiveDate`/`NaiveTime`/`FixedOffset`'s own constructors rather than re-validating in the parser, reported as the new `IncompleteFields` (a required field was never populated) and `InconsistentFields` (two populated fields disagree, or don't jointly form a valid value) `ParseError` variants alongside `InputMismatch` (literal/specifier text didn't match).
- [x] Tests: format → parse round-trip for each supported specifier combination; RFC 3339 fast-path output byte-identical to the general engine's output for the same instant; parse rejection of out-of-range/inconsistent fields

## Phase 8: Rounding & Truncation

Reference: chrono's `Round`/`SubsecRound` traits, Go's `Time.Round`/`Time.Truncate`/`Duration.Round`/`Duration.Truncate`.

Coverage target (confirmed with the user): 100%.

Design decisions (confirmed with the user before implementation):

- **Reference point**: the Unix epoch (`1970-01-01T00:00:00`), not Go's year-1 zero time — consistent with this codebase's existing `timestamp()` family, unlike Go's `Time` internal representation. `NaiveDateTime::round`/`truncate` compute the `TimeDelta` since the epoch via the already-total `signed_duration_since`/`add_signed`, rather than converting through `timestamp_nanos()` (which is `Option`-returning and can overflow for a date far from the epoch) — this keeps the date side of rounding/truncation free of spurious overflow.
- **`granularity` is restricted to two shapes**: purely sub-second (a whole number of nanoseconds, no whole-second component) or a whole-second-or-larger multiple (no sub-second remainder). A "mixed" granularity (e.g. 1.5 seconds) returns `None`. Rationale: `TimeDelta`'s `seconds` component is far too large to convert to a single nanosecond count in the general case (mirrors why `num_nanoseconds` is already `Option`-returning), and supporting arbitrary mixed granularities in general would require arbitrary-precision arithmetic (Go's own `Duration`-vs-`Time` general case falls back to manual 128-bit arithmetic for exactly this reason). Every named duration unit (ns/µs/ms/s/min/hour/day/week/...) falls into one of the two supported shapes, so this is not a practical limitation.
- **Invalid `granularity` (zero or negative) returns `None`**, not Go's silent no-op passthrough — consistent with this codebase's existing `TimeDelta::div` convention of rejecting invalid input via `Option` rather than a silent identity result.
- **Half-value ties round away from zero** (matches Go's `Duration.Round`); **truncation always rounds toward zero/the epoch**, never toward negative infinity — verified explicitly for a pre-epoch `NaiveDateTime`, where truncating moves the datetime *forward* in time.
- **`DateTime[Tz]::round`/`truncate` operate on the underlying UTC instant**, not the offset-shifted local presentation (matches Go's and chrono's documented behavior): truncating to an hour boundary in UTC may still report a non-zero local minute under a non-whole-hour `FixedOffset`.

- [x] Round/truncate a `NaiveDateTime`/`DateTime` to an arbitrary `TimeDelta` granularity since the epoch (prefer Go's general single-`div`-helper approach over chrono's two-trait split — simpler, and not limited to decimal subsecond digits)
- [x] Round/truncate a `TimeDelta` itself to a multiple of another `TimeDelta`
- [x] Tests: half-value rounds away from zero; truncation always rounds toward the epoch; round/truncate by a duration larger than the value itself

## Phase 9: Documentation & Release Polish

- [x] `README.mbt.md` per package: API reference tables, key types, usage examples (kept in sync with each phase as it lands, not deferred to the end)
- [x] Run `moon info` after each phase; review the `.mbti` diff for unintended public-surface changes
- [x] `moon fmt` and `pre-commit run --all-files` clean
- [x] `just verify` green across `js`, `wasm`, `wasm-gc`, `native`
- [x] Update the top-level `moon.mod` `description` and `keywords` once the public API stabilizes (`apm.yml` is the unrelated APM/skills tool manifest for this repo, not the library's registry metadata — left as-is)

## Phase 10: API Surface Gap Follow-ups

Reference: a feature-level gap survey against the Rust `chrono` crate and Go's `time` package (see `CLAUDE.local.md` for where the reference implementations are kept locally), covering all three packages (`src/core`, `src/tz`, `src/format`).

Two items originally required a design decision before any implementation work started, since they touch this library's core design premise that every operation is a pure function of caller-supplied instants, with no hidden wall-clock or OS access. Both are now resolved (confirmed with the user):

- [x] **Design decision (resolved)**: `Utc::now()` is added. The original premise ("`native` has OS clock access; `js`/`wasm-gc` do not") was checked against `moonbitlang/core`'s actual sources (`~/.moon/lib/core/env`) and found to be wrong: `@env.now()` (ms since the Unix epoch) is implemented symmetrically across all four backends (`native` via C FFI, `js` via `Date.now()`, `wasm`/`wasm-gc` via the `__moonbit_time_unstable` host import). `Utc::now() -> DateTime[Utc]` is implemented in its own file (`src/tz/now.mbt`), isolated from the package's otherwise-pure functions, wrapping `@env.now()`.
- [x] **Design decision (resolved)**: `Local` is added, scoped to `native` only. Unlike `now()`, a real asymmetry does exist here: `$TZ` is readable symmetrically via `@env.get_env_var`, but reading the `/etc/localtime` fallback (the common case when `$TZ` is unset) requires file I/O, which `moonbitlang/core` does not provide on any backend — `native` can add its own C stub (`native-stub` in `moon.pkg`, confirmed as a real MoonBit mechanism), but `js`/`wasm-gc` cannot without a host-provided file-read import that doesn't exist. `Local` is therefore compiled only for `native` (via `moon.pkg`'s per-file `targets`, the same mechanism `moonbitlang/core/bench`'s `monotonic_clock_*.mbt` uses), not present at all on other backends. Scoped to `$TZ` as an IANA zone name (via `Location::load`) falling back to `/etc/localtime` bytes (via `Location::from_tzif_bytes`); a bare POSIX rule string in `$TZ` (e.g. `EST5EDT`) is out of scope for this item — see the `PosixTz`-as-`TimeZone` item below, which would need to land first.

Coverage target: 100%, consistent with Phase 1–8 (confirmed with the user), except for the thin OS-facing shim functions (`Utc::now()`, `Local::new()`) which read live host state and are covered only by a sanity check, not exhaustive branch coverage — the resolution logic itself is factored into pure, fully-covered functions tested with fixture data (`Local::resolve`).

### `src/core`

- [x] `WeekdaySet`: bitset of `Weekday` values (`from_array`, `single`, `insert`/`remove`/`contains`, subset checks, `first`/`last`, iteration) — mirrors chrono's `weekday_set.rs`. Deviates from chrono in two confirmed ways: `insert`/`remove` are pure (return a new `WeekdaySet` instead of mutating `self` and reporting a `Bool`, matching this project's Immutable First principle), and iteration is a fixed `Mon..Sun`-order `to_array()` rather than chrono's `start`-day, bidirectional `WeekdaySetIter` (not called for by this bullet's own wording, and MoonBit has no native double-ended iterator to model it on)
- [x] Ordering/comparison (`compare`/`<`/`<=`/etc.) on `NaiveDate`, `NaiveTime`, `NaiveDateTime`, `TimeDelta`, `IsoWeek`. Each type's existing field layout already matches chronological/magnitude order lexicographically (e.g. `TimeDelta`'s `(seconds, nanoseconds)` with the sign carried entirely by `seconds`), so `derive(Compare)` alone (plus the same `pub extend X with Compare::{compare, op_lt, op_gt, op_le, op_ge}` pattern already used for `Eq`) is correct without a hand-written `compare`
- [x] `NaiveWeek`: "the week containing this date," parameterized by a configurable first-day-of-week, exposing `first_day()`/`last_day()`/a days range — distinct from `IsoWeek`. `NaiveDate::week(start)` constructs it (mirrors chrono's `NaiveDate::week`). Two confirmed deviations from chrono: since this project's `NaiveDate::add_days` is already total (not `Option`-returning, unlike chrono's range-limited `checked_add_days`), `first_day()`/`last_day()` are total too — no `checked_first_day()`/panicking-`first_day()` split is needed; and the days range is `days() -> Array[NaiveDate]` (all seven dates) rather than chrono's `RangeInclusive<NaiveDate>`, since MoonBit has no generic range type and this project's own lazy `iter_days` (see below) doesn't exist yet. `Eq`/`Compare` are hand-implemented (not `derive`d) to match chrono's semantics: equal/ordered by `first_day()` alone, not full-field equality — confirmed with the user as a deliberate exception to this project's usual `derive(Eq, Compare)` pattern, and this project also adds `Compare` (chrono only has `Eq`), consistent with every other value type getting ordering in this phase
- [ ] `NaiveTime` component setters: `with_hour`/`with_minute`/`with_second`/`with_nanosecond`, mirroring `NaiveDate`'s existing `with_year`/`with_month`/`with_day`/`with_ordinal`
- [ ] `NaiveTime::signed_duration_since`: time-of-day-only duration difference (no day carry), distinct from the existing `NaiveDateTime` version
- [ ] `NaiveDate::years_since(base)`: full elapsed calendar years between two dates
- [ ] `iter_days`/`iter_weeks`: lazy iterator of successive dates from a starting `NaiveDate`
- [ ] `NaiveDate::from_weekday_of_month`: construct e.g. "3rd Monday of March 2024"
- [ ] Float-based `TimeDelta` accessors: `as_seconds_f64`/`as_seconds_f32`-equivalents alongside the existing integer `num_*` accessors
- [ ] `NaiveDate::quarter()`: 1..=4 quarter number

### `src/tz`

- [ ] `MappedLocalTime` combinators: `.single()`/`.earliest()`/`.latest()`/`.map()`-equivalents, so callers don't have to hand-write a pattern match every time
- [ ] `TimeZone`-mediated `DateTime[Tz]` construction: build from local y/m/d/h/m/s or from a Unix timestamp through a given zone (resolving DST ambiguity via `MappedLocalTime`), not just `DateTime::from_utc` wrapping an already-UTC naive datetime
- [ ] `DateTime[Tz]` calendar arithmetic: expose `add_months`/`sub_months`/`add_days`/`sub_days` (already on `NaiveDateTime`) without requiring the caller to manually unwrap to `naive_utc()` and rebuild
- [ ] `Location` zone-identifier accessor: return the loaded IANA name (e.g. `"Asia/Tokyo"`), distinct from the existing instant-specific abbreviation (`"JST"`) returned by `tz_name`
- [ ] `Location` transition-boundary query: expose the validity window (start/end) of the segment covering a given instant, mirroring Go's `Location.Lookup` — the underlying transition table already exists in `TzifData`
- [x] `Local`: OS-configured local timezone lookup, `native`-only. Resolution logic (`Local::resolve`) is a pure function of `$TZ` and `/etc/localtime`'s bytes, tested with fixture data; `Local::new()` is the thin OS-facing shim (reads `$TZ` via `@env.get_env_var` and `/etc/localtime` via a native C stub, `local_native_stub.c`, declared through `moon.pkg`'s `native-stub`), covered only by a sanity check. Known tool limitation found while verifying coverage: `moon coverage analyze` reports every line in a `moon.pkg` `targets`-gated file (e.g. `local.mbt`, `local_native.mbt`) as uncovered regardless of actual test execution — confirmed by A/B testing (moving the `extern "C"` declaration to its own file did not change the result); `Local::resolve`'s branch coverage was instead verified by manual trace against `local_test.mbt`'s five cases (empty `TZ`, valid `TZ` name, invalid `TZ` name, `TZ` unset with/without `/etc/localtime` bytes) and `local_native_test.mbt`'s one sanity case.

### `src/format`

- [ ] Specifiers wired to already-existing `core`/`tz` primitives (low cost): `%b`/`%B`/`%h` (month name, via `Month::name()`), `%I`/`%l`/`%P`/`%p` (12-hour clock, via `NaiveTime::hour12()`), `%s` (Unix timestamp, via `timestamp()`), `%G`/`%g`/`%V` (ISO week-date, via `IsoWeek`)
- [ ] Remaining year/day/weekday/week-number specifiers: `%C`, `%y`, `%q`, `%e`, `%w`, `%u`, `%U`, `%W`
- [ ] Compound specifiers: `%D`, `%x`, `%v`, `%R`, `%X`, `%r`, `%c`, `%+`
- [ ] Variable-width/dot-prefixed fractional seconds: `%.f`, `%3f`, `%6f`, `%9f` (only the fixed 9-digit `%f` exists today)
- [ ] TZ colon-offset variants: `%:z`, `%::z`, `%:::z`, `%#z` (only bare `%z` exists today)
- [ ] Padding-flag modifiers: `%-?`/`%_?`/`%0?`
- [ ] RFC 2822 fast path: `to_rfc2822`/`parse_from_rfc2822`, mirroring the existing RFC 3339 fast path
- [ ] Named convenience format-string constants (Go-style `RFC1123`/`Kitchen`/`Stamp*`/`DateOnly`/`TimeOnly`-equivalents), once the specifiers they depend on exist
