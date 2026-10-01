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
