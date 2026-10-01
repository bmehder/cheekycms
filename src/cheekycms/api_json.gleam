import cheekycms/catalogue
import cheekycms/content
import cheekycms/documentation
import cheekycms/identifier
import cheekycms/metadata as content_metadata
import cheekycms/query
import gleam/json.{type Json}
import gleam/list

pub fn documentation(index: documentation.Index) -> Json {
  let documentation.Index(projects:) = index
  json.object([
    #("name", json.string("CheekyCMS")),
    #("projects", json.array(projects, of: documentation_project)),
  ])
}

fn documentation_project(project: documentation.Project) -> Json {
  let documentation.Project(id:, endpoint:, collections:, singletons:) = project
  json.object([
    #("id", json.string(identifier.project_id_to_string(id))),
    #("endpoint", json.string(endpoint)),
    #("collections", json.array(collections, of: documentation_collection)),
    #("singletons", json.array(singletons, of: documentation_singleton)),
  ])
}

fn documentation_collection(collection: documentation.Collection) -> Json {
  let documentation.Collection(name:, endpoint:, entries:, metadata:) =
    collection
  json.object([
    #("name", json.string(identifier.collection_name_to_string(name))),
    #("endpoint", json.string(endpoint)),
    #("entries", json.array(entries, of: documentation_entry)),
    #("metadata", json.dict(metadata, fn(key) { key }, documentation_field)),
  ])
}

fn documentation_entry(entry: documentation.Entry) -> Json {
  let documentation.Entry(slug:, endpoint:) = entry
  json.object([
    #("slug", json.string(identifier.slug_to_string(slug))),
    #("endpoint", json.string(endpoint)),
  ])
}

fn documentation_singleton(singleton: documentation.Singleton) -> Json {
  let documentation.Singleton(name:, endpoint:, metadata:) = singleton
  json.object([
    #("name", json.string(identifier.content_name_to_string(name))),
    #("endpoint", json.string(endpoint)),
    #("metadata", json.dict(metadata, fn(key) { key }, documentation_field)),
  ])
}

fn documentation_field(field: documentation.Field) -> Json {
  let documentation.Field(types:, present_in:) = field
  json.object([
    #("types", json.array(types, of: documentation_type)),
    #("present_in", json.int(present_in)),
  ])
}

fn documentation_type(value: documentation.ValueType) -> Json {
  let name = case value {
    documentation.StringType -> "string"
    documentation.IntType -> "integer"
    documentation.FloatType -> "float"
    documentation.BoolType -> "boolean"
    documentation.ListType -> "list"
    documentation.ObjectType -> "object"
    documentation.NullType -> "null"
  }
  json.string(name)
}

/// Encode rendered content in the shape exposed by the API.
pub fn rendered_content(value: content.RenderedContent) -> Json {
  let content.RenderedContent(id:, metadata: content_metadata, body:) = value
  let common_fields = [
    #("metadata", metadata(content_metadata)),
    #("html", json.string(content.html_to_string(body))),
  ]

  case id {
    content.Entry(project, collection, slug) ->
      json.object([
        #("kind", json.string("entry")),
        #("project", json.string(identifier.project_id_to_string(project))),
        #(
          "collection",
          json.string(identifier.collection_name_to_string(collection)),
        ),
        #("slug", json.string(identifier.slug_to_string(slug))),
        ..common_fields
      ])
    content.Singleton(project, name) ->
      json.object([
        #("kind", json.string("singleton")),
        #("project", json.string(identifier.project_id_to_string(project))),
        #("name", json.string(identifier.content_name_to_string(name))),
        ..common_fields
      ])
  }
}

/// Encode every catalogue item in deterministic discovery order.
pub fn catalogue(value: catalogue.Catalogue) -> Json {
  value
  |> catalogue.all
  |> list_items
}

/// Encode the result of a catalogue query.
pub fn selection(value: query.Selection) -> Json {
  case value {
    query.One(content) -> rendered_content(content)
    query.Many(contents) -> contents_json(contents)
  }
}

fn list_items(items: List(catalogue.Item)) -> Json {
  let contents =
    items
    |> list.map(fn(item) {
      let catalogue.Item(content:, ..) = item
      content
    })

  contents_json(contents)
}

fn contents_json(contents: List(content.RenderedContent)) -> Json {
  let items =
    contents
    |> json.array(of: rendered_content)

  json.object([#("items", items)])
}

/// Encode arbitrary frontmatter metadata as a JSON object.
pub fn metadata(value: content_metadata.Metadata) -> Json {
  value
  |> content_metadata.to_dict
  |> json.dict(fn(key) { key }, metadata_value)
}

pub fn metadata_value(value: content_metadata.Value) -> Json {
  case value {
    content_metadata.StringValue(value) -> json.string(value)
    content_metadata.IntValue(value) -> json.int(value)
    content_metadata.FloatValue(value) -> json.float(value)
    content_metadata.BoolValue(value) -> json.bool(value)
    content_metadata.ListValue(values) -> json.array(values, of: metadata_value)
    content_metadata.ObjectValue(values) ->
      json.dict(values, fn(key) { key }, metadata_value)
    content_metadata.NullValue -> json.null()
  }
}

pub fn to_string(value: Json) -> String {
  json.to_string(value)
}
