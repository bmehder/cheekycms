//// Resolve URLs for the generated Gleam implementation reference.
////
//// Maps the reference root to its index and preserves nested documentation paths,
//// rejecting invalid path segments. These trusted build-generated files are served
//// inline with their appropriate media types by `cheekycms/web/files`.

import cheekycms/web/asset
import filepath
import gleam/list
import gleam/result
import gleam/string
import gleam/uri

/// Distinguish unrelated URLs from malformed reference paths.
pub type ReferenceError {
  NotReferenceRoute
  InvalidPath
}

/// Resolve a generated reference URL without allowing it to escape its root.
/// The bare route maps to `index.html`; all other files retain the directory
/// structure emitted by `gleam docs build`.
pub fn resolve(
  request_path: String,
  reference_root: String,
) -> Result(asset.Asset, ReferenceError) {
  case request_path {
    "/reference" | "/reference/" ->
      Ok(asset.Asset(
        path: filepath.join(reference_root, "index.html"),
        content_type: "text/html; charset=utf-8",
        download: False,
      ))
    _ ->
      case string.split(request_path, on: "/") {
        ["", "reference", ..encoded_segments] -> {
          use segments <- result.try(
            encoded_segments
            |> list.try_map(uri.percent_decode)
            |> result.replace_error(InvalidPath),
          )
          case valid_segments(segments) {
            False -> Error(InvalidPath)
            True -> {
              let relative = string.join(segments, with: "/")
              Ok(asset.Asset(
                path: filepath.join(reference_root, relative),
                content_type: content_type(relative),
                download: False,
              ))
            }
          }
        }
        _ -> Error(NotReferenceRoute)
      }
  }
}

fn valid_segments(segments: List(String)) -> Bool {
  segments != []
  && list.all(segments, fn(segment) {
    segment != ""
    && segment != "."
    && segment != ".."
    && !string.starts_with(segment, ".")
    && !string.contains(segment, "\\")
    && !string.contains(segment, "\u{0000}")
  })
}

fn content_type(path: String) -> String {
  case filepath.extension(path) |> result.unwrap("") |> string.lowercase {
    "html" -> "text/html; charset=utf-8"
    "css" -> "text/css; charset=utf-8"
    "js" -> "text/javascript; charset=utf-8"
    "json" -> "application/json"
    "svg" -> "image/svg+xml"
    "woff" -> "font/woff"
    "woff2" -> "font/woff2"
    _ -> "application/octet-stream"
  }
}
