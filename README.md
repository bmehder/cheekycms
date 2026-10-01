# CheekyCMS

A small, file-backed headless CMS written in Gleam.

CheekyCMS treats Markdown files with frontmatter as source documents. Its core
pipeline will turn each source document into arbitrary metadata plus rendered
HTML suitable for a JSON API.

CheekyCMS runs on the BEAM using Mist. Content is discovered and rendered at
startup, then served from an in-memory catalogue. Markdown changes are loaded
automatically. An invalid edit is reported without replacing the last working
catalogue.

## Content layout

```text
content/
  <project>/
    collections/<collection>/<slug>.md
    singletons/<name>.md
```

## Running

```sh
gleam run
```

The server listens on port `4000` and reads from `content` by default. These
settings can be changed with:

```sh
CHEEKYCMS_PORT=8080 \
CHEEKYCMS_HOST=127.0.0.1 \
CHEEKYCMS_CONTENT_ROOT=path/to/content \
gleam run
```

Only `GET` requests are supported.

The included example is available at:

```text
GET /api/example/singletons/homepage
```

The complete route structure is:

```text
GET /api
GET /api/:project
GET /api/:project/collections/:collection
GET /api/:project/collections/:collection/:slug
GET /api/:project/singletons/:name
GET /health
```

`GET /api` is a discovery document generated from the loaded content. It lists
each project, collection, singleton, entry endpoint, and the types and presence
counts observed for frontmatter fields. The other routes return rendered
content.

`GET /health` reports the catalogue size, reload count, timestamps for the last
attempt and successful reload, and the most recent reload error. A `degraded`
status means the last working content is still being served after an invalid
edit.

## Development

```sh
gleam test
```
