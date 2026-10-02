import cheekycms/server_config
import gleam/list
import gleeunit/should

pub fn accepts_valid_server_configuration_test() {
  server_config.from_values(
    port: "8080",
    content_root: "content",
    host: "127.0.0.1",
  )
  |> should.equal(
    Ok(
      server_config.Config(
        port: 8080,
        content_root: "content",
        host: "127.0.0.1",
        allowed_origins: ["*"],
      ),
    ),
  )
}

pub fn parses_configured_allowed_origins_test() {
  let assert Ok(server_config.Config(allowed_origins:, ..)) =
    server_config.from_values_with_origins(
      port: "4000",
      content_root: "content",
      host: "localhost",
      allowed_origins: " https://one.example,https://two.example ",
    )

  allowed_origins
  |> should.equal(["https://one.example", "https://two.example"])
}

pub fn rejects_invalid_ports_test() {
  ["nope", "0", "-1", "65536"]
  |> list.each(fn(port) {
    server_config.from_values(port:, content_root: "content", host: "localhost")
    |> should.equal(Error(server_config.InvalidPort(port)))
  })
}

pub fn rejects_empty_paths_and_hosts_test() {
  server_config.from_values(port: "4000", content_root: " ", host: "localhost")
  |> should.equal(Error(server_config.EmptyContentRoot))
  server_config.from_values(port: "4000", content_root: "content", host: " ")
  |> should.equal(Error(server_config.EmptyHost))
}
