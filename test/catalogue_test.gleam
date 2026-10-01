import cheekycms/catalogue
import cheekycms/content
import cheekycms/identifier
import cheekycms/metadata
import gleeunit/should

fn rendered_content() -> content.RenderedContent {
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(name) = identifier.content_name("homepage")

  content.RenderedContent(
    id: content.Singleton(project, name),
    metadata: metadata.empty(),
    body: content.trusted_html("<h1>Homepage</h1>\n"),
  )
}

pub fn constructs_a_unique_catalogue_test() {
  let assert Ok(value) =
    catalogue.from_items([
      catalogue.Item(
        path: "personal-site/singletons/homepage.md",
        content: rendered_content(),
      ),
    ])

  catalogue.size(value)
  |> should.equal(1)
}

pub fn reports_duplicate_content_identities_test() {
  let content = rendered_content()
  let content.RenderedContent(id:, ..) = content

  catalogue.from_items([
    catalogue.Item(path: "first.md", content:),
    catalogue.Item(path: "second.md", content:),
  ])
  |> should.equal(
    Error([
      catalogue.Duplicate(
        id:,
        first_path: "first.md",
        duplicate_path: "second.md",
      ),
    ]),
  )
}
