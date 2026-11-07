//// Coordinate the read-only content API.
////
//// Parses routes, selects content, applies collection controls, and encodes results.
//// Responses contain plain status, media type, and body values so callers can use
//// the API without a live HTTP server. Also supplies discovery, health, and
//// consistent error responses.

import cheekycms/api/filter as collection_query
import cheekycms/api/index as documentation
import cheekycms/api/json as api_json
import cheekycms/api/route
import cheekycms/api/select as query
import cheekycms/content/catalogue
import cheekycms/runtime/store as catalogue_store
import gleam/json
import gleam/option

/// Media type shared by JSON API responses.
pub const json_content_type = "application/json; charset=utf-8"

/// A transport-neutral response ready to adapt to an HTTP server.
pub type Response {
  Response(status: Int, content_type: String, body: String)
}

/// Resolve an API path against a content catalogue and encode its response.
pub fn handle(catalogue: catalogue.Catalogue, path: String) -> Response {
  handle_with_query(catalogue, path, [])
}

/// Handle a path and decoded query parameters against the loaded catalogue.
/// Collection controls are accepted only on collection routes.
pub fn handle_with_query(
  catalogue: catalogue.Catalogue,
  path: String,
  parameters: List(#(String, String)),
) -> Response {
  case route.parse(path) {
    Error(route.RouteNotFound) ->
      error_response(404, "route_not_found", "No API route matches this path.")
    Error(route.InvalidPercentEncoding) ->
      error_response(
        400,
        "invalid_path_encoding",
        "The request path contains invalid percent encoding.",
      )
    Error(route.InvalidIdentifier(_)) ->
      error_response(
        400,
        "invalid_identifier",
        "The request path contains an invalid content identifier.",
      )
    Ok(route.Index) ->
      case parameters {
        [] ->
          Response(
            status: 200,
            content_type: json_content_type,
            body: catalogue
              |> documentation.build
              |> api_json.documentation
              |> api_json.to_string,
          )
        _ -> unsupported_query()
      }
    Ok(route.Content(content_query)) ->
      execute(catalogue, content_query, parameters)
  }
}

/// Describe the currently served catalogue and the latest reload attempt.
pub fn health(status: catalogue_store.Status) -> Response {
  let catalogue_store.Status(
    catalogue_size:,
    successful_reloads:,
    last_successful_reload:,
    last_reload_attempt:,
    last_error:,
  ) = status
  let state = case last_error {
    option.None -> "ok"
    option.Some(_) -> "degraded"
  }
  let error = case last_error {
    option.None -> json.null()
    option.Some(message) -> json.string(message)
  }

  Response(
    status: 200,
    content_type: json_content_type,
    body: json.object([
      #("status", json.string(state)),
      #("catalogue_size", json.int(catalogue_size)),
      #("successful_reloads", json.int(successful_reloads)),
      #("last_successful_reload", json.string(last_successful_reload)),
      #("last_reload_attempt", json.string(last_reload_attempt)),
      #("last_error", error),
    ])
      |> json.to_string,
  )
}

fn execute(
  catalogue: catalogue.Catalogue,
  content_query: query.Query,
  parameters: List(#(String, String)),
) -> Response {
  case query.run(catalogue, content_query) {
    Ok(selection) ->
      apply_collection_query(content_query, selection, parameters)
    Error(_) ->
      error_response(
        404,
        "content_not_found",
        "No content matches this request.",
      )
  }
}

fn apply_collection_query(
  content_query: query.Query,
  selection: query.Selection,
  parameters: List(#(String, String)),
) -> Response {
  case parameters, content_query, selection {
    [], _, _ -> selection_response(selection)
    _, query.Collection(_, _), query.Many(contents) ->
      case collection_query.apply(contents, parameters) {
        Ok(contents) -> selection_response(query.Many(contents))
        Error(error) ->
          error_response(
            400,
            collection_query.error_code(error),
            collection_query.error_message(error),
          )
      }
    _, _, _ -> unsupported_query()
  }
}

fn selection_response(selection: query.Selection) -> Response {
  Response(
    status: 200,
    content_type: json_content_type,
    body: selection |> api_json.selection |> api_json.to_string,
  )
}

fn unsupported_query() -> Response {
  error_response(
    400,
    "unsupported_query",
    "Query parameters are only supported on collection routes.",
  )
}

/// Build the shared JSON error envelope with a status, stable code, and message.
pub fn error_response(status: Int, code: String, message: String) -> Response {
  let body =
    json.object([
      #(
        "error",
        json.object([
          #("code", json.string(code)),
          #("message", json.string(message)),
        ]),
      ),
    ])
    |> json.to_string

  Response(status:, content_type: json_content_type, body:)
}
