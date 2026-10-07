///|
fn rfc2822_sample() -> @tz.DateTime[@tz.FixedOffset] {
  @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2003, 7, 1).unwrap(),
      @core.NaiveTime::from_hms(8, 52, 37).unwrap(),
    ),
    @tz.FixedOffset::east(2 * 3600).unwrap(),
  )
}

///|
test "format_date_time_tz_items renders Rfc2822 identically to to_rfc2822" {
  let dt = rfc2822_sample()
  assert_eq(
    @format.format_date_time_tz_items(dt, [@format.Rfc2822]),
    @format.to_rfc2822(dt),
  )
  assert_eq(
    @format.format_date_time_tz_items(dt, [@format.Rfc2822]),
    "Tue, 1 Jul 2003 10:52:37 +0200",
  )
}

///|
test "format_date_time_tz_items renders Rfc2822 between literals" {
  let items = [
    @format.Literal("Date: "),
    @format.Rfc2822,
    @format.Literal(" (mail)"),
  ]
  assert_eq(
    @format.format_date_time_tz_items(rfc2822_sample(), items),
    "Date: Tue, 1 Jul 2003 10:52:37 +0200 (mail)",
  )
}

///|
test "format_date_time_tz_items rejects Rfc2822 for a year outside 0..=9999" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(10000, 1, 1).unwrap(),
      @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  try @format.format_date_time_tz_items(dt, [@format.Rfc2822]) |> ignore catch {
    @format.InvalidRfc2822 => ()
    _ => fail("expected InvalidRfc2822")
  } noraise {
    _ => fail("expected a year beyond 9999 to be rejected")
  }
}

///|
test "format_date, format_time and format_date_time raise MissingField for Rfc2822, which needs a date, time and offset together" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @core.NaiveTime::from_hms(9, 30, 0).unwrap()
  let items = [@format.Rfc2822]
  try @format.format_date_items(date, items) |> ignore catch {
    @format.MissingField(@format.Rfc2822) => ()
    _ => fail("expected MissingField(Rfc2822)")
  } noraise {
    _ => fail("expected format_date_items to reject Rfc2822")
  }
  try @format.format_time_items(time, items) |> ignore catch {
    @format.MissingField(@format.Rfc2822) => ()
    _ => fail("expected MissingField(Rfc2822)")
  } noraise {
    _ => fail("expected format_time_items to reject Rfc2822")
  }
  try
    @format.format_date_time_items(@core.NaiveDateTime::new(date, time), items)
    |> ignore
  catch {
    @format.MissingField(@format.Rfc2822) => ()
    _ => fail("expected MissingField(Rfc2822)")
  } noraise {
    _ => fail("expected format_date_time_items to reject Rfc2822")
  }
}

///|
test "parse_items reads Rfc2822 into a date-time with its offset" {
  let parsed = @format.parse_items("Tue, 1 Jul 2003 10:52:37 +0200", [
    @format.Rfc2822,
  ])
  assert_eq(parsed.to_date_time_fixed_offset(), rfc2822_sample())
}

///|
test "Rfc2822 round-trips what to_rfc2822 renders" {
  let dt = rfc2822_sample()
  let text = @format.format_date_time_tz_items(dt, [@format.Rfc2822])
  assert_eq(
    @format.parse_items(text, [@format.Rfc2822]).to_date_time_fixed_offset(),
    dt,
  )
}

///|
test "Rfc2822 reads the obsolete syntax that parse_rfc2822_lenient reads" {
  let text = "tue,  1 jul 03 10:52 EST (comment)"
  let expected = @format.parse_rfc2822_lenient(text)
  assert_eq(
    @format.parse_items(text, [@format.Rfc2822]).to_date_time_fixed_offset(),
    expected,
  )
}

///|
test "parse_items_and_remainder leaves the text after an Rfc2822 reading" {
  let (parsed, rest) = @format.parse_items_and_remainder(
    "Tue, 1 Jul 2003 10:52:37 +0200; next",
    [@format.Rfc2822],
  )
  assert_eq(parsed.to_date_time_fixed_offset(), rfc2822_sample())
  assert_eq(rest, "; next")
}

///|
test "parse_items reads Rfc2822 between literals" {
  let items = [@format.Literal("Date: "), @format.Rfc2822, @format.Literal("!")]
  let parsed = @format.parse_items(
    "Date: Tue, 1 Jul 2003 10:52:37 +0200!", items,
  )
  assert_eq(parsed.to_date_time_fixed_offset(), rfc2822_sample())
}

///|
test "Rfc2822 rejects text that is not an RFC 2822 date-time" {
  try @format.parse_items("not a date", [@format.Rfc2822]) |> ignore catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected malformed text to be rejected")
  }
}

///|
test "Rfc2822 rejects a day of week that disagrees with the date" {
  try
    @format.parse_items("Mon, 1 Jul 2003 10:52:37 +0200", [@format.Rfc2822])
    |> ignore
  catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected a mismatched day of week to be rejected")
  }
}

///|
test "Rfc2822 rejects input that ends before the date-time does" {
  try @format.parse_items("", [@format.Rfc2822]) |> ignore catch {
    @format.InputTooShort => ()
    _ => fail("expected InputTooShort")
  } noraise {
    _ => fail("expected empty input to be rejected")
  }
}

///|
test "Rfc2822 cross-checks its fields against a redundantly present specifier" {
  let items = [
    @format.Rfc2822,
    @format.Literal(" "),
    @format.Numeric(@format.Year),
  ]
  let parsed = @format.parse_items("Tue, 1 Jul 2003 10:52:37 +0200 2003", items)
  assert_eq(parsed.to_date_time_fixed_offset(), rfc2822_sample())
  try
    @format.parse_items("Tue, 1 Jul 2003 10:52:37 +0200 2004", items) |> ignore
  catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected a disagreeing year to be rejected")
  }
}

///|
test "tokenize has no specifier that produces Rfc2822" {
  for spec in ["%+", "%c", "%a, %e %b %Y %T %z"] {
    assert_true(!@format.tokenize(spec).contains(@format.Rfc2822))
  }
}
