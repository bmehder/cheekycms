import cheekycms/content.{type ContentId, type SourceDocument}
import cheekycms/metadata
import gleam/dict
import gleam/list
import gleam/result
import gleam/string
import yamleam
import yamleam/node

const opening_delimiter = "---\n"

const closing_delimiter = "\n---\n"

/// An error encountered while turning a Markdown file into source content.
pub type ParseError {
  MissingClosingDelimiter
  InvalidYaml(yamleam.YamlError)
  FrontmatterMustBeObject
}

/// Parse an optional YAML frontmatter block and Markdown body.
///
/// Content identity comes from the caller because it will eventually be
/// derived from the file's location, not from the file's contents.
pub fn parse(
  id: ContentId,
  source: String,
) -> Result(SourceDocument, ParseError) {
  case string.starts_with(source, opening_delimiter) {
    False ->
      Ok(content.SourceDocument(
        id:,
        metadata: metadata.empty(),
        body: content.markdown(source),
      ))
    True -> parse_with_frontmatter(id, source)
  }
}

fn parse_with_frontmatter(
  id: ContentId,
  source: String,
) -> Result(SourceDocument, ParseError) {
  let after_opening =
    string.drop_start(source, string.length(opening_delimiter))

  case string.split_once(after_opening, on: closing_delimiter) {
    Error(Nil) -> Error(MissingClosingDelimiter)
    Ok(#(yaml_source, markdown_source)) -> {
      use parsed_metadata <- result.try(parse_metadata(yaml_source))

      Ok(content.SourceDocument(
        id:,
        metadata: parsed_metadata,
        body: content.markdown(markdown_source),
      ))
    }
  }
}

fn parse_metadata(source: String) -> Result(metadata.Metadata, ParseError) {
  case string.trim(source) {
    "" -> Ok(metadata.empty())
    _ ->
      case yamleam.parse_raw(source) {
        Error(error) -> Error(InvalidYaml(error))
        Ok(node.YamlMap(entries)) ->
          entries
          |> list.map(fn(entry) {
            let #(key, value) = entry
            #(key, yaml_value_to_metadata(value))
          })
          |> metadata.from_list
          |> Ok
        Ok(_) -> Error(FrontmatterMustBeObject)
      }
  }
}

fn yaml_value_to_metadata(value: node.YamlNode) -> metadata.Value {
  case value {
    node.YamlNull -> metadata.NullValue
    node.YamlBool(value) -> metadata.BoolValue(value)
    node.YamlInt(value) -> metadata.IntValue(value)
    node.YamlFloat(value) -> metadata.FloatValue(value)
    node.YamlString(value) -> metadata.StringValue(value)
    node.YamlList(values) ->
      values
      |> list.map(yaml_value_to_metadata)
      |> metadata.ListValue
    node.YamlMap(entries) ->
      entries
      |> list.map(fn(entry) {
        let #(key, value) = entry
        #(key, yaml_value_to_metadata(value))
      })
      |> dict.from_list
      |> metadata.ObjectValue
  }
}
