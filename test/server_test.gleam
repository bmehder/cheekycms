import cheekycms/catalogue
import cheekycms/catalogue_store
import cheekycms/discovery
import cheekycms/server
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import gleeunit/should

fn fixture_catalogue() -> catalogue.Catalogue {
  let assert Ok(value) = discovery.discover("test/fixtures/content")
  value
}

pub fn serves_the_public_landing_page_test() {
  let request = request.new() |> request.set_path("/")
  let result = server.response_for(request, fixture_catalogue())

  result.status |> should.equal(200)
  response.get_header(result, "content-type")
  |> should.equal(Ok("text/html; charset=utf-8"))
  response.get_header(result, "content-security-policy")
  |> should.be_ok
  string.contains(result.body, "A cheeky little")
  |> should.be_true
  string.contains(result.body, "Not the greatest new thing")
  |> should.be_true
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

pub fn passes_decoded_query_parameters_to_the_api_test() {
  let request =
    request.new()
    |> request.set_path("/api/personal-site/collections/posts")
    |> request.set_query([#("featured", "true")])
  let result = server.response_for(request, fixture_catalogue())

  result.status |> should.equal(200)
  result.body
  |> json.parse(using: {
    use items <- decode.field("items", decode.list(decode.dynamic))
    decode.success(list.length(items))
  })
  |> should.equal(Ok(1))
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
  |> should.equal(Ok("GET, OPTIONS"))
  result.body
  |> json.parse(using: {
    use code <- decode.subfield(["error", "code"], decode.string)
    decode.success(code)
  })
  |> should.equal(Ok("method_not_allowed"))
}

pub fn allows_public_browser_requests_and_preflights_test() {
  let get_request =
    request.new()
    |> request.set_header("origin", "https://svelte.dev")
    |> request.set_path("/api")
  let options_request =
    get_request
    |> request.set_method(http.Options)
  let get_response = server.response_for(get_request, fixture_catalogue())
  let options_response =
    server.response_for(options_request, fixture_catalogue())

  response.get_header(get_response, "access-control-allow-origin")
  |> should.equal(Ok("*"))
  options_response.status
  |> should.equal(204)
  response.get_header(options_response, "access-control-allow-methods")
  |> should.equal(Ok("GET, OPTIONS"))
}

pub fn restricts_browser_requests_to_configured_origins_test() {
  let allowed_request =
    request.new()
    |> request.set_header("origin", "https://allowed.example")
    |> request.set_path("/api")
  let rejected_request =
    request.new()
    |> request.set_header("origin", "https://rejected.example")
    |> request.set_path("/api")
  let origins = ["https://allowed.example"]

  let allowed =
    server.response_for_with_origins(
      allowed_request,
      fixture_catalogue(),
      origins,
    )
  response.get_header(allowed, "access-control-allow-origin")
  |> should.equal(Ok("https://allowed.example"))
  response.get_header(allowed, "vary")
  |> should.equal(Ok("Origin"))

  server.response_for_with_origins(
    rejected_request,
    fixture_catalogue(),
    origins,
  )
  |> response.get_header("access-control-allow-origin")
  |> should.equal(Error(Nil))
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
