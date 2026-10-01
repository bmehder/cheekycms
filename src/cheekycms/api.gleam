import cheekycms/api_json
import cheekycms/catalogue
import cheekycms/query
import cheekycms/route
import gleam/json

pub const json_content_type = "application/json; charset=utf-8"

/// A transport-neutral response ready to adapt to an HTTP server.
pub type Response {
  Response(status: Int, content_type: String, body: String)
}

/// Resolve an API path against a content catalogue and encode its response.
pub fn handle(catalogue: catalogue.Catalogue, path: String) -> Response {
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
    Ok(content_query) -> execute(catalogue, content_query)
  }
}

fn execute(
  catalogue: catalogue.Catalogue,
  content_query: query.Query,
) -> Response {
  case query.run(catalogue, content_query) {
    Ok(selection) ->
      Response(
        status: 200,
        content_type: json_content_type,
        body: selection |> api_json.selection |> api_json.to_string,
      )
    Error(_) ->
      error_response(
        404,
        "content_not_found",
        "No content matches this request.",
      )
  }
}

fn error_response(status: Int, code: String, message: String) -> Response {
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
