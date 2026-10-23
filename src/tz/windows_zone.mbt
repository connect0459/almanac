///|
/// The IANA zone name of the Windows zone key name `key` (e.g.
/// `"Tokyo Standard Time"`), taken from the territory `001` entry of the
/// embedded CLDR mapping. `None` if `key` is empty or absent from the
/// mapping. Matching is exact.
fn windows_zone_iana_name(key : String) -> String? {
  windows_zone_iana_names.get(key)
}

///|
/// The `Local` zone for the Windows zone key name `key`, following the rules
/// of the IANA zone it maps to in the embedded database. `None` if `key` has
/// no mapping; the zone is never assumed to be UTC.
fn Local::from_windows_zone(key : String) -> Local? {
  windows_zone_iana_name(key)
  .bind(name => Location::load(name))
  .map(loc => Local::{ kind: Iana(loc), })
}
