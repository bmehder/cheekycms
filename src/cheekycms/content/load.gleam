//// Load Markdown files into a complete rendered catalogue.
////
//// Start with `discover`: it finds and sorts Markdown paths, loads each document,
//// renders its body, and constructs the catalogue. Errors are collected rather
//// than exposing a partially loaded tree. The `load` and `render` functions expose
//// individual stages for tests and reuse.
////
//// Raw HTML is trusted because content is authored by repository owners.

import cheekycms/content
import cheekycms/content/catalogue
import cheekycms/content/frontmatter
import cheekycms/content/source_path
import filepath
import gleam/list
import gleam/result
import gleam/string
import mork
import simplifile

/// An error encountered while loading one Markdown content file.
pub type LoadError {
  InvalidPath(source_path.PathError)
  FileReadFailed(simplifile.FileError)
  ContentParseFailed(frontmatter.ParseError)
}

/// Load a Markdown file using a path relative to the content root.
pub fn load(
  content_root: String,
  relative_path: String,
) -> Result(content.SourceDocument, LoadError) {
  use id <- result.try(
    source_path.content_id(relative_path)
    |> result.map_error(InvalidPath),
  )
  use source <- result.try(
    simplifile.read(filepath.join(content_root, relative_path))
    |> result.map_error(FileReadFailed),
  )
  frontmatter.parse(id, source)
  |> result.map_error(ContentParseFailed)
}

/// A failure encountered while discovering a content tree.
pub type DiscoveryError {
  ContentRootReadFailed(simplifile.FileError)
  FileFailed(path: String, error: LoadError)
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

// Collect per-file failures before deciding whether the complete catalogue is usable.
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

      case load(content_root, path) {
        Ok(document) -> #(
          [catalogue.Item(path:, content: render(document)), ..items],
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

/// Render a parsed Markdown source document into API-ready HTML content.
///
/// Metadata and content identity pass through unchanged. Raw HTML is trusted
/// because CheekyCMS content is authored by the site owner.
pub fn render(document: content.SourceDocument) -> content.RenderedContent {
  let content.SourceDocument(id:, metadata:, body:) = document

  let html =
    body
    |> content.markdown_to_string
    |> mork.parse
    |> mork.to_html

  content.RenderedContent(id:, metadata:, body: content.trusted_html(html))
}
