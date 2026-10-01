import cheekycms/content
import cheekycms/loader
import cheekycms/metadata
import cheekycms/source_path
import gleeunit/should
import simplifile

const fixture_root = "test/fixtures/content"

pub fn loads_a_collection_entry_test() {
  let assert Ok(content.SourceDocument(metadata: values, body: body, ..)) =
    loader.load(fixture_root, "personal-site/collections/posts/hello-world.md")

  values
  |> metadata.get("title")
  |> should.equal(Ok(metadata.StringValue("Hello World")))
  body
  |> content.markdown_to_string
  |> should.equal("# Hello World\n\nLoaded from disk.\n")
}

pub fn reports_missing_files_test() {
  loader.load(fixture_root, "personal-site/collections/posts/missing.md")
  |> should.equal(Error(loader.FileReadFailed(simplifile.Enoent)))
}

pub fn validates_paths_before_reading_test() {
  loader.load(fixture_root, "personal-site/pages/homepage.md")
  |> should.equal(Error(loader.InvalidPath(source_path.InvalidLayout)))
}
