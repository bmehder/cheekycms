import cheekycms/identifier
import cheekycms/query
import cheekycms/route
import gleam/list
import gleeunit/should

fn project_id(value: String) -> identifier.ProjectId {
  let assert Ok(value) = identifier.project_id(value)
  value
}

fn collection_name(value: String) -> identifier.CollectionName {
  let assert Ok(value) = identifier.collection_name(value)
  value
}

fn slug(value: String) -> identifier.Slug {
  let assert Ok(value) = identifier.slug(value)
  value
}

fn content_name(value: String) -> identifier.ContentName {
  let assert Ok(value) = identifier.content_name(value)
  value
}

pub fn parses_the_api_root_test() {
  route.parse("/api")
  |> should.equal(Ok(query.AllContent))
  route.parse("/api/")
  |> should.equal(Ok(query.AllContent))
}

pub fn parses_a_project_route_test() {
  route.parse("/api/personal-site")
  |> should.equal(Ok(query.Project(project_id("personal-site"))))
}

pub fn parses_a_collection_route_test() {
  route.parse("/api/personal-site/collections/posts")
  |> should.equal(
    Ok(query.Collection(project_id("personal-site"), collection_name("posts"))),
  )
}

pub fn parses_an_entry_route_test() {
  route.parse("/api/personal-site/collections/posts/hello-world")
  |> should.equal(
    Ok(query.Entry(
      project_id("personal-site"),
      collection_name("posts"),
      slug("hello-world"),
    )),
  )
}

pub fn parses_a_singleton_route_test() {
  route.parse("/api/personal-site/singletons/homepage")
  |> should.equal(
    Ok(query.Singleton(project_id("personal-site"), content_name("homepage"))),
  )
}

pub fn accepts_one_trailing_slash_on_content_routes_test() {
  route.parse("/api/personal-site/singletons/homepage/")
  |> should.equal(
    Ok(query.Singleton(project_id("personal-site"), content_name("homepage"))),
  )
}

pub fn percent_decodes_dynamic_segments_test() {
  route.parse("/api/my%20site/collections/news/hello%20world")
  |> should.equal(
    Ok(query.Entry(
      project_id("my site"),
      collection_name("news"),
      slug("hello world"),
    )),
  )
}

pub fn rejects_invalid_percent_encoding_test() {
  route.parse("/api/personal-site/singletons/bad%ZZname")
  |> should.equal(Error(route.InvalidPercentEncoding))
}

pub fn rejects_decoded_path_separators_test() {
  route.parse("/api/personal-site/singletons/nested%2Fpage")
  |> should.equal(
    Error(route.InvalidIdentifier(identifier.PathSeparatorNotAllowed)),
  )
}

pub fn rejects_unknown_and_incomplete_routes_test() {
  [
    "/",
    "/other",
    "/api/personal-site/collections",
    "/api/personal-site/posts",
    "/api/personal-site/singletons/homepage/extra",
    "/api/personal-site//posts",
    "api/personal-site",
  ]
  |> list.all(fn(path) { route.parse(path) == Error(route.RouteNotFound) })
  |> should.be_true
}
