import cheekycms/content
import cheekycms/identifier
import cheekycms/metadata
import gleeunit/should

pub fn source_and_rendered_content_have_distinct_body_types_test() {
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(collection) = identifier.collection_name("posts")
  let assert Ok(slug) = identifier.slug("hello-world")
  let id = content.Entry(project, collection, slug)

  let source =
    content.SourceDocument(
      id: id,
      metadata: metadata.empty(),
      body: content.markdown("# Hello"),
    )
  let rendered =
    content.RenderedContent(
      id: id,
      metadata: metadata.empty(),
      body: content.trusted_html("<h1>Hello</h1>"),
    )

  let content.SourceDocument(body: markdown, ..) = source
  let content.RenderedContent(body: html, ..) = rendered

  content.markdown_to_string(markdown)
  |> should.equal("# Hello")
  content.html_to_string(html)
  |> should.equal("<h1>Hello</h1>")
}
