import cheekycms/catalogue
import cheekycms/content
import cheekycms/identifier
import cheekycms/metadata as content_metadata
import gleam/json.{type Json}

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
  let items =
    value
    |> catalogue.all
    |> json.array(of: fn(item) {
      let catalogue.Item(content:, ..) = item
      rendered_content(content)
    })

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
