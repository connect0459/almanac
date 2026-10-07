///|
priv enum LocalKind {
  Iana(Location)
  Fixed(FixedOffset)
  Posix(PosixTz)
}

///|
/// The host's configured local time zone. On `native` it is resolved from
/// `$TZ` or, when unset, `/etc/localtime`; on `js` from the runtime's
/// `Intl` zone name; on `wasm` and `wasm-gc` from `$TZ` alone, since neither
/// has host-provided file access.
pub struct Local {
  priv kind : LocalKind
}

///|
/// Resolves `tz_env` (the `TZ` environment variable) into a `Local`, reading
/// files through `read_file` (a path to its raw bytes, `None` if unreadable).
/// One leading `:` of `TZ` is ignored. Then an empty `TZ` (including a lone
/// `:`) means UTC; a `TZ` starting with `/` is the path of a TZif file; any
/// other value is looked up as an IANA zone name and, failing that, parsed as
/// a bare POSIX rule (e.g. `JST-9`). `None` if the value is none of these or
/// the file cannot be read as TZif. When `TZ` is unset entirely,
/// `/etc/localtime` is read instead.
fn Local::resolve(tz_env : String?, read_file : (String) -> Bytes?) -> Local? {
  let from_file = path => {
    read_file(path)
    .bind(bytes => Location::from_tzif_bytes(bytes))
    .map(loc => Local::{ kind: Iana(loc), })
  }
  match tz_env {
    None => from_file("/etc/localtime")
    Some(value) => {
      let name = match value {
        [':', .. rest] => rest.to_owned()
        _ => value
      }
      match name {
        "" => Some(Local::{ kind: Fixed(FixedOffset::east(0).unwrap()), })
        ['/', ..] => from_file(name)
        _ =>
          match Location::load(name) {
            Some(loc) => Some(Local::{ kind: Iana(loc), })
            None => parse_posix_tz(name).map(p => Local::{ kind: Posix(p), })
          }
      }
    }
  }
}

///|
pub impl TimeZone for Local with fn offset_from_utc(self, utc) {
  match self.kind {
    Iana(loc) => loc.offset_from_utc(utc)
    Fixed(off) => off.offset_from_utc(utc)
    Posix(p) => p.offset_from_utc(utc)
  }
}

///|
pub impl TimeZone for Local with fn offset_from_local(self, naive_local) {
  match self.kind {
    Iana(loc) => loc.offset_from_local(naive_local)
    Fixed(off) => off.offset_from_local(naive_local)
    Posix(p) => p.offset_from_local(naive_local)
  }
}

///|
pub impl TimeZone for Local with fn zone_name(self, utc) {
  match self.kind {
    Iana(loc) => loc.zone_name(utc)
    Fixed(off) => off.zone_name(utc)
    Posix(p) => p.zone_name(utc)
  }
}

///|
pub impl TimeZone for Local with fn is_dst(self, utc) {
  match self.kind {
    Iana(loc) => loc.is_dst(utc)
    Fixed(off) => off.is_dst(utc)
    Posix(p) => p.is_dst(utc)
  }
}

///|
pub impl TimeZone for Local with fn transition_bounds(self, utc) {
  match self.kind {
    Iana(loc) => loc.transition_bounds(utc)
    Fixed(off) => off.transition_bounds(utc)
    Posix(p) => p.transition_bounds(utc)
  }
}

///|
pub impl TimeZone for Local with fn offset_from_abbreviation(
  self,
  abbreviation,
  near,
) {
  match self.kind {
    Iana(loc) => loc.offset_from_abbreviation(abbreviation, near)
    Fixed(off) => off.offset_from_abbreviation(abbreviation, near)
    Posix(p) => p.offset_from_abbreviation(abbreviation, near)
  }
}

///|
pub extend Local with TimeZone::{
  offset_from_utc,
  offset_from_local,
  zone_name,
  is_dst,
  transition_bounds,
  offset_from_abbreviation,
}

///|
/// The current instant expressed in the host's local time zone, or `None`
/// if that zone could not be determined (see `Local::new`). The counterpart
/// of `Utc::now`, and like it reads the host clock; the `None` is about the
/// zone, not the clock.
pub fn Local::now() -> DateTime[Local]? {
  Local::new().map(zone => Utc::now().with_timezone(zone))
}
