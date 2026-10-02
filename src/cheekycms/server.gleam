import cheekycms/api
import cheekycms/catalogue
import cheekycms/catalogue_store
import cheekycms/discovery
import cheekycms/server_config
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list
import gleam/result
import mist
import polly

pub type StartError {
  ContentDiscoveryFailed(List(discovery.DiscoveryError))
  CatalogueStoreStartFailed
  ContentWatcherStartFailed
  ServerStartFailed
}

/// Start the BEAM HTTP server after loading the complete content catalogue.
pub fn start(config: server_config.Config) -> Result(Nil, StartError) {
  use content_catalogue <- result.try(
    discovery.discover(config.content_root)
    |> result.map_error(ContentDiscoveryFailed),
  )
  use store <- result.try(
    catalogue_store.start(content_catalogue, config.content_root)
    |> result.map_error(fn(_) { CatalogueStoreStartFailed }),
  )
  use _watcher <- result.try(
    polly.new()
    |> polly.add_dir(config.content_root)
    |> polly.interval(500)
    |> polly.add_callback(fn(_) { catalogue_store.reload(store) })
    |> polly.watch
    |> result.map_error(fn(_) { ContentWatcherStartFailed }),
  )

  fn(request: Request(mist.Connection)) -> Response(mist.ResponseData) {
    handle_live(request, store, config.allowed_origins)
  }
  |> mist.new
  |> mist.bind(config.host)
  |> mist.port(config.port)
  |> mist.start
  |> result.map(fn(_) { Nil })
  |> result.map_error(fn(_) { ServerStartFailed })
}

fn handle_live(
  request: Request(mist.Connection),
  store: catalogue_store.Store,
  allowed_origins: List(String),
) -> Response(mist.ResponseData) {
  let catalogue_store.Snapshot(catalogue:, status:) =
    catalogue_store.snapshot(store)
  request
  |> response_for_snapshot_with_origins(catalogue, status, allowed_origins)
  |> response.map(fn(body) { mist.Bytes(bytes_tree.from_string(body)) })
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
  response_for_with_origins(request, content_catalogue, ["*"])
}

pub fn response_for_with_origins(
  request: Request(body),
  content_catalogue: catalogue.Catalogue,
  allowed_origins: List(String),
) -> Response(String) {
  response_for_api(request, content_catalogue)
  |> add_cors(request, allowed_origins)
}

pub fn response_for_snapshot(
  request: Request(body),
  content_catalogue: catalogue.Catalogue,
  status: catalogue_store.Status,
) -> Response(String) {
  response_for_snapshot_with_origins(request, content_catalogue, status, ["*"])
}

fn response_for_snapshot_with_origins(
  request: Request(body),
  content_catalogue: catalogue.Catalogue,
  status: catalogue_store.Status,
  allowed_origins: List(String),
) -> Response(String) {
  case request.method, request.path {
    http.Get, "/health" -> api.health(status) |> to_http_response
    _, _ -> response_for_api(request, content_catalogue)
  }
  |> add_cors(request, allowed_origins)
}

fn response_for_api(
  request: Request(body),
  content_catalogue: catalogue.Catalogue,
) -> Response(String) {
  let api_response = case request.method {
    http.Get -> api.handle(content_catalogue, request.path)
    http.Options ->
      api.Response(status: 204, content_type: api.json_content_type, body: "")
    _ ->
      api.error_response(
        405,
        "method_not_allowed",
        "Only GET requests are supported.",
      )
  }
  to_http_response(api_response)
}

fn to_http_response(api_response: api.Response) -> Response(String) {
  let api.Response(status:, content_type:, body:) = api_response
  let response =
    response.new(status)
    |> response.set_header("content-type", content_type)
    |> response.set_body(body)

  case status == 405 {
    True -> response.set_header(response, "allow", "GET, OPTIONS")
    False -> response
  }
}

fn add_cors(
  api_response: Response(String),
  request: Request(body),
  allowed_origins: List(String),
) -> Response(String) {
  let allowed_origin = case list.contains(allowed_origins, "*") {
    True -> Ok("*")
    False ->
      case request.get_header(request, "origin") {
        Error(Nil) -> Error(Nil)
        Ok(origin) ->
          case list.contains(allowed_origins, origin) {
            True -> Ok(origin)
            False -> Error(Nil)
          }
      }
  }

  case allowed_origin {
    Error(Nil) -> api_response
    Ok(origin) -> {
      let with_cors =
        api_response
        |> response.set_header("access-control-allow-origin", origin)
        |> response.set_header("access-control-allow-methods", "GET, OPTIONS")
        |> response.set_header("access-control-allow-headers", "content-type")
        |> response.set_header("access-control-max-age", "86400")
      case origin == "*" {
        True -> with_cors
        False -> response.set_header(with_cors, "vary", "Origin")
      }
    }
  }
}
