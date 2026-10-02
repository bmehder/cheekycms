import cheekycms/content
import cheekycms/metadata
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{type Order}
import gleam/result
import gleam/string

pub type Direction {
  Ascending
  Descending
}

pub type Sort {
  Sort(field: String, direction: Direction)
}

pub type Options {
  Options(
    filters: List(#(String, String)),
    sort: Option(Sort),
    limit: Option(Int),
  )
}

pub type QueryError {
  EmptyParameter(String)
  DuplicateParameter(String)
  InvalidLimit
  InvalidSort
  UnknownField(String)
  UnsortableField(String)
}

pub fn error_code(error: QueryError) -> String {
  case error {
    UnknownField(_) -> "unknown_query_field"
    UnsortableField(_) -> "unsortable_query_field"
    _ -> "invalid_query"
  }
}

pub fn error_message(error: QueryError) -> String {
  case error {
    EmptyParameter(key) -> "Query parameter '" <> key <> "' cannot be empty."
    DuplicateParameter(key) ->
      "Query parameter '" <> key <> "' may only be provided once."
    InvalidLimit -> "The limit must be an integer from 1 to 100."
    InvalidSort -> "The sort field cannot be empty."
    UnknownField(field) ->
      "Metadata field '" <> field <> "' does not exist in this collection."
    UnsortableField(field) ->
      "Metadata field '" <> field <> "' cannot be sorted consistently."
  }
}

pub fn apply(
  contents: List(content.RenderedContent),
  parameters: List(#(String, String)),
) -> Result(List(content.RenderedContent), QueryError) {
  use options <- result.try(parse(parameters))
  use _ <- result.try(validate_fields(contents, options))
  let Options(filters:, sort:, limit:) = options
  let filtered =
    list.filter(contents, fn(item) {
      list.all(filters, fn(filter) { matches_filter(item, filter) })
    })
  use sorted <- result.try(sort_contents(filtered, sort))
  Ok(case limit {
    Some(limit) -> list.take(sorted, limit)
    None -> sorted
  })
}

pub fn parse(
  parameters: List(#(String, String)),
) -> Result(Options, QueryError) {
  use options <- result.try(list.try_fold(
    parameters,
    Options(filters: [], sort: None, limit: None),
    parse_parameter,
  ))
  let Options(filters:, ..) = options
  Ok(Options(..options, filters: list.reverse(filters)))
}

fn parse_parameter(options: Options, parameter: #(String, String)) {
  let #(key, value) = parameter
  case key, value {
    "", _ | _, "" -> Error(EmptyParameter(key))
    "limit", value -> parse_limit(options, value)
    "sort", value -> parse_sort(options, value)
    key, value ->
      Ok(Options(..options, filters: [#(key, value), ..options.filters]))
  }
}

fn parse_limit(options: Options, value: String) -> Result(Options, QueryError) {
  case options.limit, int.parse(value) {
    Some(_), _ -> Error(DuplicateParameter("limit"))
    None, Ok(limit) if limit > 0 && limit <= 100 ->
      Ok(Options(..options, limit: Some(limit)))
    _, _ -> Error(InvalidLimit)
  }
}

fn parse_sort(options: Options, value: String) -> Result(Options, QueryError) {
  case options.sort {
    Some(_) -> Error(DuplicateParameter("sort"))
    None -> {
      let #(field, direction) = case string.starts_with(value, "-") {
        True -> #(string.drop_start(value, 1), Descending)
        False -> #(value, Ascending)
      }
      case field {
        "" -> Error(InvalidSort)
        _ -> Ok(Options(..options, sort: Some(Sort(field:, direction:))))
      }
    }
  }
}

fn validate_fields(
  contents: List(content.RenderedContent),
  options: Options,
) -> Result(Nil, QueryError) {
  let Options(filters:, sort:, ..) = options
  use _ <- result.try(
    filters
    |> list.map(fn(filter) { filter.0 })
    |> list.unique
    |> list.try_each(validate_field(contents, _)),
  )
  case sort {
    None -> Ok(Nil)
    Some(Sort(field:, ..)) -> {
      use _ <- result.try(validate_field(contents, field))
      validate_sort_values(contents, field)
    }
  }
}

fn validate_field(
  contents: List(content.RenderedContent),
  field: String,
) -> Result(Nil, QueryError) {
  case
    list.any(contents, fn(item) { metadata_value(item, field) |> result.is_ok })
  {
    True -> Ok(Nil)
    False -> Error(UnknownField(field))
  }
}

fn validate_sort_values(
  contents: List(content.RenderedContent),
  field: String,
) -> Result(Nil, QueryError) {
  let values =
    list.filter_map(contents, fn(item) { metadata_value(item, field) })
  case values {
    [] -> Error(UnknownField(field))
    [first, ..rest] ->
      case sortable(first) && list.all(rest, same_sort_type(first, _)) {
        True -> Ok(Nil)
        False -> Error(UnsortableField(field))
      }
  }
}

fn matches_filter(
  item: content.RenderedContent,
  filter: #(String, String),
) -> Bool {
  let #(field, expected) = filter
  case metadata_value(item, field) {
    Ok(value) -> value_matches(value, expected)
    Error(Nil) -> False
  }
}

fn metadata_value(
  item: content.RenderedContent,
  field: String,
) -> Result(metadata.Value, Nil) {
  let content.RenderedContent(metadata: values, ..) = item
  metadata.get(values, field)
}

fn value_matches(value: metadata.Value, expected: String) -> Bool {
  case value {
    metadata.StringValue(value) -> value == expected
    metadata.IntValue(value) -> int.parse(expected) == Ok(value)
    metadata.FloatValue(value) -> float.parse(expected) == Ok(value)
    metadata.BoolValue(True) -> expected == "true"
    metadata.BoolValue(False) -> expected == "false"
    metadata.NullValue -> expected == "null"
    metadata.ListValue(values) -> list.any(values, value_matches(_, expected))
    metadata.ObjectValue(_) -> False
  }
}

fn sort_contents(
  contents: List(content.RenderedContent),
  sort: Option(Sort),
) -> Result(List(content.RenderedContent), QueryError) {
  case sort {
    None -> Ok(contents)
    Some(Sort(field:, direction:)) -> {
      let sorter = fn(left, right) {
        compare_items(left, right, field, direction)
      }
      Ok(list.sort(contents, sorter))
    }
  }
}

fn compare_items(
  left: content.RenderedContent,
  right: content.RenderedContent,
  field: String,
  direction: Direction,
) -> Order {
  case metadata_value(left, field), metadata_value(right, field) {
    Error(Nil), Error(Nil) -> order.Eq
    Error(Nil), Ok(_) -> order.Gt
    Ok(_), Error(Nil) -> order.Lt
    Ok(left), Ok(right) -> {
      let compared = compare_values(left, right)
      case direction {
        Ascending -> compared
        Descending -> flip_order(compared)
      }
    }
  }
}

fn flip_order(value: Order) -> Order {
  case value {
    order.Lt -> order.Gt
    order.Eq -> order.Eq
    order.Gt -> order.Lt
  }
}

fn sortable(value: metadata.Value) -> Bool {
  case value {
    metadata.StringValue(_)
    | metadata.IntValue(_)
    | metadata.FloatValue(_)
    | metadata.BoolValue(_) -> True
    _ -> False
  }
}

fn same_sort_type(first: metadata.Value, next: metadata.Value) -> Bool {
  case first, next {
    metadata.StringValue(_), metadata.StringValue(_)
    | metadata.IntValue(_), metadata.IntValue(_)
    | metadata.FloatValue(_), metadata.FloatValue(_)
    | metadata.BoolValue(_), metadata.BoolValue(_)
    -> True
    _, _ -> False
  }
}

fn compare_values(left: metadata.Value, right: metadata.Value) -> Order {
  case left, right {
    metadata.StringValue(left), metadata.StringValue(right) ->
      string.compare(left, right)
    metadata.IntValue(left), metadata.IntValue(right) ->
      int.compare(left, right)
    metadata.FloatValue(left), metadata.FloatValue(right) ->
      float.compare(left, right)
    metadata.BoolValue(False), metadata.BoolValue(True) -> order.Lt
    metadata.BoolValue(True), metadata.BoolValue(False) -> order.Gt
    _, _ -> order.Eq
  }
}
