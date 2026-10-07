# Changelog

Notable changes to CheekyCMS are recorded here.

## Unreleased

## 0.2.0 — 2026-10-07

First tagged pre-1.0 release baseline.

- Serve multiple projects, singletons, and collections from Markdown with YAML frontmatter.
- Expose a read-only, self-documenting JSON API with collection filtering and sorting.
- Render Markdown to HTML while preserving typed metadata.
- Watch content on the BEAM and reload the catalogue without restarting the server.
- Serve repository-backed files safely, including byte ranges and optimized image variants.
- Document the portable Markdown contract 1.0.0 used across related projects.
- Dogfood CheekyCMS for its marketing site, guides, and sample content.
- Generate and self-host the Gleam implementation reference at `/reference/`.
- Build, test, and deploy automatically through GitHub Actions and Fly.io.

## Release policy

CheekyCMS follows semantic versioning and releases independently from Docklands,
Chippy, and the portable Markdown contract. The project version and contract
version are intentionally separate. Each annotated `vX.Y.Z` tag points to the
checked commit for that release; later work is recorded under **Unreleased**.
