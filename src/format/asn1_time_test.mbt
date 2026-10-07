///|
fn asn1_utc(
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
fn assert_invalid_utc_time(input : String) -> Unit raise {
  try @format.parse_utc_time(input) |> ignore catch {
    @format.InvalidAsn1Time => ()
    _ => fail("expected InvalidAsn1Time for \{input}")
  } noraise {
    _ => fail("expected InvalidAsn1Time for \{input}")
  }
}

///|
fn assert_invalid_generalized_time(input : String) -> Unit raise {
  try @format.parse_generalized_time(input) |> ignore catch {
    @format.InvalidAsn1Time => ()
    _ => fail("expected InvalidAsn1Time for \{input}")
  } noraise {
    _ => fail("expected InvalidAsn1Time for \{input}")
  }
}

///|
test "to_utc_time writes a two-digit year, seconds and a Z" {
  assert_eq(
    @format.to_utc_time(asn1_utc(1991, 5, 6, 23, 45, 40)),
    "910506234540Z",
  )
  assert_eq(@format.to_utc_time(asn1_utc(2010, 1, 2, 3, 4, 5)), "100102030405Z")
}

///|
test "to_utc_time covers exactly the years 1950 through 2049" {
  assert_eq(@format.to_utc_time(asn1_utc(1950, 1, 1, 0, 0, 0)), "500101000000Z")
  assert_eq(
    @format.to_utc_time(asn1_utc(2049, 12, 31, 23, 59, 59)),
    "491231235959Z",
  )
  for year in [1949, 2050, 0, 9999] {
    try @format.to_utc_time(asn1_utc(year, 1, 1, 0, 0, 0)) |> ignore catch {
      @format.InvalidAsn1Time => ()
      _ => fail("expected InvalidAsn1Time for year \{year}")
    } noraise {
      _ => fail("expected InvalidAsn1Time for year \{year}")
    }
  }
}

///|
test "to_utc_time renders the UTC instant of a zoned value" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms(23, 30, 0).unwrap(),
    ),
    @tz.FixedOffset::east(9 * 3600).unwrap(),
  )
  assert_eq(@format.to_utc_time(dt), "240305233000Z")
  assert_eq(@format.to_generalized_time(dt), "20240305233000Z")
}

///|
test "to_utc_time and to_generalized_time drop a fractional second" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2024, 3, 5).unwrap(),
      @core.NaiveTime::from_hms_nano(9, 30, 15, 999_999_999).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@format.to_utc_time(dt), "240305093015Z")
  assert_eq(@format.to_generalized_time(dt), "20240305093015Z")
}

///|
test "to_generalized_time writes a four-digit year, seconds and a Z" {
  assert_eq(
    @format.to_generalized_time(asn1_utc(2010, 1, 2, 3, 4, 5)),
    "20100102030405Z",
  )
  assert_eq(
    @format.to_generalized_time(asn1_utc(2050, 12, 31, 23, 59, 59)),
    "20501231235959Z",
  )
}

///|
test "to_generalized_time covers exactly the years 0 through 9999" {
  assert_eq(
    @format.to_generalized_time(asn1_utc(0, 1, 1, 0, 0, 0)),
    "00000101000000Z",
  )
  assert_eq(
    @format.to_generalized_time(asn1_utc(9999, 12, 31, 23, 59, 59)),
    "99991231235959Z",
  )
  let negative = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(-1, 1, 1).unwrap(),
      @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  let beyond = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(10000, 1, 1).unwrap(),
      @core.NaiveTime::from_hms(0, 0, 0).unwrap(),
    ),
    @tz.Utc::new(),
  )
  for dt in [negative, beyond] {
    try @format.to_generalized_time(dt) |> ignore catch {
      @format.InvalidAsn1Time => ()
      _ => fail("expected InvalidAsn1Time")
    } noraise {
      _ => fail("expected InvalidAsn1Time")
    }
  }
}

///|
test "parse_utc_time reads a two-digit year of 49 and under as 20xx and 50 and over as 19xx" {
  assert_eq(
    @format.parse_utc_time("910506234540Z"),
    asn1_utc(1991, 5, 6, 23, 45, 40),
  )
  assert_eq(
    @format.parse_utc_time("500101000000Z"),
    asn1_utc(1950, 1, 1, 0, 0, 0),
  )
  assert_eq(
    @format.parse_utc_time("491231235959Z"),
    asn1_utc(2049, 12, 31, 23, 59, 59),
  )
  assert_eq(
    @format.parse_utc_time("000101000000Z"),
    asn1_utc(2000, 1, 1, 0, 0, 0),
  )
}

///|
test "parse_utc_time reads back every year to_utc_time can write" {
  for year in 1950..<2050 {
    let dt = asn1_utc(year, 6, 15, 12, 30, 45)
    assert_eq(@format.parse_utc_time(@format.to_utc_time(dt)), dt)
  }
}

///|
test "parse_utc_time rejects a missing Z, missing seconds, an offset or a fraction" {
  assert_invalid_utc_time("910506234540")
  assert_invalid_utc_time("9105062345Z")
  assert_invalid_utc_time("910506234540z")
  assert_invalid_utc_time("910506164540-0700")
  assert_invalid_utc_time("910506164540+0730")
  assert_invalid_utc_time("910506234540.5Z")
  assert_invalid_utc_time("")
  assert_invalid_utc_time("Z")
}

///|
test "parse_utc_time rejects stray characters and wrong widths" {
  assert_invalid_utc_time("a10506234540Z")
  assert_invalid_utc_time("91a506234540Z")
  assert_invalid_utc_time("9105a6234540Z")
  assert_invalid_utc_time("910506a34540Z")
  assert_invalid_utc_time("910506334a40Z")
  assert_invalid_utc_time("91050633444aZ")
  assert_invalid_utc_time("910506234540Za")
  assert_invalid_utc_time(" 910506234540Z")
  assert_invalid_utc_time("910506234540Z ")
  assert_invalid_utc_time("1910506234540Z")
  assert_invalid_utc_time("-10102030410Z")
  assert_invalid_utc_time("10-0102030410Z")
  assert_invalid_utc_time("1001-02030410Z")
  assert_invalid_utc_time("100102-030410Z")
  assert_invalid_utc_time("10010203-0410Z")
  assert_invalid_utc_time("1001020304-10Z")
}

///|
test "parse_utc_time rejects dates and times that do not exist" {
  assert_invalid_utc_time("101302030405Z")
  assert_invalid_utc_time("100002030405Z")
  assert_invalid_utc_time("100100030405Z")
  assert_invalid_utc_time("100132030405Z")
  assert_invalid_utc_time("100231030405Z")
  assert_invalid_utc_time("100229030405Z")
  assert_invalid_utc_time("100102240405Z")
  assert_invalid_utc_time("100102036005Z")
  assert_invalid_utc_time("100102030460Z")
  assert_invalid_utc_time("910506334461Z")
}

///|
test "parse_utc_time accepts February 29 only in a leap year of the window" {
  assert_eq(
    @format.parse_utc_time("240229000000Z"),
    asn1_utc(2024, 2, 29, 0, 0, 0),
  )
  assert_eq(
    @format.parse_utc_time("000229000000Z"),
    asn1_utc(2000, 2, 29, 0, 0, 0),
  )
}

///|
test "parse_generalized_time reads a four-digit year, seconds and a Z" {
  assert_eq(
    @format.parse_generalized_time("20100102030405Z"),
    asn1_utc(2010, 1, 2, 3, 4, 5),
  )
  assert_eq(
    @format.parse_generalized_time("20501231235959Z"),
    asn1_utc(2050, 12, 31, 23, 59, 59),
  )
  assert_eq(
    @format.parse_generalized_time("19491231235959Z"),
    asn1_utc(1949, 12, 31, 23, 59, 59),
  )
}

///|
test "parse_generalized_time reads back every year to_generalized_time can write" {
  for year in [0, 1, 999, 1000, 1949, 1950, 2049, 2050, 9999] {
    let dt = asn1_utc(year, 6, 15, 12, 30, 45)
    assert_eq(
      @format.parse_generalized_time(@format.to_generalized_time(dt)),
      dt,
    )
  }
}

///|
test "parse_generalized_time rejects a missing Z, an offset or a fraction" {
  assert_invalid_generalized_time("20100102030405")
  assert_invalid_generalized_time("20100102030405z")
  assert_invalid_generalized_time("20100102030405+0607")
  assert_invalid_generalized_time("20100102030405-0607")
  assert_invalid_generalized_time("20100102030405.123456Z")
  assert_invalid_generalized_time("20100102030405.Z")
  assert_invalid_generalized_time("20100102030405.")
  assert_invalid_generalized_time("")
  assert_invalid_generalized_time("Z")
}

///|
test "parse_generalized_time rejects missing seconds, stray characters and wrong widths" {
  assert_invalid_generalized_time("201001020304Z")
  assert_invalid_generalized_time("a0100102030405Z")
  assert_invalid_generalized_time("2010010203040aZ")
  assert_invalid_generalized_time("20100102030405Za")
  assert_invalid_generalized_time(" 20100102030405Z")
  assert_invalid_generalized_time("20100102030405Z ")
  assert_invalid_generalized_time("100102030405Z")
  assert_invalid_generalized_time("120100102030405Z")
  assert_invalid_generalized_time("-20100102030410Z")
  assert_invalid_generalized_time("2010-0102030410Z")
  assert_invalid_generalized_time("201001-02030410Z")
  assert_invalid_generalized_time("20100102-030410Z")
  assert_invalid_generalized_time("2010010203-0410Z")
  assert_invalid_generalized_time("201001020304-10Z")
}

///|
test "parse_generalized_time rejects dates and times that do not exist" {
  assert_invalid_generalized_time("20101302030405Z")
  assert_invalid_generalized_time("20100002030405Z")
  assert_invalid_generalized_time("20100100030405Z")
  assert_invalid_generalized_time("20100132030405Z")
  assert_invalid_generalized_time("20100231030405Z")
  assert_invalid_generalized_time("21000229000000Z")
  assert_invalid_generalized_time("20100102240405Z")
  assert_invalid_generalized_time("20100102036005Z")
  assert_invalid_generalized_time("20100102030460Z")
}

///|
test "parse_generalized_time accepts February 29 in a leap year only" {
  assert_eq(
    @format.parse_generalized_time("20000229000000Z"),
    asn1_utc(2000, 2, 29, 0, 0, 0),
  )
}

///|
test "to_utc_time and to_generalized_time render a leap second as :60" {
  let dt = @tz.DateTime::from_utc(
    @core.NaiveDateTime::new(
      @core.NaiveDate::from_ymd(2016, 12, 31).unwrap(),
      @core.NaiveTime::from_hms_nano(23, 59, 59, 1_500_000_000).unwrap(),
    ),
    @tz.Utc::new(),
  )
  assert_eq(@format.to_utc_time(dt), "161231235960Z")
  assert_eq(@format.to_generalized_time(dt), "20161231235960Z")
}

///|
test "parse_utc_time and parse_generalized_time do not read a leap second back" {
  assert_invalid_utc_time("161231235960Z")
  assert_invalid_generalized_time("20161231235960Z")
}
