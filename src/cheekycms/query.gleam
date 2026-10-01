import cheekycms/catalogue
import cheekycms/content
import cheekycms/identifier.{
  type CollectionName, type ContentName, type ProjectId, type Slug,
}
import gleam/list

/// A content request independent of any particular URL structure.
pub type Query {
  AllContent
  Project(ProjectId)
  Collection(project: ProjectId, collection: CollectionName)
  Entry(project: ProjectId, collection: CollectionName, slug: Slug)
  Singleton(project: ProjectId, name: ContentName)
}

/// The successful result of a content query.
pub type Selection {
  Many(List(content.RenderedContent))
  One(content.RenderedContent)
}

/// A well-formed query which did not identify any content.
pub type QueryError {
  ProjectNotFound(ProjectId)
  CollectionNotFound(project: ProjectId, collection: CollectionName)
  EntryNotFound(project: ProjectId, collection: CollectionName, slug: Slug)
  SingletonNotFound(project: ProjectId, name: ContentName)
}

/// Run a typed content query against a complete catalogue.
pub fn run(
  catalogue: catalogue.Catalogue,
  query: Query,
) -> Result(Selection, QueryError) {
  case query {
    AllContent -> Ok(Many(all_content(catalogue)))
    Project(project) -> select_project(catalogue, project)
    Collection(project, collection) ->
      select_collection(catalogue, project, collection)
    Entry(project, collection, slug) ->
      select_entry(catalogue, project, collection, slug)
    Singleton(project, name) -> select_singleton(catalogue, project, name)
  }
}

fn all_content(
  catalogue: catalogue.Catalogue,
) -> List(content.RenderedContent) {
  catalogue
  |> catalogue.all
  |> list.map(fn(item) {
    let catalogue.Item(content:, ..) = item
    content
  })
}

fn select_project(
  catalogue: catalogue.Catalogue,
  project: ProjectId,
) -> Result(Selection, QueryError) {
  catalogue
  |> all_content
  |> list.filter(fn(rendered) {
    let content.RenderedContent(id:, ..) = rendered
    project_for(id) == project
  })
  |> many_or_error(ProjectNotFound(project))
}

fn select_collection(
  catalogue: catalogue.Catalogue,
  project: ProjectId,
  collection: CollectionName,
) -> Result(Selection, QueryError) {
  catalogue
  |> all_content
  |> list.filter(fn(rendered) {
    let content.RenderedContent(id:, ..) = rendered
    id_is_in_collection(id, project, collection)
  })
  |> many_or_error(CollectionNotFound(project, collection))
}

fn select_entry(
  catalogue: catalogue.Catalogue,
  project: ProjectId,
  collection: CollectionName,
  slug: Slug,
) -> Result(Selection, QueryError) {
  let id = content.Entry(project, collection, slug)

  case catalogue.get(catalogue, id) {
    Ok(catalogue.Item(content:, ..)) -> Ok(One(content))
    Error(Nil) -> Error(EntryNotFound(project, collection, slug))
  }
}

fn select_singleton(
  catalogue: catalogue.Catalogue,
  project: ProjectId,
  name: ContentName,
) -> Result(Selection, QueryError) {
  let id = content.Singleton(project, name)

  case catalogue.get(catalogue, id) {
    Ok(catalogue.Item(content:, ..)) -> Ok(One(content))
    Error(Nil) -> Error(SingletonNotFound(project, name))
  }
}

fn many_or_error(
  contents: List(content.RenderedContent),
  error: QueryError,
) -> Result(Selection, QueryError) {
  case contents {
    [] -> Error(error)
    _ -> Ok(Many(contents))
  }
}

fn project_for(id: content.ContentId) -> ProjectId {
  case id {
    content.Entry(project, ..) | content.Singleton(project, ..) -> project
  }
}

fn id_is_in_collection(
  id: content.ContentId,
  project: ProjectId,
  collection: CollectionName,
) -> Bool {
  case id {
    content.Entry(entry_project, entry_collection, ..) ->
      entry_project == project && entry_collection == collection
    content.Singleton(..) -> False
  }
}
