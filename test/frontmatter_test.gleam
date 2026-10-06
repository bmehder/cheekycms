import cheekycms/content
import cheekycms/frontmatter
import cheekycms/identifier
import cheekycms/metadata
import gleam/dict
import gleam/list
import gleeunit/should

const complete_document = "---
title: Hello World
featured: true
rating: 4.5
tags:
  - gleam
  - cms
author:
  name: Brad
---
# Hello World

This is the body.
"

fn content_id() -> content.ContentId {
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(collection) = identifier.collection_name("posts")
  let assert Ok(slug) = identifier.slug("hello-world")
  content.Entry(project, collection, slug)
}

pub fn parses_frontmatter_and_preserves_markdown_body_test() {
  let assert Ok(content.SourceDocument(metadata: values, body: body, ..)) =
    frontmatter.parse(content_id(), complete_document)

  values
  |> metadata.get("title")
  |> should.equal(Ok(metadata.StringValue("Hello World")))
  values
  |> metadata.get("featured")
  |> should.equal(Ok(metadata.BoolValue(True)))
  values
  |> metadata.get("rating")
  |> should.equal(Ok(metadata.FloatValue(4.5)))
  values
  |> metadata.get("tags")
  |> should.equal(
    Ok(
      metadata.ListValue([
        metadata.StringValue("gleam"),
        metadata.StringValue("cms"),
      ]),
    ),
  )
  values
  |> metadata.get("author")
  |> should.equal(
    Ok(
      metadata.ObjectValue(
        dict.from_list([
          #("name", metadata.StringValue("Brad")),
        ]),
      ),
    ),
  )
  body
  |> content.markdown_to_string
  |> should.equal("# Hello World\n\nThis is the body.\n")
}

pub fn plain_and_quoted_core_strings_have_the_same_values_test() {
  let plain =
    "---\ntitle: A portable page\ndescription: A short summary.\npublished: 2026-10-06\n---\n"
  let quoted =
    "---\ntitle: \"A portable page\"\ndescription: \"A short summary.\"\npublished: \"2026-10-06\"\n---\n"
  let assert Ok(content.SourceDocument(metadata: plain_values, ..)) =
    frontmatter.parse(content_id(), plain)
  let assert Ok(content.SourceDocument(metadata: quoted_values, ..)) =
    frontmatter.parse(content_id(), quoted)

  ["title", "description", "published"]
  |> list.map(fn(key) { metadata.get(plain_values, key) })
  |> should.equal(
    ["title", "description", "published"]
    |> list.map(fn(key) { metadata.get(quoted_values, key) }),
  )
}

pub fn accepts_markdown_without_frontmatter_test() {
  let source = "# Just Markdown\n\nNo metadata here."
  let assert Ok(content.SourceDocument(metadata: values, body: body, ..)) =
    frontmatter.parse(content_id(), source)

  metadata.to_dict(values)
  |> dict.size
  |> should.equal(0)
  content.markdown_to_string(body)
  |> should.equal(source)
}

pub fn accepts_empty_frontmatter_test() {
  let assert Ok(content.SourceDocument(metadata: values, ..)) =
    frontmatter.parse(content_id(), "---\n\n---\n# Hello")

  metadata.to_dict(values)
  |> dict.size
  |> should.equal(0)
}

pub fn rejects_an_unclosed_frontmatter_block_test() {
  frontmatter.parse(content_id(), "---\ntitle: Hello\n# No closing delimiter")
  |> should.equal(Error(frontmatter.MissingClosingDelimiter))
}

pub fn rejects_invalid_yaml_test() {
  let result =
    frontmatter.parse(content_id(), "---\ntags: [one, two\n---\nBody")

  case result {
    Error(frontmatter.InvalidYaml(_)) -> Nil
    _ -> should.fail()
  }
}

pub fn rejects_non_object_frontmatter_test() {
  frontmatter.parse(content_id(), "---\n- one\n- two\n---\nBody")
  |> should.equal(Error(frontmatter.FrontmatterMustBeObject))
}
