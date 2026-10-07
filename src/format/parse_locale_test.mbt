///|
fn parse_error_of(f : () -> Unit raise @format.FormatError) -> String {
  try f() catch {
    e => e.to_string()
  } noraise {
    _ => "no error"
  }
}

///|
test "parse_date reads weekday and month names from the given locale" {
  let japanese = LocaleSpec::japanese().build()
  assert_eq(
    @format.parse_date("火曜日 3月 05 2024", "%A %B %d %Y", locale=japanese),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
  assert_eq(
    @format.parse_date("2024 11月 05", "%Y %b %d", locale=japanese),
    @core.NaiveDate::from_ymd(2024, 11, 5).unwrap(),
  )
  assert_eq(
    @format.parse_date("2024 1月 05", "%Y %b %d", locale=japanese),
    @core.NaiveDate::from_ymd(2024, 1, 5).unwrap(),
  )
}

///|
test "parse_date prefers the longest name when one weekday name begins another" {
  let japanese = LocaleSpec::japanese().build()
  let monday = @core.NaiveDate::from_ymd(2024, 3, 4).unwrap()
  assert_eq(
    @format.parse_date("月 2024-03-04", "%a %F", locale=japanese),
    monday,
  )
  assert_eq(
    @format.parse_date("月曜日 2024-03-04", "%a %F", locale=japanese),
    monday,
  )
}

///|
test "parse_date rejects a weekday name that contradicts the date" {
  let japanese = LocaleSpec::japanese().build()
  assert_eq(
    parse_error_of(() => {
      @format.parse_date("水 2024-03-05", "%a %F", locale=japanese) |> ignore
    }),
    "parsed fields contradict each other",
  )
}

///|
test "parse_date accepts only the names of the given locale" {
  let japanese = LocaleSpec::japanese().build()
  assert_eq(
    parse_error_of(() => {
      @format.parse_date("Tuesday 2024-03-05", "%A %F", locale=japanese)
      |> ignore
    }),
    "input does not match the format",
  )
  assert_eq(
    parse_error_of(() => {
      @format.parse_date("火曜日 2024-03-05", "%A %F") |> ignore
    }),
    "input does not match the format",
  )
}

///|
test "parse_time reads the day-period name from the given locale" {
  let japanese = LocaleSpec::japanese().build()
  assert_eq(
    @format.parse_time(
      "午後03時04分05秒",
      "%p%I時%M分%S秒",
      locale=japanese,
    ),
    @core.NaiveTime::from_hms(15, 4, 5).unwrap(),
  )
  assert_eq(
    @format.parse_time(
      "午前12時04分05秒",
      "%P%I時%M分%S秒",
      locale=japanese,
    ),
    @core.NaiveTime::from_hms(0, 4, 5).unwrap(),
  )
}

///|
test "parse_time matches the locale's day-period names ignoring ASCII case" {
  let locale = { ..LocaleSpec::japanese(), am: "A.M.", pm: "Pm", }.build()
  assert_eq(
    @format.parse_time("03:04:05 PM", "%I:%M:%S %p", locale~),
    @core.NaiveTime::from_hms(15, 4, 5).unwrap(),
  )
  assert_eq(
    @format.parse_time("03:04:05 a.m.", "%I:%M:%S %P", locale~),
    @core.NaiveTime::from_hms(3, 4, 5).unwrap(),
  )
}

///|
test "parse_time prefers the longest day-period name when one begins another" {
  let locale = { ..LocaleSpec::japanese(), am: "A", pm: "AM!", }.build()
  assert_eq(
    @format.parse_time("03:04:05 AM!", "%I:%M:%S %p", locale~),
    @core.NaiveTime::from_hms(15, 4, 5).unwrap(),
  )
}

///|
test "the parsers read %x, %X, %c and %r through the locale's layouts" {
  let japanese = LocaleSpec::japanese().build()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(15, 4, 5).unwrap(),
  )
  assert_eq(@format.parse_date("2024/03/05", "%x", locale=japanese), dt.date())
  assert_eq(@format.parse_time("15:04:05", "%X", locale=japanese), dt.time())
  assert_eq(
    @format.parse_time("午後03時04分05秒", "%r", locale=japanese),
    dt.time(),
  )
  assert_eq(
    @format.parse_date_time(
      "2024年03月05日 15時04分05秒",
      "%c",
      locale=japanese,
    ),
    dt,
  )
}

///|
test "formatting then parsing with the same locale restores the value" {
  let japanese = LocaleSpec::japanese().build()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 12, 25).unwrap(),
    @core.NaiveTime::from_hms(0, 30, 59).unwrap(),
  )
  let fmt = "%A %B%d日 %Y %p%I時%M分%S秒"
  let text = @format.format_date_time(dt, fmt, locale=japanese)
  assert_eq(text, "水曜日 12月25日 2024 午前12時30分59秒")
  assert_eq(@format.parse_date_time(text, fmt, locale=japanese), dt)
}

///|
test "every parse entry point takes the locale" {
  let japanese = LocaleSpec::japanese().build()
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @core.NaiveTime::from_hms(15, 4, 5).unwrap()
  let dt = @core.NaiveDateTime::new(date, time)
  assert_eq(
    @format.parse_date_and_remainder(
      "火 2024-03-05!",
      "%a %F",
      locale=japanese,
    ),
    (date, "!"),
  )
  assert_eq(
    @format.parse_time_and_remainder(
      "午後03:04:05!",
      "%p%I:%M:%S",
      locale=japanese,
    ),
    (time, "!"),
  )
  assert_eq(
    @format.parse_date_time_and_remainder(
      "火 2024-03-05 15:04:05!",
      "%a %F %T",
      locale=japanese,
    ),
    (dt, "!"),
  )
  let with_offset = @format.parse_date_time_fixed_offset(
    "火 2024-03-05 15:04:05 +0900",
    "%a %F %T %z",
    locale=japanese,
  )
  assert_eq(with_offset.naive_local(), dt)
  let (with_offset_rest, rest) = @format.parse_date_time_fixed_offset_and_remainder(
    "火 2024-03-05 15:04:05 +0900!",
    "%a %F %T %z",
    locale=japanese,
  )
  assert_eq((with_offset_rest.naive_local(), rest), (dt, "!"))
  match
    @format.parse_date_time_in(
      "火 2024-03-05 15:04:05",
      "%a %F %T",
      @tz.Utc::new(),
      locale=japanese,
    ) {
    Single(resolved) => assert_eq(resolved.naive_local(), dt)
    _ => fail("expected a single resolution")
  }
  let (in_utc, in_rest) = @format.parse_date_time_in_and_remainder(
    "火 2024-03-05 15:04:05!",
    "%a %F %T",
    @tz.Utc::new(),
    locale=japanese,
  )
  match in_utc {
    Single(resolved) => assert_eq((resolved.naive_local(), in_rest), (dt, "!"))
    _ => fail("expected a single resolution")
  }
}

///|
test "parse_items walks pre-tokenized items against the locale's names" {
  let japanese = LocaleSpec::japanese().build()
  let items = @format.tokenize("%a %F", locale=japanese)
  assert_eq(
    @format.parse_items("火 2024-03-05", items, locale=japanese).to_date(),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
  let (parsed, rest) = @format.parse_items_and_remainder(
    "火 2024-03-05?",
    items,
    locale=japanese,
  )
  assert_eq(
    (parsed.to_date(), rest),
    (@core.NaiveDate::from_ymd(2024, 3, 5).unwrap(), "?"),
  )
}
