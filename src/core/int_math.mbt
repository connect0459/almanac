///|
/// Floor division: rounds toward negative infinity, unlike `Int`'s built-in
/// `/` which truncates toward zero.
fn floor_div(a : Int, b : Int) -> Int {
  let q = a / b
  if a % b != 0 && (a < 0) != (b < 0) {
    q - 1
  } else {
    q
  }
}

///|
/// Floor modulo: the result always has the same sign as `b` (or is zero),
/// unlike `Int`'s built-in `%` which has the same sign as `a`.
fn floor_mod(a : Int, b : Int) -> Int {
  a - floor_div(a, b) * b
}

///|
/// Floor division for `Int64`: rounds toward negative infinity, unlike
/// `Int64`'s built-in `/` which truncates toward zero.
fn floor_div64(a : Int64, b : Int64) -> Int64 {
  let q = a / b
  if a % b != 0L && (a < 0L) != (b < 0L) {
    q - 1L
  } else {
    q
  }
}

///|
/// Floor modulo for `Int64`: the result always has the same sign as `b` (or
/// is zero), unlike `Int64`'s built-in `%` which has the same sign as `a`.
fn floor_mod64(a : Int64, b : Int64) -> Int64 {
  a - floor_div64(a, b) * b
}

///|
/// Adds two `Int64` values, or `None` if the mathematical result does not
/// fit in `Int64`.
fn checked_add64(a : Int64, b : Int64) -> Int64? {
  let sum = a + b
  if (b > 0L && sum < a) || (b < 0L && sum > a) {
    None
  } else {
    Some(sum)
  }
}

///|
/// Multiplies two `Int64` values, or `None` if the mathematical result does
/// not fit in `Int64`.
fn checked_mul64(a : Int64, b : Int64) -> Int64? {
  if a == 0L || b == 0L {
    Some(0L)
  } else {
    let product = a * b
    if product / b != a {
      None
    } else {
      Some(product)
    }
  }
}

///|
fn[T] expect_in_range(value : T?, operation : String) -> T {
  match value {
    Some(v) => v
    None => abort(operation + ": result is outside the representable range")
  }
}
