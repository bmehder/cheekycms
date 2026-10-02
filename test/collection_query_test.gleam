import cheekycms/collection_query
import cheekycms/content
import cheekycms/discovery
import cheekycms/identifier
import cheekycms/query
import gleam/list
import gleeunit/should

fn recipes() -> List(content.RenderedContent) {
  let assert Ok(catalogue) = discovery.discover("content")
  let assert Ok(project) = identifier.project_id("recipe-book")
  let assert Ok(collection) = identifier.collection_name("recipes")
  let assert Ok(query.Many(contents)) =
    query.run(catalogue, query.Collection(project, collection))
  contents
}

fn studio_projects() -> List(content.RenderedContent) {
  let assert Ok(catalogue) = discovery.discover("content")
  let assert Ok(project) = identifier.project_id("studio")
  let assert Ok(collection) = identifier.collection_name("projects")
  let assert Ok(query.Many(contents)) =
    query.run(catalogue, query.Collection(project, collection))
  contents
}

fn slugs(contents: List(content.RenderedContent)) -> List(String) {
  list.map(contents, fn(item) {
    let content.RenderedContent(id:, ..) = item
    let assert content.Entry(_, _, slug) = id
    identifier.slug_to_string(slug)
  })
}

pub fn filters_scalar_metadata_test() {
  let assert Ok(contents) =
    collection_query.apply(studio_projects(), [#("featured", "true")])
  slugs(contents) |> should.equal(["orbit"])
}

pub fn filters_members_of_metadata_lists_test() {
  let assert Ok(contents) =
    collection_query.apply(recipes(), [#("tags", "pantry")])
  slugs(contents) |> should.equal(["lemon-chickpeas"])
}

pub fn sorts_and_limits_results_test() {
  let assert Ok(contents) =
    collection_query.apply(recipes(), [#("sort", "-minutes"), #("limit", "1")])
  slugs(contents) |> should.equal(["tomato-orzo"])
}

pub fn combines_filters_with_and_test() {
  let assert Ok(contents) =
    collection_query.apply(recipes(), [
      #("vegetarian", "true"),
      #("difficulty", "easy"),
    ])
  list.length(contents) |> should.equal(2)
}

pub fn rejects_unknown_fields_and_bad_controls_test() {
  collection_query.apply(recipes(), [#("unknown", "value")])
  |> should.equal(Error(collection_query.UnknownField("unknown")))
  collection_query.apply(recipes(), [#("limit", "0")])
  |> should.equal(Error(collection_query.InvalidLimit))
  collection_query.apply(recipes(), [#("sort", "tags")])
  |> should.equal(Error(collection_query.UnsortableField("tags")))
}
