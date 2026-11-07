//// Validated names used to identify content.
////
//// Project IDs, collection names, slugs, and singleton names have separate opaque
//// types. Constructors reject invalid path components before they reach content
//// lookup. Both source-file paths and API routes use these constructors.

import gleam/result
import gleam/string

/// A name that cannot safely identify one content path component.
pub type IdentifierError {
  EmptyIdentifier
  PathSeparatorNotAllowed
  ReservedPathSegment
}

/// A validated project name.
pub opaque type ProjectId {
  ProjectId(String)
}

/// A validated collection name.
pub opaque type CollectionName {
  CollectionName(String)
}

/// A validated collection entry slug.
pub opaque type Slug {
  Slug(String)
}

/// A validated singleton name.
pub opaque type ContentName {
  ContentName(String)
}

/// Validate a project path component and give it a distinct type.
pub fn project_id(value: String) -> Result(ProjectId, IdentifierError) {
  value
  |> result_try_non_empty
  |> result.map(ProjectId)
}

/// Validate a collection path component and give it a distinct type.
pub fn collection_name(
  value: String,
) -> Result(CollectionName, IdentifierError) {
  value
  |> result_try_non_empty
  |> result.map(CollectionName)
}

/// Validate an entry slug and give it a distinct type.
pub fn slug(value: String) -> Result(Slug, IdentifierError) {
  value
  |> result_try_non_empty
  |> result.map(Slug)
}

/// Validate a singleton name and give it a distinct type.
pub fn content_name(value: String) -> Result(ContentName, IdentifierError) {
  value
  |> result_try_non_empty
  |> result.map(ContentName)
}

/// Read the validated project name for paths and JSON.
pub fn project_id_to_string(id: ProjectId) -> String {
  let ProjectId(value) = id
  value
}

/// Read the validated collection name for paths and JSON.
pub fn collection_name_to_string(name: CollectionName) -> String {
  let CollectionName(value) = name
  value
}

/// Read the validated entry slug for paths and JSON.
pub fn slug_to_string(slug: Slug) -> String {
  let Slug(value) = slug
  value
}

/// Read the validated singleton name for paths and JSON.
pub fn content_name_to_string(name: ContentName) -> String {
  let ContentName(value) = name
  value
}

fn result_try_non_empty(value: String) -> Result(String, IdentifierError) {
  case string.trim(value) {
    "" -> Error(EmptyIdentifier)
    "." | ".." -> Error(ReservedPathSegment)
    trimmed ->
      case string.contains(trimmed, "/") || string.contains(trimmed, "\\") {
        True -> Error(PathSeparatorNotAllowed)
        False -> Ok(trimmed)
      }
  }
}
