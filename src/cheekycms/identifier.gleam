import gleam/result
import gleam/string

pub type IdentifierError {
  EmptyIdentifier
}

pub opaque type ProjectId {
  ProjectId(String)
}

pub opaque type CollectionName {
  CollectionName(String)
}

pub opaque type Slug {
  Slug(String)
}

pub opaque type ContentName {
  ContentName(String)
}

pub fn project_id(value: String) -> Result(ProjectId, IdentifierError) {
  value
  |> result_try_non_empty
  |> result.map(ProjectId)
}

pub fn collection_name(
  value: String,
) -> Result(CollectionName, IdentifierError) {
  value
  |> result_try_non_empty
  |> result.map(CollectionName)
}

pub fn slug(value: String) -> Result(Slug, IdentifierError) {
  value
  |> result_try_non_empty
  |> result.map(Slug)
}

pub fn content_name(value: String) -> Result(ContentName, IdentifierError) {
  value
  |> result_try_non_empty
  |> result.map(ContentName)
}

pub fn project_id_to_string(id: ProjectId) -> String {
  let ProjectId(value) = id
  value
}

pub fn collection_name_to_string(name: CollectionName) -> String {
  let CollectionName(value) = name
  value
}

pub fn slug_to_string(slug: Slug) -> String {
  let Slug(value) = slug
  value
}

pub fn content_name_to_string(name: ContentName) -> String {
  let ContentName(value) = name
  value
}

fn result_try_non_empty(value: String) -> Result(String, IdentifierError) {
  case string.trim(value) {
    "" -> Error(EmptyIdentifier)
    trimmed -> Ok(trimmed)
  }
}
