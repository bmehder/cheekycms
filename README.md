# CheekyCMS

A small, file-backed headless CMS written in Gleam.

CheekyCMS treats Markdown files with frontmatter as source documents. Its core
pipeline will turn each source document into arbitrary metadata plus rendered
HTML suitable for a JSON API.

The project is currently being built from the domain model outwards. There is
no HTTP server, filesystem loader, or Markdown parser yet.

## Development

```sh
gleam test
```
