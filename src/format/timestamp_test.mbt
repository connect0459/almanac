///|
fn sample_utc() -> @core.NaiveDateTime {
  @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(9, 5, 7).unwrap(),
  )
}

///|
fn timestamp_kind(f : () -> Unit raise @format.ParseError) -> String {
  try f() catch {
    @format.InputTooShort => "InputTooShort"
    @format.TrailingInput => "TrailingInput"
    @format.InputMismatch => "InputMismatch"
    @format.FieldOutOfRange => "FieldOutOfRange"
    @format.InconsistentFields => "InconsistentFields"
    @format.IncompleteFields => "IncompleteFields"
    _ => "other"
  } noraise {
    _ => "ok"
  }
}

///|
test "parse_date_time reads %s as a Unix timestamp naming a UTC instant" {
  let ts = sample_utc().timestamp().to_string()
  assert_eq(@format.parse_date_time(ts, "%s"), sample_utc())
  assert_eq(
    @format.parse_date_time("0", "%s"),
    @core.NaiveDateTime::unix_epoch(),
  )
}

///|
test "%s accepts a negative timestamp and an explicit plus sign" {
  assert_eq(
    @format.parse_date_time("-86400", "%s"),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(1969, 12, 31).unwrap(),
      @core.NaiveTime::midnight(),
    ),
  )
  assert_eq(
    @format.parse_date_time("+86400", "%s"),
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(1970, 1, 2).unwrap(),
      @core.NaiveTime::midnight(),
    ),
  )
}

///|
test "%s combines with a fractional-second field to form the instant" {
  let ts = sample_utc().timestamp().to_string()
  let expected = @core.NaiveDateTime::new(
    sample_utc().date(),
    @core.NaiveTime::from_hms_nano(9, 5, 7, 123_456_789).unwrap(),
  )
  assert_eq(@format.parse_date_time(ts + ".123456789", "%s%.9f"), expected)
}

///|
test "%s round-trips through format_date_time" {
  for
    dt in [
      sample_utc(),
      @core.NaiveDateTime::unix_epoch(),
      @core.NaiveDateTime::new(
        @core.NaiveDate::from_ymd(1900, 1, 1).unwrap(),
        @core.NaiveTime::from_hms(23, 59, 59).unwrap(),
      ),
    ] {
    assert_eq(
      @format.parse_date_time(@format.format_date_time(dt, "%s"), "%s"),
      dt,
    )
  }
}

///|
test "other date and time fields are cross-checked against the timestamp's instant" {
  let ts = sample_utc().timestamp().to_string()
  assert_eq(
    @format.parse_date_time(ts + " 2024-03-05 09:05:07", "%s %F %T"),
    sample_utc(),
  )
  assert_eq(@format.parse_date_time(ts + " 03", "%s %m"), sample_utc())
  assert_eq(
    timestamp_kind(() => {
      @format.parse_date_time(ts + " 2024-03-05 09:05:08", "%s %F %T") |> ignore
    }),
    "InconsistentFields",
  )
  assert_eq(
    timestamp_kind(() => @format.parse_date_time(ts + " 05", "%s %m") |> ignore),
    "InconsistentFields",
  )
  assert_eq(
    timestamp_kind(() => {
      @format.parse_date_time(ts + " Wednesday", "%s %A") |> ignore
    }),
    "InconsistentFields",
  )
}

///|
test "a leap second cannot agree with a timestamp" {
  let ts = sample_utc().timestamp().to_string()
  assert_eq(
    timestamp_kind(() => {
      @format.parse_date_time(ts + " 09:05:60", "%s %T") |> ignore
    }),
    "InconsistentFields",
  )
}

///|
test "a timestamp with a %z offset gives a DateTime at that instant shown in that offset" {
  let ts = sample_utc().timestamp().to_string()
  let dt = @format.parse_date_time_tz(ts + " +0900", "%s %z")
  assert_eq(dt.naive_utc(), sample_utc())
  assert_eq(dt.offset(), @tz.FixedOffset::east(9 * 3600).unwrap())
  assert_eq(dt.naive_local().time().hour(), 18)
}

///|
test "with a timestamp, date and time fields are checked against the local reading in the offset" {
  let ts = sample_utc().timestamp().to_string()
  assert_eq(
    @format.parse_date_time_tz(ts + " +0900 2024-03-05 18:05:07", "%s %z %F %T").naive_utc(),
    sample_utc(),
  )
  assert_eq(
    timestamp_kind(() => {
      @format.parse_date_time_tz(
        ts + " +0900 2024-03-05 09:05:07",
        "%s %z %F %T",
      )
      |> ignore
    }),
    "InconsistentFields",
  )
}

///|
test "a timestamp without an offset does not make a fixed-offset DateTime" {
  let ts = sample_utc().timestamp().to_string()
  assert_eq(
    timestamp_kind(() => @format.parse_date_time_tz(ts, "%s") |> ignore),
    "IncompleteFields",
  )
}

///|
test "a zoned DateTime round-trips through %s and %z" {
  let dt = @tz.DateTime::from_utc(
    sample_utc(),
    @tz.FixedOffset::west(5 * 3600 + 30 * 60).unwrap(),
  )
  let text = @format.format_date_time_tz(dt, "%s %z")
  assert_eq(@format.parse_date_time_tz(text, "%s %z"), dt)
}

///|
test "parse_date_time_in places a timestamp's instant in the given zone without ambiguity" {
  let new_york = @tz.Location::load("America/New_York").unwrap()
  let ts = sample_utc().timestamp().to_string()
  let mapped = @format.parse_date_time_in(ts, "%s", new_york)
  let dt = mapped.single().unwrap()
  assert_eq(dt.naive_utc(), sample_utc())
  assert_eq(dt.zone_name(), "EST")
  let fold_instant = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 11, 3).unwrap(),
    @core.NaiveTime::from_hms(6, 30, 0).unwrap(),
  )
  assert_eq(
    @format.parse_date_time_in(
      fold_instant.timestamp().to_string(),
      "%s",
      new_york,
    )
    .single()
    .unwrap()
    .naive_utc(),
    fold_instant,
  )
}

///|
test "parse_date_time_in checks other fields against the local reading in the zone" {
  let new_york = @tz.Location::load("America/New_York").unwrap()
  let ts = sample_utc().timestamp().to_string()
  assert_eq(
    @format.parse_date_time_in(ts + " 04:05:07", "%s %T", new_york)
    .single()
    .unwrap()
    .naive_utc(),
    sample_utc(),
  )
  assert_eq(
    timestamp_kind(() => {
      @format.parse_date_time_in(ts + " 09:05:07", "%s %T", new_york) |> ignore
    }),
    "InconsistentFields",
  )
  assert_eq(
    timestamp_kind(() => {
      @format.parse_date_time_in(ts + " +0900", "%s %z", new_york) |> ignore
    }),
    "InconsistentFields",
  )
}

///|
test "the date-only and time-only resolvers ignore a timestamp" {
  let ts = sample_utc().timestamp().to_string()
  assert_eq(
    @format.parse_date(ts + " 2000-01-02", "%s %F"),
    @core.NaiveDate::from_ymd(2000, 1, 2).unwrap(),
  )
  assert_eq(
    timestamp_kind(() => @format.parse_date(ts, "%s") |> ignore),
    "IncompleteFields",
  )
  assert_eq(
    timestamp_kind(() => @format.parse_time(ts, "%s") |> ignore),
    "IncompleteFields",
  )
}

///|
test "%s rejects a missing or malformed number and a value no instant can have" {
  assert_eq(
    timestamp_kind(() => @format.parse_date_time("", "%s") |> ignore),
    "InputTooShort",
  )
  for input in ["abc", "-", "+", "--5", "1.5x"] {
    assert_eq(
      timestamp_kind(() => @format.parse_date_time(input, "%s") |> ignore),
      if input == "1.5x" {
        "TrailingInput"
      } else {
        "InputMismatch"
      },
    )
  }
  for
    input in ["99999999999999999", "12345678901234567890", "-99999999999999999"] {
    assert_eq(
      timestamp_kind(() => @format.parse_date_time(input, "%s") |> ignore),
      "FieldOutOfRange",
    )
  }
}

///|
test "two %s fields must agree" {
  assert_eq(
    @format.parse_date_time("0 0", "%s %s"),
    @core.NaiveDateTime::unix_epoch(),
  )
  assert_eq(
    timestamp_kind(() => @format.parse_date_time("0 1", "%s %s") |> ignore),
    "InconsistentFields",
  )
}

///|
test "a timestamp at the last representable instant cannot be shown in a later-than-UTC offset" {
  let last = @core.NaiveDate::from_epoch_days(2_147_483_647 - 719_468)
    .unwrap()
    .and_hms(23, 59, 59)
    .unwrap()
  let ts = last.timestamp().to_string()
  assert_eq(@format.parse_date_time(ts, "%s"), last)
  assert_eq(
    timestamp_kind(() => {
      @format.parse_date_time_tz(ts + " +0900", "%s %z") |> ignore
    }),
    "FieldOutOfRange",
  )
}
