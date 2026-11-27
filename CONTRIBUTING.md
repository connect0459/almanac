# Contributing

## Prerequisites

- [MoonBit toolchain](https://www.moonbitlang.com/download/) — `moon` CLI
- [just](https://just.systems/) — task runner
- [pre-commit](https://pre-commit.com/) — hook runner

## Setup

```sh
git clone https://github.com/connect0459/almanac
cd almanac
just setup
```

`just setup` runs `moon update` to fetch package dependencies and installs the pre-commit hooks (`pre-commit install`).

### pre-commit hooks

To run all hooks manually:

```sh
pre-commit run --all-files
```

## Development workflow

| Command | Purpose |
| :--- | :--- |
| `moon test` | Run all tests |
| `moon test --target wasm-gc` | Run tests on a specific backend |
| `moon fmt` | Format all source files |
| `moon check` | Type-check without building |
| `moon info` | Regenerate `.mbti` interface files |
| `just verify` | Run the full CI-equivalent check locally |

The pre-commit hooks enforce formatting and lint checks on every commit.

Before opening a pull request, run the full verification suite:

```sh
just verify
```

This mirrors the CI matrix and checks all four backends (`js`, `wasm`,
`wasm-gc`, `native`).

## Testing guidelines

This project follows **Red → Green → Refactor** (Detroit-school TDD):

- Write a failing test first, then implement.
- Use real objects; mocks are only permitted at external boundaries.
- Test names describe **what business rule** is verified, not how.

To confirm cross-target compatibility, run the tests on every backend:

```sh
moon test --target js
moon test --target wasm
moon test --target wasm-gc
moon test --target native
```

## Commit format

```text
<type>(<scope>): <subject>
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `tidy`, `test`, `chore`, `ci`, `perf`

**Scope**: package name when the change targets a specific package (`core`,
`tz`, `format` or `cron`); omit for project-wide changes.

**Subject**: imperative mood, 72 characters max, no trailing period.

Examples:

```text
feat(cron): accept @annually as a shorthand
fix(core): reject out-of-range month values in NaiveDate::from_ymd
tidy(tz): name the seconds-per-day constant
```

## Pull request process

1. Fork the repository and create a branch: `feat/xxx`, `fix/xxx`, `docs/xxx`.
2. Follow the Red → Green → Refactor cycle.
3. Run `just verify` and commit any resulting diffs.
4. If the change touches the public API, update documentation so it reflects the new behavior:
   - **Per-package `README.mbt.md`** — the sole documentation source for each public package; update the API reference tables, key types, and examples as needed.
   - Run `moon info` and verify the `.mbti` diff is expected (it is the authoritative formal spec for signatures).
5. Open a pull request. CI tests `js`, `wasm`, `wasm-gc`, and `native`.

Do not edit `CHANGELOG.md` in regular pull requests. Changelog entries are written together in the Release PR.

## Code style

- No code comments unless the **why** is genuinely non-obvious.
- Prefer immutability; avoid mutable state unless necessary.
- Internal packages under `internal/` are not part of the public API and must not be re-exported through the root `connect0459/almanac` package.
- All user-facing strings (test names, error messages, doc comments) must be in **English**.
