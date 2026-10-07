///|
test "tokenize expands %x, %X, %c and %r into the layouts of the given locale" {
  let japanese = LocaleSpec::japanese().build()
  assert_eq(
    @format.tokenize("%x", locale=japanese),
    @format.tokenize("%Y/%m/%d"),
  )
  assert_eq(
    @format.tokenize("%X", locale=japanese),
    @format.tokenize("%H:%M:%S"),
  )
  assert_eq(
    @format.tokenize("%c", locale=japanese),
    @format.tokenize("%Y年%m月%d日 %H時%M分%S秒"),
  )
  assert_eq(
    @format.tokenize("%r", locale=japanese),
    @format.tokenize("%p%I時%M分%S秒"),
  )
}

///|
test "tokenize expands %x, %X, %c and %r to the POSIX layouts when no locale is given" {
  assert_eq(@format.tokenize("%x"), @format.tokenize("%m/%d/%y"))
  assert_eq(@format.tokenize("%X"), @format.tokenize("%H:%M:%S"))
  assert_eq(@format.tokenize("%c"), @format.tokenize("%a %b %e %H:%M:%S %Y"))
  assert_eq(@format.tokenize("%r"), @format.tokenize("%I:%M:%S %p"))
}

///|
test "tokenize keeps %D and %T independent of the locale" {
  let japanese = LocaleSpec::japanese().build()
  assert_eq(
    @format.tokenize("%D", locale=japanese),
    @format.tokenize("%m/%d/%y"),
  )
  assert_eq(
    @format.tokenize("%T", locale=japanese),
    @format.tokenize("%H:%M:%S"),
  )
}

///|
test "tokenize rejects a padding flag on a layout specifier even when the layout is a single field" {
  let single_field = { ..LocaleSpec::japanese(), date_format: "%d", }.build()
  for
    case in [
      ("%-x", "unknown format specifier '%-'"),
      ("%0X", "unknown format specifier '%0'"),
      ("%_c", "unknown format specifier '%_'"),
      ("%-r", "unknown format specifier '%-'"),
    ] {
    let (fmt, message) = case
    let raised = try
      @format.tokenize(fmt, locale=single_field) |> ignore
    catch {
      e => e.to_string()
    } noraise {
      _ => "no error"
    }
    assert_eq(raised, message)
  }
}

///|
test "format_date renders %x through the locale's date layout" {
  let japanese = LocaleSpec::japanese().build()
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.format_date(date, "%x", locale=japanese), "2024/03/05")
  assert_eq(@format.format_date(date, "%x"), "03/05/24")
}

///|
test "format_time renders %X and %r through the locale's time layouts" {
  let japanese = LocaleSpec::japanese().build()
  let time = @core.NaiveTime::from_hms(15, 4, 5).unwrap()
  assert_eq(@format.format_time(time, "%X", locale=japanese), "15:04:05")
  assert_eq(
    @format.format_time(time, "%r", locale=japanese),
    "午後03時04分05秒",
  )
  assert_eq(@format.format_time(time, "%r"), "03:04:05 PM")
}

///|
test "format_date_time renders %c through the locale's date-time layout" {
  let japanese = LocaleSpec::japanese().build()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(15, 4, 5).unwrap(),
  )
  assert_eq(
    @format.format_date_time(dt, "%c", locale=japanese),
    "2024年03月05日 15時04分05秒",
  )
  assert_eq(@format.format_date_time(dt, "%c"), "Tue Mar  5 15:04:05 2024")
}

///|
test "a layout may use the locale's own names" {
  let spec = { ..LocaleSpec::japanese(), date_time_format: "%A %B%e日 100%%", }
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
    @core.NaiveTime::from_hms(15, 4, 5).unwrap(),
  )
  assert_eq(
    @format.format_date_time(dt, "%c", locale=spec.build()),
    "火曜日 3月 5日 100%",
  )
}

///|
test "format_date renders the month in %v through the locale" {
  let japanese = LocaleSpec::japanese().build()
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(@format.format_date(date, "%v", locale=japanese), " 5-3月-2024")
  assert_eq(@format.format_date(date, "%v"), " 5-Mar-2024")
}

///|
test "parse_date reads the month in %v through the locale" {
  let japanese = LocaleSpec::japanese().build()
  assert_eq(
    @format.parse_date(" 5-3月-2024", "%v", locale=japanese),
    @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
  )
  assert_eq(
    parse_error_of(() => {
      @format.parse_date(" 5-Mar-2024", "%v", locale=japanese) |> ignore
    }),
    "input does not match the format",
  )
}
