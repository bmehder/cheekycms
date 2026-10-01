import cheekycms/catalogue
import cheekycms/content
import cheekycms/discovery
import cheekycms/identifier
import cheekycms/query
import gleam/list
import gleeunit/should

fn fixture_catalogue() -> catalogue.Catalogue {
  let assert Ok(value) = discovery.discover("test/fixtures/content")
  value
}

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

pub fn selects_all_content_in_discovery_order_test() {
  let assert Ok(query.Many(contents)) =
    query.run(fixture_catalogue(), query.AllContent)

  list.length(contents)
  |> should.equal(3)
}

pub fn selects_all_content_for_one_project_test() {
  let personal_site = project_id("personal-site")
  let assert Ok(query.Many(contents)) =
    query.run(fixture_catalogue(), query.Project(personal_site))

  list.length(contents)
  |> should.equal(2)
}

pub fn selects_one_collection_test() {
  let personal_site = project_id("personal-site")
  let posts = collection_name("posts")
  let assert Ok(query.Many(contents)) =
    query.run(fixture_catalogue(), query.Collection(personal_site, posts))

  list.length(contents)
  |> should.equal(1)
  let assert [content.RenderedContent(id: content.Entry(_, _, entry_slug), ..)] =
    contents
  identifier.slug_to_string(entry_slug)
  |> should.equal("hello-world")
}

pub fn selects_one_collection_entry_test() {
  let personal_site = project_id("personal-site")
  let posts = collection_name("posts")
  let hello_world = slug("hello-world")
  let assert Ok(query.One(content.RenderedContent(id:, ..))) =
    query.run(
      fixture_catalogue(),
      query.Entry(personal_site, posts, hello_world),
    )

  id
  |> should.equal(content.Entry(personal_site, posts, hello_world))
}

pub fn selects_one_singleton_test() {
  let personal_site = project_id("personal-site")
  let homepage = content_name("homepage")
  let assert Ok(query.One(content.RenderedContent(id:, ..))) =
    query.run(fixture_catalogue(), query.Singleton(personal_site, homepage))

  id
  |> should.equal(content.Singleton(personal_site, homepage))
}

pub fn distinguishes_each_not_found_case_test() {
  let catalogue = fixture_catalogue()
  let missing_project = project_id("missing")
  let personal_site = project_id("personal-site")
  let missing_collection = collection_name("missing")
  let posts = collection_name("posts")
  let missing_slug = slug("missing")
  let missing_singleton = content_name("missing")

  query.run(catalogue, query.Project(missing_project))
  |> should.equal(Error(query.ProjectNotFound(missing_project)))
  query.run(catalogue, query.Collection(personal_site, missing_collection))
  |> should.equal(
    Error(query.CollectionNotFound(personal_site, missing_collection)),
  )
  query.run(catalogue, query.Entry(personal_site, posts, missing_slug))
  |> should.equal(
    Error(query.EntryNotFound(personal_site, posts, missing_slug)),
  )
  query.run(catalogue, query.Singleton(personal_site, missing_singleton))
  |> should.equal(
    Error(query.SingletonNotFound(personal_site, missing_singleton)),
  )
}
