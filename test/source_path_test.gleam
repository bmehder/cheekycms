import cheekycms/content
import cheekycms/identifier
import cheekycms/source_path
import gleeunit/should

pub fn derives_a_collection_entry_id_test() {
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(collection) = identifier.collection_name("posts")
  let assert Ok(slug) = identifier.slug("hello-world")

  source_path.content_id("personal-site/collections/posts/hello-world.md")
  |> should.equal(Ok(content.Entry(project, collection, slug)))
}

pub fn derives_a_singleton_id_test() {
  let assert Ok(project) = identifier.project_id("personal-site")
  let assert Ok(name) = identifier.content_name("homepage")

  source_path.content_id("personal-site/singletons/homepage.md")
  |> should.equal(Ok(content.Singleton(project, name)))
}

pub fn rejects_non_markdown_files_test() {
  source_path.content_id("personal-site/singletons/homepage.html")
  |> should.equal(Error(source_path.NotMarkdown))
}

pub fn rejects_unknown_layouts_test() {
  source_path.content_id("personal-site/posts/hello-world.md")
  |> should.equal(Error(source_path.InvalidLayout))
}

pub fn rejects_nested_collection_entries_test() {
  source_path.content_id("personal-site/collections/posts/2026/hello-world.md")
  |> should.equal(Error(source_path.InvalidLayout))
}

pub fn rejects_path_traversal_test() {
  source_path.content_id("../collections/posts/hello-world.md")
  |> should.equal(Error(source_path.TraversalNotAllowed))
}
