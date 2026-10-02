import cheekycms/api
import cheekycms/asset
import cheekycms/catalogue
import cheekycms/catalogue_store
import cheekycms/content
import cheekycms/discovery
import cheekycms/identifier
import cheekycms/landing
import cheekycms/metadata as content_metadata
import cheekycms/server_config
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/list
import gleam/option
import gleam/result
import mist
import polly
import simplifile

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
  case asset.resolve(request.path, asset_root) {
    Ok(resolved) -> asset_response(request, resolved, allowed_origins)
    Error(asset.InvalidPath) ->
      api.error_response(
        400,
        "invalid_asset_path",
        "The asset path is invalid.",
      )
      |> to_mist_response
      |> add_cors(request, allowed_origins)
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

fn asset_response(
  request: Request(mist.Connection),
  resolved: asset.Asset,
  allowed_origins: List(String),
) -> Response(mist.ResponseData) {
  let asset.Asset(path:, content_type:, download:) = resolved
  let response = case request.method {
    http.Get -> get_asset_response(request, path, content_type, download)
    http.Options ->
      response.new(204)
      |> response.set_body(mist.Bytes(bytes_tree.from_string("")))
    _ ->
      api.error_response(
        405,
        "method_not_allowed",
        "Only GET requests are supported.",
      )
      |> to_mist_response
      |> response.set_header("allow", "GET, OPTIONS")
  }

  response
  |> response.set_header("x-content-type-options", "nosniff")
  |> add_cors(request, allowed_origins)
}

fn get_asset_response(
  request: Request(mist.Connection),
  path: String,
  content_type: String,
  download: Bool,
) -> Response(mist.ResponseData) {
  case simplifile.file_info(path) {
    Error(_) ->
      api.error_response(404, "asset_not_found", "The asset was not found.")
      |> to_mist_response
    Ok(info) -> {
      let simplifile.FileInfo(size:, ..) = info
      case request.get_header(request, "range") {
        Error(Nil) -> send_asset(path, 0, size, 200, content_type, download)
        Ok(range_header) ->
          case asset.parse_range(range_header, size) {
            Ok(asset.ByteRange(offset:, length:)) ->
              send_asset(path, offset, length, 206, content_type, download)
              |> response.set_header(
                "content-range",
                "bytes "
                  <> int.to_string(offset)
                  <> "-"
                  <> int.to_string(offset + length - 1)
                  <> "/"
                  <> int.to_string(size),
              )
            Error(_) ->
              api.error_response(
                416,
                "range_not_satisfiable",
                "The requested byte range is not available.",
              )
              |> to_mist_response
              |> response.set_header(
                "content-range",
                "bytes */" <> int.to_string(size),
              )
          }
      }
    }
  }
}

fn send_asset(
  path: String,
  offset: Int,
  length: Int,
  status: Int,
  content_type: String,
  download: Bool,
) -> Response(mist.ResponseData) {
  case mist.send_file(path, offset:, limit: option.Some(length)) {
    Ok(body) ->
      response.new(status)
      |> response.set_body(body)
      |> response.set_header("accept-ranges", "bytes")
      |> asset_headers(content_type, download)
    Error(_) ->
      api.error_response(404, "asset_not_found", "The asset was not found.")
      |> to_mist_response
  }
}

fn asset_headers(
  asset_response: Response(mist.ResponseData),
  content_type: String,
  download: Bool,
) -> Response(mist.ResponseData) {
  let asset_response =
    asset_response
    |> response.set_header("content-type", content_type)
    |> response.set_header("x-content-type-options", "nosniff")
    |> response.set_header("cache-control", "public, max-age=3600")

  case download {
    True ->
      response.set_header(asset_response, "content-disposition", "attachment")
    False -> asset_response
  }
}

fn to_mist_response(api_response: api.Response) -> Response(mist.ResponseData) {
  let api.Response(status:, content_type:, body:) = api_response
  response.new(status)
  |> response.set_header("content-type", content_type)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
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
  case request.method, request.path {
    http.Get, "/" -> homepage_response(content_catalogue)
    http.Get, _ -> {
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
    http.Options, _ ->
      api.Response(status: 204, content_type: api.json_content_type, body: "")
      |> to_http_response
    _, _ ->
      api.error_response(
        405,
        "method_not_allowed",
        "Only GET requests are supported.",
      )
      |> to_http_response
  }
}

fn homepage_response(
  content_catalogue: catalogue.Catalogue,
) -> Response(String) {
  let assert Ok(project) = identifier.project_id("cheekycms")
  let assert Ok(name) = identifier.content_name("homepage")
  let homepage =
    catalogue.get(
      content_catalogue,
      content.Singleton(project: project, name: name),
    )
  let #(title, description, body) = case homepage {
    Ok(catalogue.Item(
      content: content.RenderedContent(metadata:, body:, ..),
      ..,
    )) -> #(
      metadata_string(metadata, "title", "CheekyCMS — Markdown in, JSON out"),
      metadata_string(
        metadata,
        "description",
        "A cheeky little Markdown content API, written in Gleam.",
      ),
      content.html_to_string(body),
    )
    Error(Nil) -> #(
      "CheekyCMS",
      "A cheeky little Markdown content API, written in Gleam.",
      "<main class='hero'><div class='wrap'><h1>CheekyCMS</h1><p class='lede'>Add content/cheekycms/singletons/homepage.md to author this page with CheekyCMS.</p></div></main>",
    )
  }

  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_header("cache-control", "public, max-age=300")
  |> response.set_header("x-content-type-options", "nosniff")
  |> response.set_header("referrer-policy", "strict-origin-when-cross-origin")
  |> response.set_header("x-frame-options", "DENY")
  |> response.set_header(
    "content-security-policy",
    "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  )
  |> response.set_body(landing.html(title, description, body))
}

fn metadata_string(
  metadata: content_metadata.Metadata,
  key: String,
  fallback: String,
) -> String {
  case content_metadata.get(metadata, key) {
    Ok(content_metadata.StringValue(value)) -> value
    _ -> fallback
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

fn add_cors(
  api_response: Response(response_body),
  request: Request(request_body),
  allowed_origins: List(String),
) -> Response(response_body) {
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
        |> response.set_header(
          "access-control-expose-headers",
          "content-length, content-range, accept-ranges",
        )
        |> response.set_header("access-control-max-age", "86400")
      case origin == "*" {
        True -> with_cors
        False -> response.set_header(with_cors, "vary", "Origin")
      }
    }
  }
}
