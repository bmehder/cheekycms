# CheekyCMS

A small, file-backed headless CMS written in Gleam. Try the
[live API](https://cheekycms.fly.dev/api) or check its
[health](https://cheekycms.fly.dev/health).

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

Each project is independent inside the content directory. A single CheekyCMS
installation can therefore serve as a data monorepo for several websites and
apps. You can also deploy separate installations when projects need isolated
content or release cycles.

Only Markdown files are used for content. YAML frontmatter holds arbitrary
metadata—including nested objects and lists—and the Markdown body is rendered
to HTML. Raw HTML may be included directly in Markdown.

## Live demo

This repository includes several sample projects to demonstrate a multi-project
content API:

- [`example`](https://cheekycms.fly.dev/api/example) — a minimal starting point
- [`studio`](https://cheekycms.fly.dev/api/studio) — pages, portfolio projects,
  and team members
- [`field-notes`](https://cheekycms.fly.dev/api/field-notes) — a profile,
  dispatches, and places
- [`recipe-book`](https://cheekycms.fly.dev/api/recipe-book) — an about page and
  structured recipes

The [API index](https://cheekycms.fly.dev/api) is generated from the content
currently loaded by the server. It links every project, collection, singleton,
and entry while summarising the metadata fields found in each group.

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

Browser requests are allowed from any origin by default. Set
`CHEEKYCMS_ALLOWED_ORIGINS` to a comma-separated list of origins to restrict
access. CORS preflight `OPTIONS` requests are handled automatically.

For example, the included starter page is available at:

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

The sample content under [`content`](content) is intentionally substantial
enough to use for prototyping clients, testing queries, or adapting into your
own data monorepo.

## Deployment

CheekyCMS includes a production container, continuous integration, and an
always-warm Fly.io configuration. See [DEPLOYMENT.md](DEPLOYMENT.md).
