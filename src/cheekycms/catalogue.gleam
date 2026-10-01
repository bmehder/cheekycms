import cheekycms/content
import gleam/dict.{type Dict}
import gleam/list

/// Rendered content together with the path it was loaded from.
pub type Item {
  Item(path: String, content: content.RenderedContent)
}

/// Two files resolved to the same content identity.
pub type Duplicate {
  Duplicate(id: content.ContentId, first_path: String, duplicate_path: String)
}

/// A complete set of uniquely identified, rendered content.
pub opaque type Catalogue {
  Catalogue(items: List(Item), by_id: Dict(content.ContentId, Item))
}

/// Construct a catalogue, rejecting every duplicate identity found.
pub fn from_items(items: List(Item)) -> Result(Catalogue, List(Duplicate)) {
  let #(by_id, duplicates) =
    list.fold(items, #(dict.new(), []), fn(state, item) {
      let #(by_id, duplicates) = state
      let Item(path:, content: rendered) = item
      let content.RenderedContent(id:, ..) = rendered

      case dict.get(by_id, id) {
        Error(Nil) -> #(dict.insert(by_id, id, item), duplicates)
        Ok(Item(path: first_path, ..)) -> #(by_id, [
          Duplicate(id:, first_path:, duplicate_path: path),
          ..duplicates
        ])
      }
    })

  case duplicates {
    [] -> Ok(Catalogue(items:, by_id:))
    _ -> Error(list.reverse(duplicates))
  }
}

pub fn all(catalogue: Catalogue) -> List(Item) {
  catalogue.items
}

pub fn get(catalogue: Catalogue, id: content.ContentId) -> Result(Item, Nil) {
  dict.get(catalogue.by_id, id)
}

pub fn size(catalogue: Catalogue) -> Int {
  list.length(catalogue.items)
}
