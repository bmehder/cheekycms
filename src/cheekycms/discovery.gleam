import cheekycms/catalogue
import cheekycms/loader
import cheekycms/renderer
import filepath
import gleam/list
import gleam/string
import simplifile

/// A failure encountered while discovering a content tree.
pub type DiscoveryError {
  ContentRootReadFailed(simplifile.FileError)
  FileFailed(path: String, error: loader.LoadError)
  DuplicateContent(catalogue.Duplicate)
}

/// Discover, load, and render every Markdown document below a content root.
///
/// Files with other extensions are ignored. If any content is invalid, all
/// discoverable failures are returned together and no partial catalogue is
/// exposed.
pub fn discover(
  content_root: String,
) -> Result(catalogue.Catalogue, List(DiscoveryError)) {
  case simplifile.get_files(in: content_root) {
    Error(error) -> Error([ContentRootReadFailed(error)])
    Ok(paths) -> discover_paths(content_root, paths)
  }
}

fn discover_paths(
  content_root: String,
  paths: List(String),
) -> Result(catalogue.Catalogue, List(DiscoveryError)) {
  let relative_paths =
    paths
    |> list.filter(fn(path) { filepath.extension(path) == Ok("md") })
    |> list.map(relative_path(content_root, _))
    |> list.sort(by: string.compare)

  let #(items, file_errors) =
    list.fold(relative_paths, #([], []), fn(state, path) {
      let #(items, errors) = state

      case loader.load(content_root, path) {
        Ok(document) -> #(
          [catalogue.Item(path:, content: renderer.render(document)), ..items],
          errors,
        )
        Error(error) -> #(items, [FileFailed(path:, error:), ..errors])
      }
    })

  let items = list.reverse(items)
  let file_errors = list.reverse(file_errors)

  case catalogue.from_items(items), file_errors {
    Ok(catalogue), [] -> Ok(catalogue)
    Ok(_), errors -> Error(errors)
    Error(duplicates), errors ->
      duplicates
      |> list.map(DuplicateContent)
      |> list.append(errors)
      |> Error
  }
}

fn relative_path(content_root: String, full_path: String) -> String {
  let root = filepath.join(content_root, "")
  let prefix = root <> "/"

  case string.starts_with(full_path, prefix) {
    True -> string.drop_start(full_path, string.length(prefix))
    False -> full_path
  }
}
