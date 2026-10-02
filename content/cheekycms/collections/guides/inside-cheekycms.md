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

This tutorial follows one piece of content through the complete application: from a Markdown file, through parsing and an in-memory catalogue, to a JSON response served by Mist. Read the files in the order below and keep this guide beside the code.

CheekyCMS is deliberately small. Most modules do one transformation, and the effects—filesystem access, processes, and HTTP—stay near the outside. You do not need to understand OTP before beginning.

## 1. Start with the shape of the repository

The important directories are:

```text
content/                 Markdown and YAML frontmatter
assets/                  Images, documents, and other public files
src/cheekycms/           Application modules
test/                    Unit and adapter tests
.github/workflows/       Verification and automatic deployment
```

Content paths are meaningful. These two forms are the entire content model:

```text
content/<project>/singletons/<name>.md
content/<project>/collections/<collection>/<slug>.md
```

For example, this tutorial is a `guides` entry in the `cheekycms` project. Its identity becomes:

```text
GET /api/cheekycms/collections/guides/inside-cheekycms
```

The project name is not a global configuration value. It comes directly from the directory containing the content.

## 2. Meet the domain types

Open `src/cheekycms/content.gleam`. It defines the small vocabulary used throughout the application:

- `ContentId` distinguishes collection entries from singletons.
- `Markdown` wraps source text that has not been rendered.
- `Html` wraps trusted renderer output.
- `SourceDocument` contains parsed frontmatter and Markdown.
- `RenderedContent` contains metadata and final HTML.

The `Markdown` and `Html` types are opaque. Both contain strings, but the compiler prevents accidentally treating unrendered Markdown as finished HTML.

Next, open `src/cheekycms/metadata.gleam`. YAML values become a recursive `Value` type supporting strings, integers, floats, booleans, lists, objects, and null. `Metadata` is an opaque dictionary, so callers use its public functions rather than depending on its representation.

Finally, look at `src/cheekycms/identifier.gleam`. Project IDs, collection names, slugs, and singleton names are separate opaque types. Their constructors reject empty values, path separators, and reserved path segments. This makes invalid identifiers difficult to pass deeper into the program.

## 3. Turn a path into an identity

Open `src/cheekycms/source_path.gleam`. Its main job is translating repository structure into a typed `ContentId`.

Conceptually:

```text
cheekycms/collections/guides/inside-cheekycms.md
                         ↓
Entry(ProjectId("cheekycms"), CollectionName("guides"), Slug("inside-cheekycms"))
```

Only the two documented directory shapes are accepted. That constraint keeps route generation and lookup predictable without introducing collection configuration files.

## 4. Load and parse a document

Follow the path into `src/cheekycms/loader.gleam`. The loader:

1. Derives the typed identity from the relative path.
2. Reads the source file beneath the configured content root.
3. Sends the source to `frontmatter.parse`.

Now open `src/cheekycms/frontmatter.gleam`. It separates the YAML block between the opening and closing `---` markers from the Markdown body. Yamleam decodes the YAML, and the module recursively converts each decoded value into CheekyCMS metadata.

Errors remain explicit values. A bad path, failed file read, malformed frontmatter, or unsupported YAML value is returned rather than silently ignored.

## 5. Render Markdown once

Open `src/cheekycms/renderer.gleam`. This is one of the smallest modules in the project. Mörk converts the Markdown body to HTML while the identity and metadata pass through unchanged.

Rendering happens during discovery, not on every HTTP request. Raw HTML is allowed because repository content is considered trusted author input. That is convenient for the marketing homepage, but it also means write access to the content repository is equivalent to permission to publish HTML.

## 6. Discover the whole content tree

Open `src/cheekycms/discovery.gleam`. Discovery finds files beneath `content/`, keeps the Markdown files, sorts their paths for deterministic behavior, and runs the loader and renderer for each one.

The results go into `src/cheekycms/catalogue.gleam`. A catalogue stores both an ordered list and a dictionary indexed by `ContentId`. Construction rejects duplicate identities rather than choosing one file unpredictably.

This is the first important performance decision: requests read already-parsed metadata and already-rendered HTML from memory.

## 7. Keep the last good catalogue alive

Open `src/cheekycms/catalogue_store.gleam`. The catalogue lives inside a lightweight BEAM actor. The store answers snapshot requests and handles reload messages serially.

When files change, Polly asks the store to reload the entire content tree. A valid replacement becomes the new snapshot atomically. If any content is invalid, the error is recorded for `/health`, but the last valid snapshot continues serving requests.

This gives CheekyCMS a useful property without locks or partial updates: every request sees either the complete old catalogue or the complete new one.

## 8. Parse URLs and run queries

Open these modules together:

- `src/cheekycms/route.gleam` turns an encoded URL path into a typed query.
- `src/cheekycms/query.gleam` selects projects, collections, entries, or singletons from the catalogue.
- `src/cheekycms/collection_query.gleam` applies metadata filters, sorting, and limits to collection results.

Routing and querying are separate deliberately. The query layer knows nothing about HTTP, and the route layer knows nothing about storage. Tests can exercise both without starting a server.

Try these against the live installation:

```text
/api/cheekycms
/api/cheekycms/collections/guides
/api/cheekycms/collections/guides/inside-cheekycms
/api/studio/collections/projects?featured=true
```

## 9. Encode the public API

Open `src/cheekycms/api_json.gleam`. It converts typed content and metadata values into `gleam_json` values. This is where `RenderedContent` becomes the familiar response containing `metadata` and `html`.

Then open `src/cheekycms/api.gleam`. It coordinates route parsing, query execution, collection controls, API discovery, health information, and consistent JSON errors. Its custom `Response` type is transport-neutral: status, content type, and body are plain data.

`src/cheekycms/documentation.gleam` builds the `/api` discovery document by inspecting the catalogue. That is why adding this project automatically adds its routes and observed metadata fields to the API index.

## 10. Reach the network boundary

Open `src/cheekycms/server.gleam`. This is the adapter between transport-neutral application logic and Mist.

The server starts the initial catalogue, actor, filesystem watcher, and HTTP listener. For each request it:

1. Checks whether the path is an asset request.
2. Serves the CMS-authored homepage at `/` when requested.
3. Handles `/health` from the current store status.
4. Delegates API paths to the transport-neutral API module.
5. Adds configured CORS headers.

The homepage is a useful dogfooding example. `content/cheekycms/singletons/homepage.md` owns its words and markup. `src/cheekycms/landing.gleam` owns only the reusable HTML document shell and CSS. The root handler reads the rendered singleton from the same catalogue used by `/api`.

## 11. Follow an asset

Open `src/cheekycms/asset.gleam`. It resolves `/assets/...` paths beneath the configured asset root, blocks traversal, assigns content types, and forces potentially active formats to download rather than execute inline.

`src/cheekycms/assets_build.gleam` uses Alakazam and ImageMagick during the container build to generate 480, 960, and 1600 pixel WebP variants from supported `*-source` images.

The server streams asset files and understands single byte ranges, allowing browsers to seek through PDFs, audio, and video without loading an entire file first.

## 12. Start at `main`

Only now open `src/cheekycms.gleam`. Its `main` function loads environment configuration and starts the server. There is little code here because all interesting decisions live in testable modules.

`src/cheekycms/server_config.gleam` turns environment variables into a validated configuration. The defaults use local `content/` and `assets/` directories; the container supplies their `/app` locations.

## 13. Read the tests beside the code

The tests mirror the modules. A productive loop is:

1. Read one source module.
2. Find the similarly named file under `test/`.
3. Predict the edge cases before reading the assertions.
4. Change or add a fixture under `test/fixtures/content/`.
5. Run `gleam test`.

The server adapter tests do not bind a network port. They construct Gleam HTTP requests and inspect returned responses directly. That keeps the suite quick while still covering routing, headers, CORS, and the homepage.

## 14. Understand deployment last

The `Dockerfile` exports an Erlang shipment, copies content and generated assets into a small runtime image, and runs as an unprivileged user. The `fly.toml` keeps one Fly Machine warm.

`.github/workflows/ci.yml` is the publishing path. A push to `main` formats, tests, exports the shipment, builds the container, and deploys only after every preceding job passes. Content publishing and application deployment are intentionally the same Git workflow.

## Exercises

Once the tour makes sense, try these in order:

1. Add a metadata field to this document and find it in the API response.
2. Add a second guide and watch `/api` discover it automatically.
3. Filter a collection by one of your new metadata fields.
4. Introduce malformed YAML locally and inspect the discovery error.
5. Add a new content route test before changing its implementation.
6. Replace one section of the marketing homepage by editing only its Markdown singleton.

If you can trace those changes from disk to JSON, you understand the core of CheekyCMS.
