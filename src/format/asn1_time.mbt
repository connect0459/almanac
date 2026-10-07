///|
fn[T] asn1_require(opt : T?) -> T raise FormatError {
  match opt {
    None => raise InvalidAsn1Time
    Some(v) => v
  }
}

///|
fn[Tz] asn1_year_and_tail(dt : @tz.DateTime[Tz]) -> (Int, String) {
  let utc = dt.naive_utc()
  let date = utc.date()
  let time = utc.time()
  let seconds = time.second() + time.nanosecond() / 1_000_000_000
  (
    date.year(),
    pad_int(date.month().number(), 2) +
    pad_int(date.day(), 2) +
    pad_int(time.hour(), 2) +
    pad_int(time.minute(), 2) +
    pad_int(seconds, 2) +
    "Z",
  )
}

///|
fn asn1_parse_fields(
  s : String,
  year_width : Int,
) -> @core.NaiveDateTime raise FormatError {
  let chars = s.to_array()
  let (year, p1) = asn1_require(parse_fixed_digits(chars, 0, year_width))
  let (month, p2) = asn1_require(parse_fixed_digits(chars, p1, 2))
  let (day, p3) = asn1_require(parse_fixed_digits(chars, p2, 2))
  let (hour, p4) = asn1_require(parse_fixed_digits(chars, p3, 2))
  let (minute, p5) = asn1_require(parse_fixed_digits(chars, p4, 2))
  let (second, p6) = asn1_require(parse_fixed_digits(chars, p5, 2))
  let p7 = asn1_require(expect_char(chars, p6, 'Z'))
  if p7 != chars.length() {
    raise InvalidAsn1Time
  }
  let full_year = if year_width == 2 {
    if year < 50 {
      2000 + year
    } else {
      1900 + year
    }
  } else {
    year
  }
  let date = asn1_require(@core.NaiveDate::from_ymd(full_year, month, day))
  let time = asn1_require(@core.NaiveTime::from_hms(hour, minute, second))
  @core.NaiveDateTime::new(date, time)
}

///|
/// Renders the UTC instant of `dt` as an ASN.1 `UTCTime` in DER form
/// (ITU-T X.680 section 47, RFC 5280 section 4.1.2.5.1):
/// `"<YY><MM><DD><HH><MM><SS>Z"`, e.g. `"910506234540Z"`. The two-digit year
/// reads back as 20xx below 50 and 19xx from 50, so only the years
/// `1950..=2049` can be written. A fractional second is dropped and a leap
/// second is written as `:60`.
///
/// Raises `InvalidAsn1Time` if the year is outside `1950..=2049`.
pub fn[Tz] to_utc_time(dt : @tz.DateTime[Tz]) -> String raise FormatError {
  let (year, tail) = asn1_year_and_tail(dt)
  if year < 1950 || year > 2049 {
    raise InvalidAsn1Time
  }
  pad_int(year % 100, 2) + tail
}

///|
/// Renders the UTC instant of `dt` as an ASN.1 `GeneralizedTime` in DER form
/// (ITU-T X.680 section 42, RFC 5280 section 4.1.2.5.2):
/// `"<YYYY><MM><DD><HH><MM><SS>Z"`, e.g. `"20501231235959Z"`. A fractional
/// second is dropped and a leap second is written as `:60`.
///
/// Raises `InvalidAsn1Time` if the year is outside `0..=9999`.
pub fn[Tz] to_generalized_time(
  dt : @tz.DateTime[Tz],
) -> String raise FormatError {
  let (year, tail) = asn1_year_and_tail(dt)
  if year < 0 || year > 9999 {
    raise InvalidAsn1Time
  }
  pad_int(year, 4) + tail
}

///|
/// Parses an ASN.1 `UTCTime` in DER form (`"<YY><MM><DD><HH><MM><SS>Z"`,
/// 13 characters) into a UTC instant. The two-digit year is read by the
/// window of RFC 5280 section 4.1.2.5.1: below 50 is 20xx, from 50 is 19xx.
/// Seconds and an upper-case `Z` are mandatory; an offset, a fractional
/// second, a leap second (`:60`) and surrounding text are rejected, as is a
/// date or time that does not exist.
///
/// Raises `InvalidAsn1Time` for anything else.
pub fn parse_utc_time(s : String) -> @tz.DateTime[@tz.Utc] raise FormatError {
  let naive = asn1_parse_fields(s, 2)
  @tz.DateTime::from_utc(naive, @tz.Utc::new())
}

///|
/// Parses an ASN.1 `GeneralizedTime` in DER form
/// (`"<YYYY><MM><DD><HH><MM><SS>Z"`, 15 characters) into a UTC instant.
/// Seconds and an upper-case `Z` are mandatory; an offset, a fractional
/// second, a leap second (`:60`) and surrounding text are rejected, as is a
/// date or time that does not exist.
///
/// Raises `InvalidAsn1Time` for anything else.
pub fn parse_generalized_time(
  s : String,
) -> @tz.DateTime[@tz.Utc] raise FormatError {
  let naive = asn1_parse_fields(s, 4)
  @tz.DateTime::from_utc(naive, @tz.Utc::new())
}
