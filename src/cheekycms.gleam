import cheekycms/server
import cheekycms/server_config
import gleam/erlang/process
import gleam/string

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
