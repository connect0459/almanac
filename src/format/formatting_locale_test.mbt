///|
test "format_date renders weekday and month names from the given locale" {
  let japanese = LocaleSpec::japanese().build()
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(
    @format.format_date(date, "%A|%a|%B|%b|%h", locale=japanese),
    "火曜日|火|3月|3月|3月",
  )
}

///|
test "format_date renders English names when no locale is given" {
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  assert_eq(
    @format.format_date(date, "%A %a %B %b"),
    @format.format_date(date, "%A %a %B %b", locale=@format.Locale::posix()),
  )
  assert_eq(@format.format_date(date, "%A %a %B %b"), "Tuesday Tue March Mar")
}

///|
test "format_time renders the day-period name from the given locale" {
  let japanese = LocaleSpec::japanese().build()
  let morning = @core.NaiveTime::from_hms(9, 5, 7).unwrap()
  let evening = @core.NaiveTime::from_hms(15, 4, 5).unwrap()
  assert_eq(@format.format_time(morning, "%p%I", locale=japanese), "午前09")
  assert_eq(@format.format_time(evening, "%p%I", locale=japanese), "午後03")
  assert_eq(@format.format_time(evening, "%P", locale=japanese), "午後")
}

///|
test "format_time renders the lowercase day-period marker as the ASCII lowercase of the locale's name" {
  let spec = { ..LocaleSpec::japanese(), am: "A.M.", pm: "Pm", }
  let locale = spec.build()
  let morning = @core.NaiveTime::from_hms(9, 5, 7).unwrap()
  let evening = @core.NaiveTime::from_hms(15, 4, 5).unwrap()
  assert_eq(@format.format_time(morning, "%p/%P", locale~), "A.M./a.m.")
  assert_eq(@format.format_time(evening, "%p/%P", locale~), "Pm/pm")
}

///|
test "format_date_time renders names from the given locale" {
  let japanese = LocaleSpec::japanese().build()
  let dt = @core.NaiveDateTime::new(
    @core.NaiveDate::from_ymd(2024, 12, 25).unwrap(),
    @core.NaiveTime::from_hms(0, 30, 0).unwrap(),
  )
  assert_eq(
    @format.format_date_time(dt, "%B%d日 %A %p", locale=japanese),
    "12月25日 水曜日 午前",
  )
}

///|
test "format_date_time_tz renders names from the given locale" {
  let japanese = LocaleSpec::japanese().build()
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(15, 4, 5).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(
    @format.format_date_time_tz(dt, "%a %p %Z", locale=japanese),
    "火 午後 UTC",
  )
}

///|
test "the _items renderers take the locale too" {
  let japanese = LocaleSpec::japanese().build()
  let date = @core.NaiveDate::from_ymd(2024, 3, 5).unwrap()
  let time = @core.NaiveTime::from_hms(15, 4, 5).unwrap()
  let dt = @core.NaiveDateTime::new(date, time)
  let tz_dt = @tz.DateTime::from_utc(dt, @tz.Utc::new())
  assert_eq(
    @format.format_date_items(date, @format.tokenize("%a"), locale=japanese),
    "火",
  )
  assert_eq(
    @format.format_time_items(time, @format.tokenize("%p"), locale=japanese),
    "午後",
  )
  assert_eq(
    @format.format_date_time_items(
      dt,
      @format.tokenize("%b %p"),
      locale=japanese,
    ),
    "3月 午後",
  )
  assert_eq(
    @format.format_date_time_tz_items(
      tz_dt,
      @format.tokenize("%b %p"),
      locale=japanese,
    ),
    "3月 午後",
  )
}
