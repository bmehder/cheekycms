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
    Ok(server_config.Config(
      port: 8080,
      content_root: "content",
      host: "127.0.0.1",
    )),
  )
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
