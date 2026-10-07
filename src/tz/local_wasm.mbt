///|
/// The host's configured local time zone, or `None` if it could not be
/// determined. Reads live host state (`$TZ`), so it is not a pure function of
/// its arguments; the `$TZ` precedence rules it applies are described on
/// `Local`. With `$TZ` unset there is nothing to fall back on, since these
/// backends have no file access, so the result is `None`.
pub fn Local::new() -> Local? {
  Local::resolve(@env.get_env_var("TZ"), _ => None)
}
