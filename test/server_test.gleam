import cheekycms/catalogue
import cheekycms/catalogue_store
import cheekycms/discovery
import cheekycms/server
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/option
import gleeunit/should

fn fixture_catalogue() -> catalogue.Catalogue {
  let assert Ok(value) = discovery.discover("test/fixtures/content")
  value
}

pub fn adapts_get_requests_test() {
  let request =
    request.new()
    |> request.set_path("/api/personal-site/singletons/homepage")
  let result = server.response_for(request, fixture_catalogue())

  result.status
  |> should.equal(200)
  response.get_header(result, "content-type")
  |> should.equal(Ok("application/json; charset=utf-8"))
  result.body
  |> json.parse(using: {
    use name <- decode.field("name", decode.string)
    decode.success(name)
  })
  |> should.equal(Ok("homepage"))
}

pub fn rejects_non_get_requests_test() {
  let request =
    request.new()
    |> request.set_method(http.Post)
    |> request.set_path("/api")
  let result = server.response_for(request, fixture_catalogue())

  result.status
  |> should.equal(405)
  response.get_header(result, "allow")
  |> should.equal(Ok("GET"))
  result.body
  |> json.parse(using: {
    use code <- decode.subfield(["error", "code"], decode.string)
    decode.success(code)
  })
  |> should.equal(Ok("method_not_allowed"))
}

pub fn serves_reload_health_as_json_test() {
  let request = request.new() |> request.set_path("/health")
  let status =
    catalogue_store.Status(
      catalogue_size: 3,
      successful_reloads: 2,
      last_successful_reload: "2026-10-02T12:00:00Z",
      last_reload_attempt: "2026-10-02T12:01:00Z",
      last_error: option.Some("bad frontmatter"),
    )
  let result =
    server.response_for_snapshot(request, fixture_catalogue(), status)

  result.status
  |> should.equal(200)
  result.body
  |> json.parse(using: {
    use state <- decode.field("status", decode.string)
    use size <- decode.field("catalogue_size", decode.int)
    use reloads <- decode.field("successful_reloads", decode.int)
    use error <- decode.field("last_error", decode.string)
    decode.success(#(state, size, reloads, error))
  })
  |> should.equal(Ok(#("degraded", 3, 2, "bad frontmatter")))
}
