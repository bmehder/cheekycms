//// Stream public assets and generated reference files through Mist.
////
//// Handles file lookup, GET and OPTIONS requests, download headers, and single
//// byte-range responses. Path validation happens in the asset and reference
//// resolvers before a file reaches this module.

import cheekycms/api
import cheekycms/web/asset
import cheekycms/web/cors
import gleam/bytes_tree
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/int
import gleam/option
import mist
import simplifile

/// Serve a file already validated by an asset or reference resolver.
/// Supports GET, OPTIONS, and single byte ranges; other methods return 405.
pub fn respond(
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
      |> from_api
      |> response.set_header("allow", "GET, OPTIONS")
  }

  response
  |> response.set_header("x-content-type-options", "nosniff")
  |> cors.add(request, allowed_origins)
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
      |> from_api
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
              |> from_api
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
      |> from_api
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

/// Adapt plain API response data to a Mist byte response.
pub fn from_api(api_response: api.Response) -> Response(mist.ResponseData) {
  let api.Response(status:, content_type:, body:) = api_response
  response.new(status)
  |> response.set_header("content-type", content_type)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(body)))
}
