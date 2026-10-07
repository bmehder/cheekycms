import cheekycms/catalogue
import cheekycms/content
import cheekycms/identifier.{
  type CollectionName, type ContentName, type ProjectId, type Slug,
}
import cheekycms/metadata
import gleam/dict.{type Dict}
import gleam/list
import gleam/uri

/// A self-documenting description derived from the loaded catalogue.
pub type Index {
  Index(projects: List(Project))
}

pub type Project {
  Project(
    id: ProjectId,
    endpoint: String,
    collections: List(Collection),
    singletons: List(Singleton),
  )
}

pub type Collection {
  Collection(
    name: CollectionName,
    endpoint: String,
    entries: List(Entry),
    metadata: Dict(String, Field),
  )
}

pub type Entry {
  Entry(slug: Slug, endpoint: String)
}

pub type Singleton {
  Singleton(name: ContentName, endpoint: String, metadata: Dict(String, Field))
}

/// An observed metadata field, not a declared schema.
pub type Field {
  Field(types: List(ValueType), present_in: Int)
}

pub type ValueType {
  StringType
  IntType
  FloatType
  BoolType
  ListType
  ObjectType
  NullType
}

/// Describe the runtime content API from the currently loaded catalogue.
/// This powers `/api`; it is distinct from the generated Gleam code reference.
pub fn build(catalogue: catalogue.Catalogue) -> Index {
  let contents = rendered_contents(catalogue)
  let projects =
    contents
    |> list.map(project_id)
    |> list.unique
    |> list.map(build_project(_, contents))

  Index(projects:)
}

fn build_project(
  id: ProjectId,
  contents: List(content.RenderedContent),
) -> Project {
  let project_contents =
    list.filter(contents, fn(rendered) { project_id(rendered) == id })
  let collections =
    project_contents
    |> list.filter_map(fn(rendered) {
      let content.RenderedContent(id:, ..) = rendered
      case id {
        content.Entry(_, collection, _) -> Ok(collection)
        content.Singleton(..) -> Error(Nil)
      }
    })
    |> list.unique
    |> list.map(build_collection(id, _, project_contents))
  let singletons =
    project_contents
    |> list.filter_map(fn(rendered) {
      let content.RenderedContent(id:, ..) = rendered
      case id {
        content.Singleton(_, name) -> Ok(#(name, rendered))
        content.Entry(..) -> Error(Nil)
      }
    })
    |> list.map(fn(pair) {
      let #(name, rendered) = pair
      Singleton(
        name:,
        endpoint: singleton_endpoint(id, name),
        metadata: observe_metadata([rendered]),
      )
    })

  Project(id:, endpoint: project_endpoint(id), collections:, singletons:)
}

fn build_collection(
  project: ProjectId,
  name: CollectionName,
  contents: List(content.RenderedContent),
) -> Collection {
  let collection_contents =
    list.filter(contents, fn(rendered) {
      let content.RenderedContent(id:, ..) = rendered
      case id {
        content.Entry(entry_project, entry_collection, _) ->
          entry_project == project && entry_collection == name
        content.Singleton(..) -> False
      }
    })
  let entries =
    list.filter_map(collection_contents, fn(rendered) {
      let content.RenderedContent(id:, ..) = rendered
      case id {
        content.Entry(_, _, slug) ->
          Ok(Entry(slug:, endpoint: entry_endpoint(project, name, slug)))
        content.Singleton(..) -> Error(Nil)
      }
    })

  Collection(
    name:,
    endpoint: collection_endpoint(project, name),
    entries:,
    metadata: observe_metadata(collection_contents),
  )
}

fn observe_metadata(
  contents: List(content.RenderedContent),
) -> Dict(String, Field) {
  list.fold(contents, dict.new(), fn(fields, rendered) {
    let content.RenderedContent(metadata: values, ..) = rendered
    values
    |> metadata.to_dict
    |> dict.fold(fields, fn(fields, key, value) {
      case dict.get(fields, key) {
        Error(Nil) ->
          dict.insert(
            fields,
            key,
            Field(types: [value_type(value)], present_in: 1),
          )
        Ok(Field(types:, present_in:)) ->
          dict.insert(
            fields,
            key,
            Field(
              types: list.unique(list.append(types, [value_type(value)])),
              present_in: present_in + 1,
            ),
          )
      }
    })
  })
}

fn value_type(value: metadata.Value) -> ValueType {
  case value {
    metadata.StringValue(_) -> StringType
    metadata.IntValue(_) -> IntType
    metadata.FloatValue(_) -> FloatType
    metadata.BoolValue(_) -> BoolType
    metadata.ListValue(_) -> ListType
    metadata.ObjectValue(_) -> ObjectType
    metadata.NullValue -> NullType
  }
}

fn rendered_contents(
  catalogue: catalogue.Catalogue,
) -> List(content.RenderedContent) {
  catalogue
  |> catalogue.all
  |> list.map(fn(item) {
    let catalogue.Item(content:, ..) = item
    content
  })
}

fn project_id(rendered: content.RenderedContent) -> ProjectId {
  let content.RenderedContent(id:, ..) = rendered
  case id {
    content.Entry(project, ..) | content.Singleton(project, ..) -> project
  }
}

fn project_endpoint(project: ProjectId) -> String {
  "/api/" <> encode(identifier.project_id_to_string(project))
}

fn collection_endpoint(
  project: ProjectId,
  collection: CollectionName,
) -> String {
  project_endpoint(project)
  <> "/collections/"
  <> encode(identifier.collection_name_to_string(collection))
}

fn entry_endpoint(
  project: ProjectId,
  collection: CollectionName,
  slug: Slug,
) -> String {
  collection_endpoint(project, collection)
  <> "/"
  <> encode(identifier.slug_to_string(slug))
}

fn singleton_endpoint(project: ProjectId, name: ContentName) -> String {
  project_endpoint(project)
  <> "/singletons/"
  <> encode(identifier.content_name_to_string(name))
}

fn encode(value: String) -> String {
  uri.percent_encode(value)
}
