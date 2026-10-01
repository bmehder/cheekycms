import cheekycms/api_json
import cheekycms/catalogue
import cheekycms/content
import cheekycms/discovery
import cheekycms/identifier
import cheekycms/metadata
import gleam/dict
import gleam/dynamic/decode
import gleam/json
import gleam/option
import gleeunit/should

fn entry() -> content.RenderedContent {
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(collection) = identifier.collection_name("posts")
  let assert Ok(slug) = identifier.slug("hello-world")

  content.RenderedContent(
    id: content.Entry(project, collection, slug),
    metadata: metadata.from_list([
      #("title", metadata.StringValue("Hello World")),
      #("featured", metadata.BoolValue(True)),
      #("rating", metadata.FloatValue(4.5)),
      #("views", metadata.IntValue(12)),
      #(
        "tags",
        metadata.ListValue([
          metadata.StringValue("gleam"),
          metadata.StringValue("cms"),
        ]),
      ),
      #(
        "author",
        metadata.ObjectValue(
          dict.from_list([#("name", metadata.StringValue("Brad"))]),
        ),
      ),
      #("draft_note", metadata.NullValue),
    ]),
    body: content.trusted_html("<h1>Hello World</h1>\n"),
  )
}

pub fn encodes_collection_entry_identity_and_html_test() {
  let encoded = entry() |> api_json.rendered_content |> api_json.to_string

  json.parse(from: encoded, using: {
    use kind <- decode.field("kind", decode.string)
    use project <- decode.field("project", decode.string)
    use collection <- decode.field("collection", decode.string)
    use slug <- decode.field("slug", decode.string)
    use html <- decode.field("html", decode.string)
    decode.success(#(kind, project, collection, slug, html))
  })
  |> should.equal(
    Ok(#(
      "entry",
      "personal-site",
      "posts",
      "hello-world",
      "<h1>Hello World</h1>\n",
    )),
  )
}

pub fn encodes_nested_dynamic_metadata_test() {
  let encoded = entry() |> api_json.rendered_content |> api_json.to_string

  let tags_decoder = {
    use tags <- decode.subfield(
      ["metadata", "tags"],
      decode.list(decode.string),
    )
    decode.success(tags)
  }

  json.parse(from: encoded, using: tags_decoder)
  |> should.equal(Ok(["gleam", "cms"]))

  let author_decoder = {
    use name <- decode.subfield(["metadata", "author", "name"], decode.string)
    decode.success(name)
  }

  json.parse(from: encoded, using: author_decoder)
  |> should.equal(Ok("Brad"))

  let scalar_decoder = {
    use featured <- decode.subfield(["metadata", "featured"], decode.bool)
    use rating <- decode.subfield(["metadata", "rating"], decode.float)
    use views <- decode.subfield(["metadata", "views"], decode.int)
    use draft_note <- decode.subfield(
      ["metadata", "draft_note"],
      decode.optional(decode.string),
    )
    decode.success(#(featured, rating, views, draft_note))
  }

  json.parse(from: encoded, using: scalar_decoder)
  |> should.equal(Ok(#(True, 4.5, 12, option.None)))
}

pub fn encodes_singleton_identity_test() {
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(name) = identifier.content_name("homepage")
  let value =
    content.RenderedContent(
      id: content.Singleton(project, name),
      metadata: metadata.empty(),
      body: content.trusted_html("<h1>Home</h1>"),
    )

  value
  |> api_json.rendered_content
  |> api_json.to_string
  |> json.parse(using: {
    use kind <- decode.field("kind", decode.string)
    use name <- decode.field("name", decode.string)
    decode.success(#(kind, name))
  })
  |> should.equal(Ok(#("singleton", "homepage")))
}

pub fn encodes_a_complete_catalogue_test() {
  let assert Ok(value) = discovery.discover("test/fixtures/content")
  let encoded = value |> api_json.catalogue |> api_json.to_string

  let project_decoder = {
    use project <- decode.field("project", decode.string)
    decode.success(project)
  }
  let projects_decoder = {
    use projects <- decode.field("items", decode.list(project_decoder))
    decode.success(projects)
  }

  encoded
  |> json.parse(using: projects_decoder)
  |> should.equal(Ok(["course-site", "personal-site", "personal-site"]))

  catalogue.size(value)
  |> should.equal(3)
}
