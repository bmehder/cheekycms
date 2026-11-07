//// Application entry point.
////
//// Loads environment configuration, starts the HTTP server, and keeps the main
//// process alive. See `cheekycms/web/server` for startup and request handling.

import cheekycms/web/config as server_config
import cheekycms/web/server
import gleam/erlang/process
import gleam/string

/// Load configuration, start the server, and keep the application alive.
/// Invalid configuration or startup failures stop the application with a message.
pub fn main() -> Nil {
  let config = case server_config.load() {
    Ok(config) -> config
    Error(error) -> {
      let message =
        "Invalid CheekyCMS server configuration: " <> string.inspect(error)
      panic as message
    }
  }

  case server.start(config) {
    Ok(Nil) -> process.sleep_forever()
    Error(error) -> {
      let message =
        "CheekyCMS server failed to start: " <> string.inspect(error)
      panic as message
    }
  }
}
