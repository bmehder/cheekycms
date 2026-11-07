---
title: Inside CheekyCMS
description: A guided tour from a Markdown file on disk to JSON over HTTP.
published: "2026-10-02"
order: 1
tags:
  - gleam
  - architecture
  - tutorial
---

# Inside CheekyCMS

CheekyCMS has two main flows. First it loads Markdown into memory; then it answers requests from that in-memory catalogue.

```text
Loading:  files → frontmatter → rendered HTML → catalogue
Serving:  request → route → selection → JSON → response
```

Rendering happens when content loads, rather than on every request. The runtime store holds the last complete valid catalogue.

## Find your way around

```text
src/cheekycms.gleam       Entry point: configuration and startup
src/cheekycms/
  content.gleam          Shared document types
  content/               Loading, parsing, identity, metadata, catalogue
  api.gleam              Coordinate content API responses
  api/                   Routes, selection, filtering, JSON, API index
  runtime/store.gleam    Actor holding the live catalogue
  web/                   HTTP startup, files, CORS, configuration
  assets_build.gleam     Build-time image optimization
src/marketing.gleam      Demo website route handler
src/marketing/           Website page responses, HTML shell, CSS, favicon
```

Start with the loading and serving sections below. The later sections explain supporting features when you need them.

## Follow one Markdown file

Content lives in two supported directory shapes:

```text
content/<project>/singletons/<name>.md
content/<project>/collections/<collection>/<slug>.md
```

For this guide, the project is `cheekycms`, the collection is `guides`, and the slug is `inside-cheekycms`. These come from its path, rather than its frontmatter.

Open `src/cheekycms/content.gleam` to see the document types. A `SourceDocument` contains metadata and Markdown; a `RenderedContent` contains metadata and HTML. Opaque Markdown and HTML wrappers prevent accidentally passing unrendered text as rendered content.

Now read `src/cheekycms/content/load.gleam`. Its three entry points describe the complete loading flow:

1. `discover` finds and sorts Markdown paths, loads and renders each document, and constructs the catalogue.
2. `load` derives a document identity, reads one file, and parses its frontmatter.
3. `render` uses Mörk to convert the Markdown body to HTML while preserving identity and metadata.

The single-document functions remain public so tests and other callers can exercise each stage directly.

Only open the supporting modules when you want their details:

- `content/source_path.gleam` interprets the two path shapes.
- `content/identifier.gleam` validates project IDs, collection names, slugs, and singleton names.
- `content/frontmatter.gleam` separates YAML from Markdown and converts YAML values.
- `content/metadata.gleam` represents strings, numbers, booleans, lists, objects, and null.
- `content/catalogue.gleam` stores ordered items and indexes them by identity, rejecting duplicates.

Discovery collects errors and returns no partial catalogue. Raw HTML is trusted because repository authors control published content.

## Follow one request

For this guide, request:

```text
GET /api/cheekycms/collections/guides/inside-cheekycms
```

Read `src/cheekycms/api.gleam`. It coordinates the content API and returns plain response data: status, content type, and body.

Its supporting modules answer distinct questions:

| Module | Question |
|---|---|
| `api/route.gleam` | What does this URL request? |
| `api/select.gleam` | Which content matches that typed request? |
| `api/filter.gleam` | How should collection entries be filtered, sorted, and limited? |
| `api/json.gleam` | How does the result become JSON? |
| `api/index.gleam` | Which projects, routes, and metadata fields exist? |

Selection does not need an HTTP server. Route parsing does not need to read files. You can test both using ordinary values.

The API index at `/api` describes loaded content. The generated Gleam reference at `/reference/` describes the implementation's modules, types, and functions.

## Understand startup and the live catalogue

Read `src/cheekycms.gleam`, followed by `src/cheekycms/web/server.gleam`.

The entry point loads validated environment configuration from `web/config.gleam`. The server loads the initial catalogue, starts the store actor and filesystem watcher, then starts Mist.

`runtime/store.gleam` owns the live catalogue. Snapshot requests and reload messages are handled serially by the actor. Polly requests a reload when files change. Successful discovery replaces the catalogue as a whole. A failed reload records the errors for `/health` and keeps the previous valid catalogue available.

## Follow HTTP dispatch

The live handler checks reference files, then public assets, then delegates to `marketing.handle` before handling API requests. The supporting web modules contain the details:

- `web/files.gleam` streams files and handles single byte ranges.
- `web/asset.gleam` validates asset paths, assigns media types, and makes active formats download.
- `web/reference.gleam` resolves generated documentation files.
- `web/cors.gleam` applies the configured browser access policy.

The marketing website lives outside the CMS modules. `src/marketing.gleam` owns `/` and `/favicon.svg`; `src/marketing/pages.gleam` builds their responses; `src/marketing/layout.gleam` supplies the HTML shell, CSS, and favicon artwork. The server's connection is the call to `marketing.handle`.

The website runs in the same process and deployment as the CMS. It demonstrates consuming CMS content; page rendering and branding belong to the website. The homepage comes from `content/cheekycms/singletons/homepage.md` in the same catalogue used by the API. File delivery sits outside that catalogue because media should be streamed rather than encoded as content JSON.

## Images and deployment

`src/cheekycms/assets_build.gleam` generates responsive WebP variants during the build using Alakazam and ImageMagick.

The Dockerfile generates assets and the Gleam reference, exports an Erlang shipment, and copies the results and content into the runtime image. Fly.io keeps one machine warm. GitHub Actions verifies and deploys pushes to main.

## Read the tests beside the code

Tests retain descriptive names such as `loader_test.gleam`, `discovery_test.gleam`, and `renderer_test.gleam`, even though those stages now live together in `content/load.gleam`. Their imports identify the module under test.

Read a test, predict its result, and then follow the function it calls. Adapter tests construct HTTP requests without binding a socket. Run `gleam test` after a change.

A useful first exercise is to add a Markdown fixture, follow its identity through discovery, and then select it through the API.
