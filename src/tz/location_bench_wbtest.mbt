///|
test "bench: Location::load of an already loaded zone" (b : @bench.T) {
  ignore(Location::load("America/New_York"))
  b.bench(name="Location::load (loaded)", fn() {
    b.keep(Location::load("America/New_York"))
  })
}

///|
test "bench: parsing a zone from TZif bytes" (b : @bench.T) {
  let bytes = tzdata_zones.get("America/New_York").unwrap()
  b.bench(name="Location::from_tzif_bytes_named", fn() {
    b.keep(Location::from_tzif_bytes_named("America/New_York", bytes))
  })
}
