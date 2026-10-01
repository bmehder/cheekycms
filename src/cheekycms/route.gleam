import cheekycms/identifier
import cheekycms/query
import gleam/result
import gleam/string
import gleam/uri

pub type Route {
  Index
  Content(query.Query)
}

/// A request path which cannot be converted into a content query.
pub type RouteError {
  RouteNotFound
  InvalidPercentEncoding
  InvalidIdentifier(identifier.IdentifierError)
}

/// Parse an API request path into a typed content query.
///
/// A single trailing slash is accepted. Query strings and full URLs are not;
/// callers should pass only the request path supplied by their HTTP server.
pub fn parse(path: String) -> Result(Route, RouteError) {
  let path = drop_trailing_slash(path)

  case string.split(path, on: "/") {
    ["", "api"] -> Ok(Index)
    ["", "api", project] -> {
      use project <- result.try(parse_project(project))
      Ok(Content(query.Project(project)))
    }
    ["", "api", project, "collections", collection] -> {
      use project <- result.try(parse_project(project))
      use collection <- result.try(parse_collection(collection))
      Ok(Content(query.Collection(project, collection)))
    }
    ["", "api", project, "collections", collection, slug] -> {
      use project <- result.try(parse_project(project))
      use collection <- result.try(parse_collection(collection))
      use slug <- result.try(parse_slug(slug))
      Ok(Content(query.Entry(project, collection, slug)))
    }
    ["", "api", project, "singletons", name] -> {
      use project <- result.try(parse_project(project))
      use name <- result.try(parse_content_name(name))
      Ok(Content(query.Singleton(project, name)))
    }
    _ -> Error(RouteNotFound)
  }
}

fn drop_trailing_slash(path: String) -> String {
  case path != "/" && string.ends_with(path, "/") {
    True -> string.drop_end(path, 1)
    False -> path
  }
}

fn parse_project(segment: String) -> Result(identifier.ProjectId, RouteError) {
  use value <- result.try(decode_segment(segment))
  identifier.project_id(value)
  |> result.map_error(InvalidIdentifier)
}

fn parse_collection(
  segment: String,
) -> Result(identifier.CollectionName, RouteError) {
  use value <- result.try(decode_segment(segment))
  identifier.collection_name(value)
  |> result.map_error(InvalidIdentifier)
}

fn parse_slug(segment: String) -> Result(identifier.Slug, RouteError) {
  use value <- result.try(decode_segment(segment))
  identifier.slug(value)
  |> result.map_error(InvalidIdentifier)
}

fn parse_content_name(
  segment: String,
) -> Result(identifier.ContentName, RouteError) {
  use value <- result.try(decode_segment(segment))
  identifier.content_name(value)
  |> result.map_error(InvalidIdentifier)
}

fn decode_segment(segment: String) -> Result(String, RouteError) {
  uri.percent_decode(segment)
  |> result.map_error(fn(_) { InvalidPercentEncoding })
}
