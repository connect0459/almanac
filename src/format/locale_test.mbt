///|
priv struct LocaleSpec {
  long_months : Array[String]
  short_months : Array[String]
  long_weekdays : Array[String]
  short_weekdays : Array[String]
  am : String
  pm : String
  date_format : String
  time_format : String
  date_time_format : String
  time_format_12h : String
}

///|
fn LocaleSpec::japanese() -> LocaleSpec {
  let months = [
    "1月", "2月", "3月", "4月", "5月", "6月", "7月", "8月", "9月", "10月",
    "11月", "12月",
  ]
  {
    long_months: months,
    short_months: months,
    long_weekdays: [
      "月曜日", "火曜日", "水曜日", "木曜日", "金曜日", "土曜日",
      "日曜日",
    ],
    short_weekdays: ["月", "火", "水", "木", "金", "土", "日"],
    am: "午前",
    pm: "午後",
    date_format: "%Y/%m/%d",
    time_format: "%H:%M:%S",
    date_time_format: "%Y年%m月%d日 %H時%M分%S秒",
    time_format_12h: "%p%I時%M分%S秒",
  }
}

///|
fn LocaleSpec::build(
  self : LocaleSpec,
) -> @format.Locale raise @format.LocaleError {
  @format.Locale::new(
    long_months=self.long_months,
    short_months=self.short_months,
    long_weekdays=self.long_weekdays,
    short_weekdays=self.short_weekdays,
    am=self.am,
    pm=self.pm,
    date_format=self.date_format,
    time_format=self.time_format,
    date_time_format=self.date_time_format,
    time_format_12h=self.time_format_12h,
  )
}

///|
fn locale_error_of(spec : LocaleSpec) -> @format.LocaleError? {
  try spec.build() |> ignore catch {
    e => Some(e)
  } noraise {
    _ => None
  }
}

///|
test "the POSIX locale names months, weekdays and day periods in English" {
  let posix = @format.Locale::posix()
  assert_eq(posix.month_name(@core.Mar), "March")
  assert_eq(posix.month_name(@core.Mar, short=true), "Mar")
  assert_eq(posix.weekday_name(@core.Tue), "Tuesday")
  assert_eq(posix.weekday_name(@core.Tue, short=true), "Tue")
  assert_eq(posix.am_pm(false), "AM")
  assert_eq(posix.am_pm(true), "PM")
}

///|
test "the POSIX locale carries the C-locale date and time layouts" {
  let posix = @format.Locale::posix()
  assert_eq(posix.date_format(), "%m/%d/%y")
  assert_eq(posix.time_format(), "%H:%M:%S")
  assert_eq(posix.date_time_format(), "%a %b %e %H:%M:%S %Y")
  assert_eq(posix.time_format_12h(), "%I:%M:%S %p")
}

///|
test "a custom locale answers with the names it was built from" {
  let japanese = LocaleSpec::japanese().build()
  assert_eq(japanese.month_name(@core.Nov), "11月")
  assert_eq(japanese.weekday_name(@core.Mon), "月曜日")
  assert_eq(japanese.weekday_name(@core.Sun, short=true), "日")
  assert_eq(japanese.am_pm(false), "午前")
  assert_eq(japanese.am_pm(true), "午後")
  assert_eq(japanese.date_format(), "%Y/%m/%d")
}

///|
test "a locale needs exactly twelve month names in each form" {
  let spec = LocaleSpec::japanese()
  assert_eq(
    locale_error_of({ ..spec, long_months: spec.long_months[:11].to_owned(), }),
    Some(@format.InvalidMonthNames),
  )
  assert_eq(
    locale_error_of({ ..spec, short_months: spec.short_months + ["13月"], }),
    Some(@format.InvalidMonthNames),
  )
}

///|
test "a locale rejects an empty month name" {
  let spec = LocaleSpec::japanese()
  let months = spec.long_months.copy()
  months[4] = ""
  assert_eq(
    locale_error_of({ ..spec, long_months: months, }),
    Some(@format.InvalidMonthNames),
  )
}

///|
test "a locale rejects one month name shared by two months" {
  let spec = LocaleSpec::japanese()
  let long_months = spec.long_months.copy()
  long_months[1] = "1月"
  assert_eq(
    locale_error_of({ ..spec, long_months, }),
    Some(@format.InvalidMonthNames),
  )
  let short_months = spec.short_months.copy()
  short_months[0] = "Mar"
  short_months[2] = "Mar"
  assert_eq(
    locale_error_of({ ..spec, short_months, }),
    Some(@format.InvalidMonthNames),
  )
}

///|
test "a locale accepts a month whose long and short names are the same word" {
  let spec = LocaleSpec::japanese()
  assert_true(
    locale_error_of({ ..spec, short_months: spec.long_months, }) is None,
  )
}

///|
test "a locale needs exactly seven distinct non-empty weekday names in each form" {
  let spec = LocaleSpec::japanese()
  assert_eq(
    locale_error_of({
      ..spec,
      long_weekdays: spec.long_weekdays[:6].to_owned(),
    }),
    Some(@format.InvalidWeekdayNames),
  )
  let short_weekdays = spec.short_weekdays.copy()
  short_weekdays[6] = "月"
  assert_eq(
    locale_error_of({ ..spec, short_weekdays, }),
    Some(@format.InvalidWeekdayNames),
  )
  let long_weekdays = spec.long_weekdays.copy()
  long_weekdays[3] = ""
  assert_eq(
    locale_error_of({ ..spec, long_weekdays, }),
    Some(@format.InvalidWeekdayNames),
  )
}

///|
test "a locale needs two non-empty day-period names that differ ignoring ASCII case" {
  let spec = LocaleSpec::japanese()
  assert_eq(
    locale_error_of({ ..spec, am: "", }),
    Some(@format.InvalidAmPmNames),
  )
  assert_eq(
    locale_error_of({ ..spec, pm: "", }),
    Some(@format.InvalidAmPmNames),
  )
  assert_eq(
    locale_error_of({ ..spec, am: "am", pm: "AM", }),
    Some(@format.InvalidAmPmNames),
  )
}

///|
test "a locale rejects a layout that uses a locale-dependent specifier" {
  let spec = LocaleSpec::japanese()
  for pattern in ["%x", "%X", "%c", "%r", "%Y %-x", "%H%0c"] {
    assert_eq(
      locale_error_of({ ..spec, date_format: pattern, }),
      Some(@format.InvalidPattern(pattern)),
    )
    assert_eq(
      locale_error_of({ ..spec, time_format_12h: pattern, }),
      Some(@format.InvalidPattern(pattern)),
    )
  }
}

///|
test "a locale rejects a layout that is not a valid format string" {
  let spec = LocaleSpec::japanese()
  assert_eq(
    locale_error_of({ ..spec, time_format: "%Q", }),
    Some(@format.InvalidPattern("%Q")),
  )
  assert_eq(
    locale_error_of({ ..spec, date_time_format: "%Y%", }),
    Some(@format.InvalidPattern("%Y%")),
  )
}

///|
test "a locale rejects an empty layout" {
  let spec = LocaleSpec::japanese()
  assert_eq(
    locale_error_of({ ..spec, date_format: "", }),
    Some(@format.InvalidPattern("")),
  )
  assert_eq(
    locale_error_of({ ..spec, time_format: "", }),
    Some(@format.InvalidPattern("")),
  )
  assert_eq(
    locale_error_of({ ..spec, date_time_format: "", }),
    Some(@format.InvalidPattern("")),
  )
  assert_eq(
    locale_error_of({ ..spec, time_format_12h: "", }),
    Some(@format.InvalidPattern("")),
  )
}

///|
test "a layout may contain a literal percent sign that spells a locale-dependent specifier" {
  let spec = LocaleSpec::japanese()
  assert_true(locale_error_of({ ..spec, date_format: "100%%x %Y", }) is None)
}

///|
test "LocaleError renders a one-line human-readable message for each variant" {
  assert_eq(
    @format.InvalidMonthNames.to_string(),
    "a locale needs twelve distinct non-empty month names in each form",
  )
  assert_eq(
    @format.InvalidWeekdayNames.to_string(),
    "a locale needs seven distinct non-empty weekday names in each form",
  )
  assert_eq(
    @format.InvalidAmPmNames.to_string(),
    "a locale needs two distinct non-empty day-period names",
  )
  assert_eq(
    @format.InvalidPattern("%x").to_string(),
    "invalid locale layout: %x",
  )
}
