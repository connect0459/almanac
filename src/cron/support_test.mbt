///|
fn utc_at(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  minute : Int,
  second : Int,
) -> @tz.DateTime[@tz.Utc] {
  @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(year, month, day).unwrap(),
      @core.NaiveTime::from_hms(hour, minute, second).unwrap(),
    ),
    @tz.Utc::new(),
  )
}

///|
fn new_york() -> @tz.Location {
  @tz.Location::load("America/New_York").unwrap()
}

///|
fn new_york_at(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  minute : Int,
  second : Int,
) -> @tz.DateTime[@tz.Location] {
  @tz.DateTime::from_local(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(year, month, day).unwrap(),
      @core.NaiveTime::from_hms(hour, minute, second).unwrap(),
    ),
    new_york(),
  )
  .single()
  .unwrap()
}

///|
fn new_york_utc(
  year : Int,
  month : Int,
  day : Int,
  hour : Int,
  minute : Int,
  second : Int,
) -> @tz.DateTime[@tz.Location] {
  utc_at(year, month, day, hour, minute, second).with_timezone(new_york())
}

///|
fn assert_invalid_field(
  expression : String,
  field : @cron.CronField,
) -> Unit raise {
  try @cron.Cron::parse(expression) |> ignore catch {
    @cron.InvalidField(f) => assert_eq(f, field)
  } noraise {
    _ => fail("expected InvalidField for \{expression}")
  }
}
