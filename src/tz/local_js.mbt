///|
extern "js" fn host_zone_name() -> String? =
  #| function() {
  #|   try {
  #|     const name = Intl.DateTimeFormat().resolvedOptions().timeZone;
  #|     return typeof name === "string" && name.length > 0 ? name : null;
  #|   } catch (_) {
  #|     return null;
  #|   }
  #| }

///|
/// The host's configured local time zone, or `None` if it could not be
/// determined. Reads the runtime's `Intl` zone name, so it is not a pure
/// function of its arguments; the name is resolved as a `$TZ` value would be.
pub fn Local::new() -> Local? {
  match host_zone_name() {
    Some(name) => Local::resolve(Some(name), _ => None)
    None => None
  }
}

///|
/// Loads the embedded zone `name`, exactly like `Location::load`: this
/// backend has no file access, so there is no system zoneinfo to consult.
pub fn Location::load_system(name : String) -> Location? {
  Location::load(name)
}
