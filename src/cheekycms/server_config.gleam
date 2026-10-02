import envoy
import gleam/int
import gleam/list
import gleam/result
import gleam/string

const default_port = "4000"

const default_content_root = "content"

const default_host = "0.0.0.0"

const default_allowed_origins = "*"

pub type Config {
  Config(
    port: Int,
    content_root: String,
    host: String,
    allowed_origins: List(String),
  )
}

pub type ConfigError {
  InvalidPort(String)
  EmptyContentRoot
  EmptyHost
}

/// Load server configuration from the process environment.
pub fn load() -> Result(Config, ConfigError) {
  from_values_with_origins(
    port: environment("CHEEKYCMS_PORT", default_port),
    content_root: environment("CHEEKYCMS_CONTENT_ROOT", default_content_root),
    host: environment("CHEEKYCMS_HOST", default_host),
    allowed_origins: environment(
      "CHEEKYCMS_ALLOWED_ORIGINS",
      default_allowed_origins,
    ),
  )
}

/// Validate configuration values independently of the environment.
pub fn from_values(
  port port_value: String,
  content_root content_root_value: String,
  host host_value: String,
) -> Result(Config, ConfigError) {
  from_values_with_origins(
    port: port_value,
    content_root: content_root_value,
    host: host_value,
    allowed_origins: default_allowed_origins,
  )
}

pub fn from_values_with_origins(
  port port_value: String,
  content_root content_root_value: String,
  host host_value: String,
  allowed_origins allowed_origins_value: String,
) -> Result(Config, ConfigError) {
  use port <- result.try(parse_port(port_value))
  let content_root = string.trim(content_root_value)
  let host = string.trim(host_value)

  case content_root, host {
    "", _ -> Error(EmptyContentRoot)
    _, "" -> Error(EmptyHost)
    _, _ ->
      Ok(Config(
        port:,
        content_root:,
        host:,
        allowed_origins: allowed_origins_value
          |> string.split(on: ",")
          |> list.map(string.trim)
          |> list.filter(fn(origin) { origin != "" }),
      ))
  }
}

fn environment(name: String, default: String) -> String {
  envoy.get(name)
  |> result.unwrap(default)
}

fn parse_port(value: String) -> Result(Int, ConfigError) {
  case int.parse(value) {
    Ok(port) if port > 0 && port <= 65_535 -> Ok(port)
    _ -> Error(InvalidPort(value))
  }
}
