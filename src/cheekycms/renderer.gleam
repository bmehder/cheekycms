import cheekycms/content
import mork

/// Render a parsed Markdown source document into API-ready HTML content.
///
/// Metadata and content identity pass through unchanged. Raw HTML is trusted
/// because CheekyCMS content is authored by the site owner.
pub fn render(document: content.SourceDocument) -> content.RenderedContent {
  let content.SourceDocument(id:, metadata:, body:) = document

  let html =
    body
    |> content.markdown_to_string
    |> mork.parse
    |> mork.to_html

  content.RenderedContent(id:, metadata:, body: content.trusted_html(html))
}
