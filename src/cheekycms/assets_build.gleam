import alakazam/image
import envoy
import filepath
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

const source_suffix = "-source"

const responsive_widths = [480, 960, 1600]

/// Generate responsive WebP images from `*-source.png`, `.jpg`, and `.jpeg` files.
pub fn main() -> Nil {
  let root = envoy.get("CHEEKYCMS_ASSET_ROOT") |> result.unwrap("assets")
  case discover_sources(root) {
    Error(error) -> {
      let message = "Could not scan assets: " <> string.inspect(error)
      panic as message
    }
    Ok(sources) -> {
      sources |> list.each(build_source)
      io.println(
        "Processed " <> string.inspect(list.length(sources)) <> " source images",
      )
    }
  }
}

fn discover_sources(directory: String) {
  use entries <- result.try(simplifile.read_directory(directory))
  entries
  |> list.try_fold([], fn(sources, name) {
    let path = filepath.join(directory, name)
    case simplifile.is_directory(path) {
      Ok(True) ->
        discover_sources(path)
        |> result.map(fn(nested) { list.append(sources, nested) })
      Ok(False) ->
        case is_source_image(path) {
          True -> Ok([path, ..sources])
          False -> Ok(sources)
        }
      Error(error) -> Error(error)
    }
  })
}

fn is_source_image(path: String) -> Bool {
  let extension =
    filepath.extension(path)
    |> result.unwrap("")
    |> string.lowercase
  let base = filepath.strip_extension(path)
  string.ends_with(base, source_suffix)
  && list.contains(["png", "jpg", "jpeg"], extension)
}

fn build_source(source: String) -> Nil {
  let output_base =
    source
    |> filepath.strip_extension
    |> string.drop_end(string.length(source_suffix))

  responsive_widths
  |> list.each(fn(width) {
    let destination = output_base <> "-" <> string.inspect(width) <> ".webp"
    case
      image.from_file(source)
      |> image.auto_orient
      |> image.raw("-resize", string.inspect(width) <> "x>")
      |> image.quality(82)
      |> image.strip
      |> image.to_file(destination)
    {
      Ok(_) -> io.println("Generated " <> destination)
      Error(error) -> {
        let message =
          "Could not generate " <> destination <> ": " <> string.inspect(error)
        panic as message
      }
    }
  })
}
