import cheekycms/api
import cheekycms/catalogue
import cheekycms/discovery
import gleam/dynamic/decode
import gleam/json
import gleeunit/should

fn fixture_catalogue() -> catalogue.Catalogue {
  let assert Ok(value) = discovery.discover("test/fixtures/content")
  value
}

fn demo_catalogue() -> catalogue.Catalogue {
  let assert Ok(value) = discovery.discover("content")
  value
}

pub fn serves_a_catalogue_derived_api_index_test() {
  let api.Response(status:, content_type:, body:) =
    api.handle(fixture_catalogue(), "/api")

  status
  |> should.equal(200)
  content_type
  |> should.equal(api.json_content_type)
  body
  |> json.parse(using: {
    use name <- decode.field("name", decode.string)
    use projects <- decode.field(
      "projects",
      decode.list({
        use id <- decode.field("id", decode.string)
        use endpoint <- decode.field("endpoint", decode.string)
        decode.success(#(id, endpoint))
      }),
    )
    decode.success(#(name, projects))
  })
  |> should.equal(
    Ok(
      #("CheekyCMS", [
        #("course-site", "/api/course-site"),
        #("personal-site", "/api/personal-site"),
      ]),
    ),
  )
}

pub fn handles_a_single_content_request_test() {
  let api.Response(status:, content_type:, body:) =
    api.handle(
      fixture_catalogue(),
      "/api/personal-site/collections/posts/hello-world",
    )

  status
  |> should.equal(200)
  content_type
  |> should.equal(api.json_content_type)
  body
  |> json.parse(using: {
    use kind <- decode.field("kind", decode.string)
    use slug <- decode.field("slug", decode.string)
    use html <- decode.field("html", decode.string)
    decode.success(#(kind, slug, html))
  })
  |> should.equal(
    Ok(#(
      "entry",
      "hello-world",
      "<h1>Hello World</h1>\n<p>Loaded from disk.</p>\n",
    )),
  )
}

pub fn serves_the_shared_portable_document_unchanged_test() {
  let api.Response(status:, body:, ..) =
    api.handle(demo_catalogue(), "/api/example/singletons/portable-page")

  status |> should.equal(200)
  body
  |> json.parse(using: {
    use title <- decode.subfield(["metadata", "title"], decode.string)
    use description <- decode.subfield(
      ["metadata", "description"],
      decode.string,
    )
    use published <- decode.subfield(["metadata", "published"], decode.string)
    use nested_title <- decode.subfield(
      ["metadata", "custom", "title"],
      decode.string,
    )
    use links <- decode.subfield(
      ["metadata", "custom", "links"],
      decode.list(decode.string),
    )
    use html <- decode.field("html", decode.string)
    decode.success(#(title, description, published, nested_title, links, html))
  })
  |> should.equal(
    Ok(#(
      "A portable page",
      "The same document can supply content to three independent projects.",
      "2026-10-06",
      "This nested title is additional metadata.",
      ["https://example.com"],
      "<h1>A portable page</h1>\n<p>Markdown works. We build around that.</p>\n<p>The destination supplies the route and presentation. The title, description,\npublication date, and writing travel together in this file.</p>\n<ul>\n<li>Chippy renders a page when it is requested.</li>\n<li>Docklands generates a static page during its build.</li>\n<li>CheekyCMS delivers the content through its API.</li>\n</ul>\n",
    )),
  )
}

pub fn handles_a_collection_request_test() {
  let api.Response(status:, body:, ..) =
    api.handle(fixture_catalogue(), "/api/personal-site/collections/posts")

  status
  |> should.equal(200)
  body
  |> json.parse(using: {
    use slugs <- decode.field(
      "items",
      decode.list({
        use slug <- decode.field("slug", decode.string)
        decode.success(slug)
      }),
    )
    decode.success(slugs)
  })
  |> should.equal(Ok(["hello-world"]))
}

pub fn filters_sorts_and_limits_collection_requests_test() {
  let api.Response(status:, body:, ..) =
    api.handle_with_query(
      demo_catalogue(),
      "/api/recipe-book/collections/recipes",
      [#("vegetarian", "true"), #("sort", "-minutes"), #("limit", "1")],
    )

  status |> should.equal(200)
  body
  |> json.parse(using: {
    use slugs <- decode.field(
      "items",
      decode.list({
        use slug <- decode.field("slug", decode.string)
        decode.success(slug)
      }),
    )
    decode.success(slugs)
  })
  |> should.equal(Ok(["tomato-orzo"]))
}

pub fn rejects_query_parameters_on_non_collection_routes_test() {
  let api.Response(status:, body:, ..) =
    api.handle_with_query(
      fixture_catalogue(),
      "/api/personal-site/singletons/homepage",
      [#("title", "Home")],
    )

  status |> should.equal(400)
  error_code(body) |> should.equal(Ok("unsupported_query"))
}

pub fn reports_unknown_collection_query_fields_test() {
  let api.Response(status:, body:, ..) =
    api.handle_with_query(
      demo_catalogue(),
      "/api/recipe-book/collections/recipes",
      [#("unknown", "value")],
    )

  status |> should.equal(400)
  error_code(body) |> should.equal(Ok("unknown_query_field"))
}

pub fn returns_json_for_an_unknown_route_test() {
  let api.Response(status:, content_type:, body:) =
    api.handle(fixture_catalogue(), "/not-an-api-route")

  status
  |> should.equal(404)
  content_type
  |> should.equal(api.json_content_type)
  error_code(body)
  |> should.equal(Ok("route_not_found"))
}

pub fn returns_json_when_content_is_missing_test() {
  let api.Response(status:, body:, ..) =
    api.handle(
      fixture_catalogue(),
      "/api/personal-site/collections/posts/missing",
    )

  status
  |> should.equal(404)
  error_code(body)
  |> should.equal(Ok("content_not_found"))
}

pub fn returns_bad_request_for_malformed_paths_test() {
  let api.Response(status: encoding_status, body: encoding_body, ..) =
    api.handle(fixture_catalogue(), "/api/personal-site/singletons/bad%ZZname")
  let api.Response(status: identifier_status, body: identifier_body, ..) =
    api.handle(
      fixture_catalogue(),
      "/api/personal-site/singletons/nested%2Fpage",
    )

  encoding_status
  |> should.equal(400)
  error_code(encoding_body)
  |> should.equal(Ok("invalid_path_encoding"))
  identifier_status
  |> should.equal(400)
  error_code(identifier_body)
  |> should.equal(Ok("invalid_identifier"))
}

fn error_code(body: String) -> Result(String, json.DecodeError) {
  json.parse(from: body, using: {
    use code <- decode.subfield(["error", "code"], decode.string)
    decode.success(code)
  })
}
