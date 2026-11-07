//// Connect the content pipeline and runtime store to Mist.
////
//// Startup loads the catalogue, starts its actor and filesystem watcher, and opens
//// the HTTP listener. Live requests check reference files and assets before
//// handing website routes to `marketing` and other requests to the content API.
//// Supporting web modules own file streaming and CORS; socket-free response
//// functions support adapter tests.

import cheekycms/api
import cheekycms/content/catalogue
import cheekycms/content/load as discovery
import cheekycms/runtime/store as catalogue_store
import cheekycms/web/asset
import cheekycms/web/config as server_config
import cheekycms/web/cors
import cheekycms/web/files
import cheekycms/web/reference
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/result
import marketing
import mist
import polly

/// Failures during initial discovery, actor/watcher startup, or HTTP startup.
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
    handle_live(request, store, config.asset_root, config.allowed_origins)
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
  asset_root: String,
  allowed_origins: List(String),
) -> Response(mist.ResponseData) {
  case reference.resolve(request.path, "reference") {
    Ok(resolved) -> files.respond(request, resolved, allowed_origins)
    Error(reference.InvalidPath) ->
      api.error_response(
        400,
        "invalid_reference_path",
        "The reference path is invalid.",
      )
      |> files.from_api
      |> cors.add(request, allowed_origins)
    Error(reference.NotReferenceRoute) ->
      handle_asset_live(request, store, asset_root, allowed_origins)
  }
}

fn handle_asset_live(
  request: Request(mist.Connection),
  store: catalogue_store.Store,
  asset_root: String,
  allowed_origins: List(String),
) -> Response(mist.ResponseData) {
  case asset.resolve(request.path, asset_root) {
    Ok(resolved) -> files.respond(request, resolved, allowed_origins)
    Error(asset.InvalidPath) ->
      api.error_response(
        400,
        "invalid_asset_path",
        "The asset path is invalid.",
      )
      |> files.from_api
      |> cors.add(request, allowed_origins)
    Error(asset.NotAssetRoute) ->
      api_response_live(request, store, allowed_origins)
  }
}

fn api_response_live(
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

/// Build a socket-free response and apply an explicit browser origin policy.
pub fn response_for_with_origins(
  request: Request(body),
  content_catalogue: catalogue.Catalogue,
  allowed_origins: List(String),
) -> Response(String) {
  response_for_request(request, content_catalogue)
  |> cors.add(request, allowed_origins)
}

/// Build a socket-free response using a catalogue and its reload status.
/// Health requests report that status; other routes use the same catalogue.
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
    _, _ -> response_for_request(request, content_catalogue)
  }
  |> cors.add(request, allowed_origins)
}

// The single connection to the demo website; unclaimed routes go to the CMS API.
fn response_for_request(
  request: Request(body),
  content_catalogue: catalogue.Catalogue,
) -> Response(String) {
  case marketing.handle(request, content_catalogue) {
    Ok(page) -> page
    Error(Nil) -> response_for_api(request, content_catalogue)
  }
}

fn response_for_api(
  request: Request(body),
  content_catalogue: catalogue.Catalogue,
) -> Response(String) {
  case request.method {
    http.Get -> {
      let api_response = case request.get_query(request) {
        Ok(parameters) ->
          api.handle_with_query(content_catalogue, request.path, parameters)
        Error(Nil) ->
          api.error_response(
            400,
            "invalid_query_encoding",
            "The query string contains invalid percent encoding.",
          )
      }
      to_http_response(api_response)
    }
    http.Options ->
      api.Response(status: 204, content_type: api.json_content_type, body: "")
      |> to_http_response
    _ ->
      api.error_response(
        405,
        "method_not_allowed",
        "Only GET requests are supported.",
      )
      |> to_http_response
  }
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
