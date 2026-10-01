import cheekycms/catalogue
import cheekycms/content
import cheekycms/discovery
import cheekycms/identifier
import cheekycms/loader
import cheekycms/metadata
import gleam/list
import gleeunit/should
import simplifile

pub fn discovers_multiple_projects_and_content_kinds_test() {
  let assert Ok(value) = discovery.discover("test/fixtures/content")

  catalogue.size(value)
  |> should.equal(3)

  value
  |> catalogue.all
  |> list.map(fn(item) {
    let catalogue.Item(path:, ..) = item
    path
  })
  |> should.equal([
    "course-site/collections/courses/biology.md",
    "personal-site/collections/posts/hello-world.md",
    "personal-site/singletons/homepage.md",
  ])
}

pub fn catalogue_content_is_rendered_and_queryable_test() {
  let assert Ok(value) = discovery.discover("test/fixtures/content")
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(name) = identifier.content_name("homepage")
  let id = content.Singleton(project, name)
  let assert Ok(catalogue.Item(content: rendered, ..)) =
    catalogue.get(value, id)
  let content.RenderedContent(metadata: values, body: html, ..) = rendered

  values
  |> metadata.get("title")
  |> should.equal(Ok(metadata.StringValue("Homepage")))
  content.html_to_string(html)
  |> should.equal("<h1>Welcome</h1>\n<p>This is the homepage.</p>\n")
}

pub fn collects_all_file_failures_test() {
  let assert Error(errors) = discovery.discover("test/fixtures/invalid-content")

  list.length(errors)
  |> should.equal(2)
  errors
  |> list.map(fn(error) {
    case error {
      discovery.FileFailed(path:, error: loader.ContentParseFailed(_)) -> path
      _ -> "unexpected"
    }
  })
  |> should.equal([
    "personal-site/collections/posts/broken-one.md",
    "personal-site/collections/posts/broken-two.md",
  ])
}

pub fn reports_an_unreadable_content_root_test() {
  discovery.discover("test/fixtures/does-not-exist")
  |> should.equal(
    Error([
      discovery.ContentRootReadFailed(simplifile.Enoent),
    ]),
  )
}
