import cheekycms/content
import cheekycms/frontmatter
import cheekycms/source_path
import filepath
import gleam/result
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
