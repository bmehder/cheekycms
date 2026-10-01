import cheekycms/catalogue
import cheekycms/discovery
import cheekycms/server
import gleam/dynamic/decode
import gleam/http
import gleam/http/request
import gleam/http/response
import gleam/json
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
