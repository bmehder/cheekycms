//// Apply the configured browser access policy to HTTP responses.
////
//// Allows all origins when configured with a wildcard, or echoes an explicitly
//// allowed request origin. Adds preflight and exposed-header information shared
//// by API and file responses.

import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/list

/// Apply configured CORS headers when the request origin is permitted.
/// An explicit origin also adds Vary: Origin so caches distinguish responses.
pub fn add(
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
