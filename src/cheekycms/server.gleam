import cheekycms/api
import cheekycms/catalogue
import cheekycms/discovery
import cheekycms/server_config
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/result
import mist

pub type StartError {
  ContentDiscoveryFailed(List(discovery.DiscoveryError))
  ServerStartFailed
}

/// Start the BEAM HTTP server after loading the complete content catalogue.
pub fn start(config: server_config.Config) -> Result(Nil, StartError) {
  use content_catalogue <- result.try(
    discovery.discover(config.content_root)
    |> result.map_error(ContentDiscoveryFailed),
  )

  fn(request: Request(mist.Connection)) -> Response(mist.ResponseData) {
    handle(request, content_catalogue)
  }
  |> mist.new
  |> mist.bind(config.host)
  |> mist.port(config.port)
  |> mist.start
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(_) { ServerStartFailed })
}

/// Adapt a Mist request to the transport-neutral API response.
pub fn handle(
  request: Request(mist.Connection),
  content_catalogue: catalogue.Catalogue,
) -> Response(mist.ResponseData) {
  request
  |> response_for(content_catalogue)
  |> response.map(fn(body) { mist.Bytes(bytes_tree.from_string(body)) })
}

/// Handle a request without requiring a live socket, for adapter tests.
pub fn response_for(
  request: Request(body),
  content_catalogue: catalogue.Catalogue,
) -> Response(String) {
  let api_response = case request.method {
    http.Get -> api.handle(content_catalogue, request.path)
    _ ->
      api.error_response(
        405,
        "method_not_allowed",
        "Only GET requests are supported.",
      )
  }
  let api.Response(status:, content_type:, body:) = api_response
  let response =
    response.new(status)
    |> response.set_header("content-type", content_type)
    |> response.set_body(body)

  case status == 405 {
    True -> response.set_header(response, "allow", "GET")
    False -> response
  }
}
