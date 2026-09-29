///|
fn pad_zero(value : Int, width : Int) -> String {
  let digits = value.to_string()
  if digits.length() >= width {
    digits
  } else {
    String::make(width - digits.length(), '0') + digits
  }
}

///|
/// A year as `YYYY` for `0..=9999`, otherwise with an explicit sign and at
/// least four digits (`-0001`, `+10000`), as ISO 8601 requires for years
/// outside that range.
fn year_text(year : Int) -> String {
  if year >= 0 && year <= 9999 {
    pad_zero(year, 4)
  } else if year < 0 {
    "-" + pad_zero(-year, 4)
  } else {
    "+" + pad_zero(year, 4)
  }
}

///|
fn Weekday::short_name(self : Weekday) -> String {
  match self {
    Mon => "Mon"
    Tue => "Tue"
    Wed => "Wed"
    Thu => "Thu"
    Fri => "Fri"
    Sat => "Sat"
    Sun => "Sun"
  }
}
