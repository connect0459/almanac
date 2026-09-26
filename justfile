# Setup after clone
setup:
    moon update
    pre-commit install

# Run tests for a single target (e.g. `just test-target wasm-gc`)
test-target target:
    moon check --deny-warn --target {{target}}
    moon test --target {{target}}

# Verify code quality and all targets (matches CI)
verify:
    moon fmt --check
    for t in js wasm wasm-gc native; do \
        just test-target $t; \
    done

# Regenerate src/tz/tzdata_generated.mbt from a compiled zoneinfo directory
# (e.g. a system's /usr/share/zoneinfo, or one built from a specific IANA
# tzdata release with `zic`)
gen-tzdata source_dir:
    python3 scripts/gen_tzdata.py --source-dir {{source_dir}} --output src/tz/tzdata_generated.mbt
    moon fmt
