//// Build the marketing homepage and favicon HTTP responses.
////
//// Reads the homepage singleton from the same catalogue used by the API, with a
//// fallback when it is absent. Applies page headers and passes rendered content to
//// `marketing/layout` for the document shell.

import cheekycms/content
import cheekycms/content/catalogue
import cheekycms/content/identifier
import cheekycms/content/metadata as content_metadata
import gleam/http/response.{type Response}
import marketing/layout as landing

/// Serve the marketing site's SVG mark with browser caching headers.
pub fn favicon() -> Response(String) {
  response.new(200)
  |> response.set_header("content-type", "image/svg+xml; charset=utf-8")
  |> response.set_header("cache-control", "public, max-age=86400")
  |> response.set_header("x-content-type-options", "nosniff")
  |> response.set_body(landing.favicon_svg())
}

/// Read the marketing homepage singleton and wrap it in the site's layout.
/// Falls back to a small explanatory page when the singleton is missing.
pub fn homepage(content_catalogue: catalogue.Catalogue) -> Response(String) {
  let assert Ok(project) = identifier.project_id("cheekycms")
  let assert Ok(name) = identifier.content_name("homepage")
  let homepage =
    catalogue.get(
      content_catalogue,
      content.Singleton(project: project, name: name),
    )
  let #(title, description, body) = case homepage {
    Ok(catalogue.Item(
      content: content.RenderedContent(metadata:, body:, ..),
      ..,
    )) -> #(
      metadata_string(metadata, "title", "CheekyCMS — Markdown in, JSON out"),
      metadata_string(
        metadata,
        "description",
        "A cheeky little Markdown content API, written in Gleam.",
      ),
      content.html_to_string(body),
    )
    Error(Nil) -> #(
      "CheekyCMS",
      "A cheeky little Markdown content API, written in Gleam.",
      "<main class='hero'><div class='wrap'><h1>CheekyCMS</h1><p class='lede'>Add content/cheekycms/singletons/homepage.md to author this page with CheekyCMS.</p></div></main>",
    )
  }

  response.new(200)
  |> response.set_header("content-type", "text/html; charset=utf-8")
  |> response.set_header("cache-control", "public, max-age=300")
  |> response.set_header("x-content-type-options", "nosniff")
  |> response.set_header("referrer-policy", "strict-origin-when-cross-origin")
  |> response.set_header("x-frame-options", "DENY")
  |> response.set_header(
    "content-security-policy",
    "default-src 'none'; style-src 'unsafe-inline'; img-src 'self'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  )
  |> response.set_body(landing.html(title, description, body))
}

fn metadata_string(
  metadata: content_metadata.Metadata,
  key: String,
  fallback: String,
) -> String {
  case content_metadata.get(metadata, key) {
    Ok(content_metadata.StringValue(value)) -> value
    _ -> fallback
  }
}
