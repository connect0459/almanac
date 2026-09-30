///|
/// A small deterministic pseudo-random sequence (an LCG), so a failing case
/// repeats exactly.
struct Rng {
  mut state : UInt64
}

///|
fn Rng::new(seed : UInt64) -> Rng {
  Rng::{ state: seed, }
}

///|
fn Rng::next(self : Rng) -> UInt64 {
  self.state = self.state * 6364136223846793005UL + 1442695040888963407UL
  self.state >> 11
}

///|
/// A value in `low..=high`.
fn Rng::between(self : Rng, low : Int64, high : Int64) -> Int64 {
  low +
  (self.next().reinterpret_as_int64() & 0x7FFF_FFFF_FFFF_FFFFL) %
  (high - low + 1L)
}

///|
let day_limit : Int64 = 2_147_483_647L - 719_468L - 4L

///|
fn random_date(rng : Rng) -> @core.NaiveDate {
  @core.NaiveDate::from_epoch_days(rng.between(-day_limit, day_limit).to_int()).unwrap()
}

///|
fn random_time(rng : Rng) -> @core.NaiveTime {
  let secs = rng.between(0L, 86399L).to_int()
  let nanos = match rng.between(0L, 3L) {
    0L => 0
    1L => (rng.between(0L, 999L) * 1_000_000L).to_int()
    2L => (rng.between(0L, 999_999L) * 1_000L).to_int()
    _ => rng.between(0L, 999_999_999L).to_int()
  }
  @core.NaiveTime::from_num_seconds_from_midnight(secs, nanos).unwrap()
}

///|
fn random_offset(rng : Rng) -> @tz.FixedOffset {
  @tz.FixedOffset::east(rng.between(-86399L, 86399L).to_int()).unwrap()
}

///|
let samples : Int = 2000

///|
test "parse_date_default reads back the Show of every sampled date, including years beyond 0..=9999 and negative ones" {
  let rng = Rng::new(1UL)
  for _ in 0..<samples {
    let date = random_date(rng)
    assert_eq(@format.parse_date_default(date.to_string()), date)
  }
  for
    edge in [
      @core.NaiveDate::from_ymd(0, 1, 1).unwrap(),
      @core.NaiveDate::from_ymd(9999, 12, 31).unwrap(),
      @core.NaiveDate::from_ymd(10000, 1, 1).unwrap(),
      @core.NaiveDate::from_ymd(-1, 12, 31).unwrap(),
      @core.NaiveDate::from_ymd(2024, 2, 29).unwrap(),
    ] {
    assert_eq(@format.parse_date_default(edge.to_string()), edge)
  }
}

///|
test "parse_time_default reads back the Show of every sampled time, including a leap second" {
  let rng = Rng::new(2UL)
  for _ in 0..<samples {
    let time = random_time(rng)
    assert_eq(@format.parse_time_default(time.to_string()), time)
  }
  let leap = @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap()
  assert_eq(@format.parse_time_default(leap.to_string()), leap)
}

///|
test "parse_date_time_default reads back the Show of every sampled date-time" {
  let rng = Rng::new(3UL)
  for _ in 0..<samples {
    let dt = @core.NaiveDateTime::new(random_date(rng), random_time(rng))
    assert_eq(@format.parse_date_time_default(dt.to_string()), dt)
  }
}

///|
test "parse_date_time_utc_default reads back the Show of every sampled UTC datetime" {
  let rng = Rng::new(4UL)
  for _ in 0..<samples {
    let dt = @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(random_date(rng), random_time(rng)),
      @tz.Utc::new(),
    )
    assert_eq(@format.parse_date_time_utc_default(dt.to_string()), dt)
  }
}

///|
test "parse_date_time_fixed_offset_default reads back the Show of every sampled datetime in a fixed offset" {
  let rng = Rng::new(5UL)
  for _ in 0..<samples {
    let dt = @tz.DateTime::from_utc(
      @core.NaiveDateTime::new(random_date(rng), random_time(rng)),
      random_offset(rng),
    )
    assert_eq(@format.parse_date_time_fixed_offset_default(dt.to_string()), dt)
  }
}

///|
test "parse_fixed_offset reads back the Show of every offset in range" {
  for secs = -86399; secs <= 86399; secs = secs + 1 {
    let offset = @tz.FixedOffset::east(secs).unwrap()
    assert_eq(@format.parse_fixed_offset(offset.to_string()), offset)
  }
}

///|
test "parse_duration reads back the Show of every sampled duration" {
  let rng = Rng::new(6UL)
  for _ in 0..<samples {
    let seconds = rng.between(-9_223_372_036_854_774L, 9_223_372_036_854_774L)
    let nanos = match rng.between(0L, 2L) {
      0L => 0L
      1L => rng.between(0L, 999L) * 1_000_000L
      _ => rng.between(0L, 999_999_999L)
    }
    match
      @core.TimeDelta::seconds(seconds)
      .unwrap()
      .checked_add(@core.TimeDelta::nanoseconds(nanos).unwrap()) {
      Some(delta) => assert_eq(@format.parse_duration(delta.to_string()), delta)
      None => ()
    }
  }
  for
    edge in [
      @core.TimeDelta::zero(),
      @core.TimeDelta::max_value(),
      @core.TimeDelta::min_value(),
      @core.TimeDelta::nanoseconds(1L).unwrap(),
      @core.TimeDelta::nanoseconds(-1L).unwrap(),
    ] {
    assert_eq(@format.parse_duration(edge.to_string()), edge)
  }
}

///|
test "the sampling reaches the ranges the round trips are meant to cover" {
  let rng = Rng::new(1UL)
  let mut before_year_zero = false
  let mut past_year_9999 = false
  let mut fractional = false
  for _ in 0..<samples {
    let date = random_date(rng)
    if date.year() < 0 {
      before_year_zero = true
    }
    if date.year() > 9999 {
      past_year_9999 = true
    }
    if random_time(rng).nanosecond() != 0 {
      fractional = true
    }
  }
  assert_true(before_year_zero)
  assert_true(past_year_9999)
  assert_true(fractional)
}
