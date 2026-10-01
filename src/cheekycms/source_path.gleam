import cheekycms/content
import cheekycms/identifier
import filepath
import gleam/list
import gleam/result

/// A path that does not identify a CheekyCMS Markdown document.
pub type PathError {
  InvalidLayout
  NotMarkdown
  InvalidIdentifier(identifier.IdentifierError)
  TraversalNotAllowed
}

/// Derive content identity from a path relative to the content root.
///
/// Supported layouts are:
///
/// ```text
/// <project>/collections/<collection>/<slug>.md
/// <project>/singletons/<name>.md
/// ```
pub fn content_id(path: String) -> Result(content.ContentId, PathError) {
  let segments = filepath.split(path)

  case list.contains(segments, "..") || list.contains(segments, ".") {
    True -> Error(TraversalNotAllowed)
    False -> content_id_from_segments(segments)
  }
}

fn content_id_from_segments(
  segments: List(String),
) -> Result(content.ContentId, PathError) {
  case segments {
    [project, "collections", collection, filename] -> {
      use project <- result.try(parse_project(project))
      use collection <- result.try(parse_collection(collection))
      use slug <- result.try(parse_slug(filename))
      Ok(content.Entry(project, collection, slug))
    }
    [project, "singletons", filename] -> {
      use project <- result.try(parse_project(project))
      use name <- result.try(parse_content_name(filename))
      Ok(content.Singleton(project, name))
    }
    _ -> Error(InvalidLayout)
  }
}

fn parse_project(value: String) -> Result(identifier.ProjectId, PathError) {
  identifier.project_id(value)
  |> result.map_error(InvalidIdentifier)
}

fn parse_collection(
  value: String,
) -> Result(identifier.CollectionName, PathError) {
  identifier.collection_name(value)
  |> result.map_error(InvalidIdentifier)
}

fn parse_slug(filename: String) -> Result(identifier.Slug, PathError) {
  use stem <- result.try(markdown_stem(filename))
  identifier.slug(stem)
  |> result.map_error(InvalidIdentifier)
}

fn parse_content_name(
  filename: String,
) -> Result(identifier.ContentName, PathError) {
  use stem <- result.try(markdown_stem(filename))
  identifier.content_name(stem)
  |> result.map_error(InvalidIdentifier)
}

fn markdown_stem(filename: String) -> Result(String, PathError) {
  case filepath.extension(filename) {
    Ok("md") -> Ok(filepath.strip_extension(filename))
    _ -> Error(NotMarkdown)
  }
}
