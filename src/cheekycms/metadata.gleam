import gleam/dict.{type Dict}

/// A metadata value supported by CheekyCMS frontmatter and its JSON API.
pub type Value {
  StringValue(String)
  IntValue(Int)
  FloatValue(Float)
  BoolValue(Bool)
  ListValue(List(Value))
  ObjectValue(Dict(String, Value))
  NullValue
}

/// Arbitrary metadata attached to a content document.
pub opaque type Metadata {
  Metadata(Dict(String, Value))
}

pub fn empty() -> Metadata {
  Metadata(dict.new())
}

pub fn from_list(entries: List(#(String, Value))) -> Metadata {
  Metadata(dict.from_list(entries))
}

pub fn get(metadata: Metadata, key: String) -> Result(Value, Nil) {
  let Metadata(values) = metadata
  dict.get(values, key)
}

pub fn to_dict(metadata: Metadata) -> Dict(String, Value) {
  let Metadata(values) = metadata
  values
}
