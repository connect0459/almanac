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
