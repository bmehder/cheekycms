import cheekycms/identifier.{
  type CollectionName, type ContentName, type ProjectId, type Slug,
}
import cheekycms/metadata.{type Metadata}

/// The stable identity of a piece of content.
pub type ContentId {
  Entry(project: ProjectId, collection: CollectionName, slug: Slug)
  Singleton(project: ProjectId, name: ContentName)
}

/// Markdown which has not yet passed through the renderer.
pub opaque type Markdown {
  Markdown(String)
}

/// Rendered HTML ready to expose through the API.
pub opaque type Html {
  Html(String)
}

/// A parsed source file before its Markdown body has been rendered.
pub type SourceDocument {
  SourceDocument(id: ContentId, metadata: Metadata, body: Markdown)
}

/// Content after Markdown rendering, ready for JSON encoding.
pub type RenderedContent {
  RenderedContent(id: ContentId, metadata: Metadata, body: Html)
}

pub fn markdown(value: String) -> Markdown {
  Markdown(value)
}

pub fn markdown_to_string(markdown: Markdown) -> String {
  let Markdown(value) = markdown
  value
}

/// Wrap HTML produced by a trusted renderer.
pub fn trusted_html(value: String) -> Html {
  Html(value)
}

pub fn html_to_string(html: Html) -> String {
  let Html(value) = html
  value
}
