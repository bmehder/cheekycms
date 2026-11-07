# CheekyCMS

A cheeky little Markdown content API written in Gleam. Visit the
[project site](https://cheekycms.fly.dev), explore the
[live API](https://cheekycms.fly.dev/api), browse the
[generated Gleam code reference](https://cheekycms.fly.dev/reference/), or check its
[health](https://cheekycms.fly.dev/health).

CheekyCMS treats Markdown files with frontmatter as source documents. Its core
pipeline will turn each source document into arbitrary metadata plus rendered
HTML suitable for a JSON API.

It is content delivery more than content management: there is no dashboard,
visual editor, database, write API, or editorial workflow. Git handles editing,
history, and publishing. CheekyCMS keeps the deliberately smaller job of turning
a repository of Markdown and assets into a reusable, read-only API.

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
assets/
  <project>/images/<name>-source.png
  <project>/documents/<file>
```

Each project is independent inside the content directory. A single CheekyCMS
installation can therefore serve as a data monorepo for several websites and
apps. You can also deploy separate installations when projects need isolated
content or release cycles.

Only Markdown files are used for content. YAML frontmatter holds arbitrary
metadata—including nested objects and lists—and the Markdown body is rendered
to HTML. Raw HTML may be included directly in Markdown.

For example:

```markdown
---
title: Lemony Chickpeas with Greens
description: A quick one-pan supper of chickpeas, lemon, and greens.
published: 2026-10-02
minutes: 25
vegetarian: true
tags:
  - one-pan
  - pantry
---
# Lemony Chickpeas with Greens

Warm the chickpeas in olive oil, then fold through the greens.
```

The frontmatter becomes the response's `metadata` object and the body becomes
its rendered `html` string. CheekyCMS does not impose a shared schema across
projects or collections.

## Portable Markdown contract

CheekyCMS supports version 1.0.0 of The Markdown Works'
[Markdown content contract](https://github.com/bmehder/themarkdownworks/blob/main/docs/markdown-contract.md).
A portable document has non-empty `title`, `description`, and `published`
fields, with `published` written as a `YYYY-MM-DD` calendar date. Plain and
quoted YAML strings have the same text value, and additional scalar, list, and
mapping metadata is preserved in the API.

The contract describes a portable subset, not a global CheekyCMS schema.
CheekyCMS continues to accept Markdown without those fields and to expose
arbitrary YAML metadata. Destination-specific templates, styles, shortcodes,
routes, and asset locations remain outside the portability promise.

The repository includes the contract's shared example unchanged at
[`/api/example/singletons/portable-page`](https://cheekycms.fly.dev/api/example/singletons/portable-page).
The sample documents that previously had no publication date use `2026-10-02`,
their first appearance in Git history; existing editorial dates are unchanged.

## Why CheekyCMS?

CheekyCMS favors two simple ideas: Markdown is a pleasantly portable content
format, and one installation can serve several independent projects. Keep every
project separate, use one deployment as a small data monorepo, or land somewhere
in between. It is not necessarily the right architecture for everyone. You can
do you.

Full CMS products provide editing interfaces, permissions, drafts, schemas, and
editorial workflows. Static-site tools turn files directly into websites.
CheekyCMS sits narrowly between them: it exposes Markdown files as a universal
HTTP API for websites, applications, static builds, or anything else that can
read JSON. It does less on purpose.

## Publishing content

Add or edit Markdown under `content/`, add any referenced files under `assets/`,
then commit and push to `main`:

```sh
git add content assets
git commit -m "Update content"
git push
```

GitHub Actions checks formatting, runs the full test suite, builds the
container, and deploys the new content to Fly.io. A failed check prevents the
production deployment, so the currently working version stays live. Follow the
run on the repository's [Actions page](https://github.com/bmehder/cheekycms/actions),
then verify the [live API](https://cheekycms.fly.dev/api). There is no separate
`fly deploy` step for normal publishing.

## Assets and images

CheekyCMS serves repository-managed files from `/assets/...`. Images, PDFs,
audio, video, text files, fonts, archives, and other downloads can live under
`assets/` and be referenced from frontmatter:

```yaml
hero:
  src: /assets/studio/images/orbit-1600.webp
  alt: A commuter using a journey planner
document:
  src: /assets/studio/documents/northstar-capabilities.pdf
```

Source images named `*-source.png`, `*-source.jpg`, or `*-source.jpeg` are
automatically converted into 480, 960, and 1600 pixel WebP variants during the
container build. To generate them locally, install ImageMagick and run:

```sh
gleam run -m cheekycms/assets_build
```

Try the live [responsive image](https://cheekycms.fly.dev/assets/studio/images/orbit-960.webp),
[PDF](https://cheekycms.fly.dev/assets/studio/documents/northstar-capabilities.pdf),
or [text download](https://cheekycms.fly.dev/assets/field-notes/downloads/coastal-walk-checklist.txt).
Asset paths are traversal-safe, unknown types are served as binary data, and
potentially active HTML, SVG, XML, and JavaScript files are forced to download.
Byte-range requests are supported, allowing browsers to seek through larger
PDF, audio, and video files without downloading them completely first.

Assets are currently read-only and repository-backed. CheekyCMS does not
provide an upload API, authentication, or persistent runtime storage. GitHub
enforces a 100 MB maximum for an individual Git object, so large or frequently
changing media libraries should use object storage rather than this
repository-backed workflow.

## Generate the Gleam code reference

Public types and functions use `///` comments; module introductions use `////`.
Generate the reference with Gleam and stage it for the local server:

```sh
sh docs/build-reference.sh
gleam run
```

Open `http://localhost:4000/reference/`, or use the book icon in the demo site's
main navigation. The script runs `gleam docs build`, copies its output to the
ignored `reference/` directory, and adds the self-hosted `docs_config.js`.
The container build uses the same script. Regenerate after changing source
comments. `/api` describes content; `/reference/` documents the Gleam code.

## Content service and marketing website

CheekyCMS provides the content API, asset delivery, and health endpoint. This
repository also includes the marketing website published at the root URL.
The website consumes the loaded CMS catalogue and runs in the same process
and deployment.

- [src/cheekycms/](src/cheekycms/) contains the content service.
- [src/marketing.gleam](src/marketing.gleam) owns the website routes.
- [src/marketing/pages.gleam](src/marketing/pages.gleam) reads the homepage
  singleton and builds page responses.
- [src/marketing/layout.gleam](src/marketing/layout.gleam) owns the website's
  HTML shell, CSS, and favicon artwork.
- [content/cheekycms/](content/cheekycms/) holds the website's Markdown content,
  which is also available through the API like any other project.

The HTTP server connects to the website through `marketing.handle`. Website
routes and branding belong to that module and its helpers. The generated
`/reference/` pages are implementation documentation.

## Live demo

This repository includes several sample projects to demonstrate a multi-project
content API:

- [`cheekycms`](https://cheekycms.fly.dev/api/cheekycms) — this site's own
  homepage and guides, dogfooding the content API
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
CHEEKYCMS_ASSET_ROOT=path/to/assets \
gleam run
```

Public data operations are read-only. `GET` serves content and assets, while
`OPTIONS` is supported for browser CORS preflights. Other methods return `405`.

Browser requests are allowed from any origin by default. Set
`CHEEKYCMS_ALLOWED_ORIGINS` to a comma-separated list of origins to restrict
access. CORS preflight `OPTIONS` requests are handled automatically.

For example, the included starter page is available at:

```text
GET /api/example/singletons/homepage
```

The content service routes are:

```text
GET /api
GET /api/:project
GET /api/:project/collections/:collection
GET /api/:project/collections/:collection/:slug
GET /api/:project/singletons/:name
GET /assets/:path
GET /health
```

The marketing website handles `GET /` and `GET /favicon.svg`. Generated code
reference pages are available at `/reference/` and its nested file paths.

`GET /` serves the project introduction. `GET /api` is a discovery document
generated from the loaded content. It lists
each project, collection, singleton, entry endpoint, and the types and presence
counts observed for frontmatter fields. The other routes return rendered
content.

### Filtering collections

Collection routes support metadata filters, sorting, and limits:

```text
GET /api/studio/collections/projects?featured=true
GET /api/recipe-book/collections/recipes?tags=pantry
GET /api/recipe-book/collections/recipes?vegetarian=true&sort=minutes
GET /api/field-notes/collections/dispatches?sort=-published&limit=10
```

Any metadata field can be used as a filter. Scalar values use exact matching;
list fields such as `tags` match when the requested value is present. Multiple
filters are combined with AND. Use `sort=field` for ascending order or
`sort=-field` for descending order, and use `limit` from 1 through 100.

Unknown fields, unsortable fields, malformed controls, and query parameters on
non-collection routes return a descriptive `400` response. The generated API
index also describes these query controls.

Try [featured projects](https://cheekycms.fly.dev/api/studio/collections/projects?featured=true)
or [the quickest vegetarian recipe](https://cheekycms.fly.dev/api/recipe-book/collections/recipes?vegetarian=true&sort=minutes&limit=1).

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

## Reading the code

The [`Inside CheekyCMS`](content/cheekycms/collections/guides/inside-cheekycms.md)
tutorial follows one Markdown file all the way from disk to JSON over HTTP. Its
live API response is available at
[`/api/cheekycms/collections/guides/inside-cheekycms`](https://cheekycms.fly.dev/api/cheekycms/collections/guides/inside-cheekycms).

The source is grouped by responsibility:

| Location | Purpose |
|---|---|
| [content.gleam](src/cheekycms/content.gleam) and [content/](src/cheekycms/content/) | Document types, loading, frontmatter, metadata, identity, and catalogue |
| [api.gleam](src/cheekycms/api.gleam) and [api/](src/cheekycms/api/) | Routes, content selection, filtering, JSON, and the API index |
| [runtime/store.gleam](src/cheekycms/runtime/store.gleam) | Actor holding the live catalogue and reload status |
| [web/](src/cheekycms/web/) | Server startup, HTTP dispatch, file delivery, CORS, and configuration |
| [marketing.gleam](src/marketing.gleam) and [marketing/](src/marketing/) | Demo website routes, page responses, HTML shell, and CSS |
| [assets_build.gleam](src/cheekycms/assets_build.gleam) | Build-time responsive images |
| [cheekycms.gleam](src/cheekycms.gleam) | Application entry point |

Follow these two flows first:

```text
Files → content/load → catalogue
Request → api/route → api/select → api/json → response
```

Start with [content/load.gleam](src/cheekycms/content/load.gleam) for loading
and rendering, then [api.gleam](src/cheekycms/api.gleam) for serving content.
[web/server.gleam](src/cheekycms/web/server.gleam) connects them to the actor,
filesystem watcher, and Mist.

Most transformations are pure and have a corresponding focused test under
[`test`](test). The filesystem, watcher, process, and network effects stay near
the outer modules.

## Deployment

CheekyCMS includes a production container, continuous integration, and an
always-warm Fly.io configuration. Pushes to `main` deploy automatically after
all checks pass. See [DEPLOYMENT.md](DEPLOYMENT.md) for initial setup, manual
deployment, storage, and release verification.

CheekyCMS is available under the [MIT License](LICENSE).
