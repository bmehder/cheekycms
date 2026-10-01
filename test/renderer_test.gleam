import cheekycms/content
import cheekycms/identifier
import cheekycms/metadata
import cheekycms/renderer
import gleeunit/should

fn source_document(markdown: String) -> content.SourceDocument {
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(name) = identifier.content_name("homepage")

  content.SourceDocument(
    id: content.Singleton(project, name),
    metadata: metadata.from_list([
      #("title", metadata.StringValue("Homepage")),
    ]),
    body: content.markdown(markdown),
  )
}

pub fn renders_commonmark_to_html_test() {
  let source =
    source_document("# Hello\n\nThis is **CheekyCMS**.\n\n- Small\n- Typed\n")
  let content.RenderedContent(body: html, ..) = renderer.render(source)

  html
  |> content.html_to_string
  |> should.equal(
    "<h1>Hello</h1>\n<p>This is <strong>CheekyCMS</strong>.</p>\n<ul>\n<li>Small</li>\n<li>Typed</li>\n</ul>\n",
  )
}

pub fn preserves_trusted_raw_html_test() {
  let source =
    source_document(
      "Before <span class=\"accent\">colour</span>.\n\n<section class=\"feature\">\n  <h2>Custom HTML</h2>\n</section>\n",
    )
  let content.RenderedContent(body: html, ..) = renderer.render(source)

  html
  |> content.html_to_string
  |> should.equal(
    "<p>Before <span class=\"accent\">colour</span>.</p>\n<section class=\"feature\">\n  <h2>Custom HTML</h2>\n</section>\n",
  )
}

pub fn preserves_identity_and_metadata_test() {
  let source = source_document("# Hello")
  let content.SourceDocument(id: source_id, metadata: source_metadata, ..) =
    source
  let content.RenderedContent(id:, metadata: rendered_metadata, ..) =
    renderer.render(source)

  id
  |> should.equal(source_id)
  rendered_metadata
  |> metadata.get("title")
  |> should.equal(source_metadata |> metadata.get("title"))
}
