///|
fn march_fifth() -> @core.NaiveDate {
  @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
}

///|
fn nine_oh_five() -> @core.NaiveTime {
  @core.NaiveTime::from_hms(9, 5, 7).unwrap()
}

///|
test "parse_items walks a pre-tokenized item sequence and the result resolves to a date" {
  let items = @format.tokenize("%F")
  assert_eq(@format.parse_items("2024-03-05", items).to_date(), march_fifth())
}

///|
test "one Parsed resolves to a date, a time and a date-time without re-parsing" {
  let parsed = @format.parse_items(
    "2024-03-05 09:05:07",
    @format.tokenize("%F %T"),
  )
  assert_eq(parsed.to_date(), march_fifth())
  assert_eq(parsed.to_time(), nine_oh_five())
  assert_eq(
    parsed.to_date_time(),
    @core.NaiveDateTime::new(march_fifth(), nine_oh_five()),
  )
}

///|
test "parse_items accepts a hand-built item sequence" {
  let items = [
    @format.Numeric(@format.Day),
    @format.Literal("."),
    @format.Numeric(@format.MonthNumber),
    @format.Literal("."),
    @format.Numeric(@format.Year),
  ]
  assert_eq(@format.parse_items("05.03.2024", items).to_date(), march_fifth())
}

///|
test "parse_items rejects trailing input while parse_items_and_remainder returns it" {
  let items = @format.tokenize("%F")
  try @format.parse_items("2024-03-05 rest", items) |> ignore catch {
    @format.TrailingInput => ()
    _ => fail("expected TrailingInput")
  } noraise {
    _ => fail("expected trailing input to be rejected")
  }
  let (parsed, rest) = @format.parse_items_and_remainder(
    "2024-03-05 rest", items,
  )
  assert_eq(parsed.to_date(), march_fifth())
  assert_eq(rest, " rest")
}

///|
test "Parsed::to_date_time_fixed_offset applies the parsed offset" {
  let parsed = @format.parse_items(
    "2024-03-05 18:30:00 +0900",
    @format.tokenize("%F %T %z"),
  )
  let dt = parsed.to_date_time_fixed_offset()
  assert_eq(dt.offset(), @tz.FixedOffset::east(9 * 3600).unwrap())
  assert_eq(dt.naive_utc().time(), @core.NaiveTime::from_hms(9, 30, 0).unwrap())
}

///|
test "Parsed::to_date_time_in resolves a zone-less reading in the given zone" {
  let tokyo = @tz.FixedOffset::east(9 * 3600).unwrap()
  let parsed = @format.parse_items(
    "2024-03-05 18:30:00",
    @format.tokenize("%F %T"),
  )
  assert_eq(
    parsed.to_date_time_in(tokyo).unwrap().naive_utc().time(),
    @core.NaiveTime::from_hms(9, 30, 0).unwrap(),
  )
}

///|
test "a Parsed reports the same failures as the parse function it replaces" {
  let no_date = @format.parse_items("09", @format.tokenize("%H"))
  try no_date.to_date() |> ignore catch {
    @format.IncompleteFields => ()
    _ => fail("expected IncompleteFields")
  } noraise {
    _ => fail("expected a missing date to be rejected")
  }
  let with_offset = @format.parse_items(
    "2024-03-05 09:05:07 +0900",
    @format.tokenize("%F %T %z"),
  )
  try with_offset.to_date_time_in(@tz.Utc::new()) |> ignore catch {
    @format.InconsistentFields => ()
    _ => fail("expected InconsistentFields")
  } noraise {
    _ => fail("expected an offset to be rejected by to_date_time_in")
  }
}

///|
test "parse_items surfaces a mismatch inside the item sequence" {
  try
    @format.parse_items("2024-XX-05", @format.tokenize("%F")) |> ignore
  catch {
    @format.InputMismatch => ()
    _ => fail("expected InputMismatch")
  } noraise {
    _ => fail("expected a mismatch to be rejected")
  }
}

///|
test "format_date_items renders a date against a pre-tokenized item sequence, matching format_date" {
  let items = @format.tokenize("%Y/%m/%d %A")
  assert_eq(
    @format.format_date_items(march_fifth(), items),
    @format.format_date(march_fifth(), "%Y/%m/%d %A"),
  )
}

///|
test "format_time_items renders a time against a pre-tokenized item sequence, matching format_time" {
  let items = @format.tokenize("%H:%M:%S")
  assert_eq(
    @format.format_time_items(nine_oh_five(), items),
    @format.format_time(nine_oh_five(), "%H:%M:%S"),
  )
}

///|
test "format_date_time_items renders a date-time against a pre-tokenized item sequence, matching format_date_time" {
  let dt = @core.NaiveDateTime::new(march_fifth(), nine_oh_five())
  let items = @format.tokenize("%F %T %s")
  assert_eq(
    @format.format_date_time_items(dt, items),
    @format.format_date_time(dt, "%F %T %s"),
  )
}

///|
test "format_date_time_tz_items renders a zoned date-time against a pre-tokenized item sequence, matching format_date_time_tz" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(march_fifth(), nine_oh_five()),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  let items = @format.tokenize("%F %T %Z %z")
  assert_eq(
    @format.format_date_time_tz_items(dt, items),
    @format.format_date_time_tz(dt, "%F %T %Z %z"),
  )
}

///|
test "one tokenized item sequence renders many values" {
  let items = @format.tokenize("%d/%m")
  assert_eq(@format.format_date_items(march_fifth(), items), "05/03")
  assert_eq(
    @format.format_date_items(
      @core.NaiveDate::from_ymd(2024, 12, 25).unwrap(),
      items,
    ),
    "25/12",
  )
}

///|
test "the _items formatters raise MissingField for a specifier the value cannot supply" {
  try
    @format.format_date_items(march_fifth(), @format.tokenize("%H")) |> ignore
  catch {
    @format.MissingField(_) => ()
    _ => fail("expected MissingField")
  } noraise {
    _ => fail("expected format_date_items to reject %H")
  }
  try
    @format.format_time_items(nine_oh_five(), @format.tokenize("%Y")) |> ignore
  catch {
    @format.MissingField(_) => ()
    _ => fail("expected MissingField")
  } noraise {
    _ => fail("expected format_time_items to reject %Y")
  }
}

///|
test "Parsed compares equal for the same input and differs for different input" {
  let items = @format.tokenize("%F")
  let a = @format.parse_items("2024-03-05", items)
  let b = @format.parse_items("2024-03-05", items)
  let c = @format.parse_items("2024-03-06", items)
  assert_eq(a, b)
  assert_true(a != c)
}

///|
test "Parsed reports the offset and the zone name text that resolution alone cannot show" {
  let with_both = @format.parse_items(
    "2024-03-05 09:30:00 +0900 JST",
    @format.tokenize("%F %T %z %Z"),
  )
  assert_eq(with_both.utc_offset(), Some(32400))
  assert_eq(with_both.zone_name(), Some("JST"))
  let colon = @format.parse_items(
    "2024-03-05 09:30:00 -05:30",
    @format.tokenize("%F %T %:z"),
  )
  assert_eq(colon.utc_offset(), Some(-(5 * 3600 + 30 * 60)))
  assert_eq(colon.zone_name(), None)
}

///|
test "Parsed reports neither when the format read no offset and no zone name" {
  let plain = @format.parse_items(
    "2024-03-05 09:30:00",
    @format.tokenize("%F %T"),
  )
  assert_eq(plain.utc_offset(), None)
  assert_eq(plain.zone_name(), None)
}
