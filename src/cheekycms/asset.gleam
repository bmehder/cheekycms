import filepath
import gleam/int
import gleam/list
import gleam/result
import gleam/string
import gleam/uri

pub type Asset {
  Asset(path: String, content_type: String, download: Bool)
}

pub type AssetError {
  NotAssetRoute
  InvalidPath
}

pub type ByteRange {
  ByteRange(offset: Int, length: Int)
}

pub type RangeError {
  InvalidRange
  UnsatisfiableRange
}

/// Resolve a public asset URL without allowing it to escape the asset root.
pub fn resolve(
  request_path: String,
  asset_root: String,
) -> Result(Asset, AssetError) {
  case string.split(request_path, on: "/") {
    ["", "assets", ..encoded_segments] -> {
      use segments <- result.try(
        encoded_segments
        |> list.try_map(uri.percent_decode)
        |> result.replace_error(InvalidPath),
      )

      case valid_segments(segments) {
        False -> Error(InvalidPath)
        True -> {
          let relative = string.join(segments, with: "/")
          Ok(Asset(
            path: filepath.join(asset_root, relative),
            content_type: content_type(relative),
            download: must_download(relative),
          ))
        }
      }
    }
    _ -> Error(NotAssetRoute)
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

pub fn content_type(path: String) -> String {
  case extension(path) {
    "avif" -> "image/avif"
    "gif" -> "image/gif"
    "jpeg" | "jpg" -> "image/jpeg"
    "png" -> "image/png"
    "webp" -> "image/webp"
    "svg" -> "image/svg+xml"
    "pdf" -> "application/pdf"
    "mp3" -> "audio/mpeg"
    "m4a" -> "audio/mp4"
    "ogg" -> "audio/ogg"
    "wav" -> "audio/wav"
    "mp4" -> "video/mp4"
    "webm" -> "video/webm"
    "txt" -> "text/plain; charset=utf-8"
    "csv" -> "text/csv; charset=utf-8"
    "json" -> "application/json"
    "zip" -> "application/zip"
    "woff" -> "font/woff"
    "woff2" -> "font/woff2"
    _ -> "application/octet-stream"
  }
}

pub fn must_download(path: String) -> Bool {
  case extension(path) {
    "html" | "htm" | "svg" | "xml" | "js" | "mjs" -> True
    _ -> False
  }
}

/// Parse one HTTP byte range. Multiple ranges are deliberately unsupported.
pub fn parse_range(value: String, size: Int) -> Result(ByteRange, RangeError) {
  case string.split(value, on: "=") {
    ["bytes", range] ->
      case string.contains(range, ",") {
        True -> Error(InvalidRange)
        False ->
          case string.split(range, on: "-") {
            ["", suffix] -> {
              use suffix <- result.try(parse_positive(suffix))
              let length = int.min(suffix, size)
              Ok(ByteRange(offset: size - length, length:))
            }
            [start, ""] -> {
              use start <- result.try(parse_non_negative(start))
              case start < size {
                True -> Ok(ByteRange(offset: start, length: size - start))
                False -> Error(UnsatisfiableRange)
              }
            }
            [start, finish] -> {
              use start <- result.try(parse_non_negative(start))
              use finish <- result.try(parse_non_negative(finish))
              case start <= finish && start < size {
                True -> {
                  let finish = int.min(finish, size - 1)
                  Ok(ByteRange(offset: start, length: finish - start + 1))
                }
                False -> Error(UnsatisfiableRange)
              }
            }
            _ -> Error(InvalidRange)
          }
      }
    _ -> Error(InvalidRange)
  }
}

fn parse_positive(value: String) -> Result(Int, RangeError) {
  case int.parse(value) {
    Ok(value) if value > 0 -> Ok(value)
    _ -> Error(InvalidRange)
  }
}

fn parse_non_negative(value: String) -> Result(Int, RangeError) {
  case int.parse(value) {
    Ok(value) if value >= 0 -> Ok(value)
    _ -> Error(InvalidRange)
  }
}

fn extension(path: String) -> String {
  filepath.extension(path)
  |> result.unwrap("")
  |> string.lowercase
}
