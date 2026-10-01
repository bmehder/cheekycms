import cheekycms/metadata
import gleam/dict
import gleeunit/should

pub fn metadata_supports_nested_dynamic_values_test() {
  let value =
    metadata.from_list([
      #("title", metadata.StringValue("Hello")),
      #("featured", metadata.BoolValue(True)),
      #(
        "author",
        metadata.ObjectValue(
          dict.from_list([#("name", metadata.StringValue("Brad"))]),
        ),
      ),
      #(
        "tags",
        metadata.ListValue([
          metadata.StringValue("gleam"),
          metadata.StringValue("cms"),
        ]),
      ),
    ])

  value
  |> metadata.get("title")
  |> should.equal(Ok(metadata.StringValue("Hello")))
}

pub fn missing_metadata_is_explicit_test() {
  metadata.empty()
  |> metadata.get("missing")
  |> should.be_error()
}
