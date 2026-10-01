import cheekycms/catalogue
import cheekycms/discovery
import cheekycms/documentation
import cheekycms/identifier
import gleam/dict
import gleeunit/should

fn fixture_catalogue() -> catalogue.Catalogue {
  let assert Ok(value) = discovery.discover("test/fixtures/content")
  value
}

pub fn derives_routes_and_metadata_from_the_catalogue_test() {
  let documentation.Index(projects:) = documentation.build(fixture_catalogue())
  let assert [course_site, personal_site] = projects

  let assert documentation.Project(
    id: course_id,
    endpoint: course_endpoint,
    collections: course_collections,
    singletons: [],
  ) = course_site
  identifier.project_id_to_string(course_id)
  |> should.equal("course-site")
  course_endpoint
  |> should.equal("/api/course-site")

  let assert [course_collection] = course_collections
  let documentation.Collection(
    name: course_name,
    entries: course_entries,
    metadata: course_metadata,
    ..,
  ) = course_collection
  identifier.collection_name_to_string(course_name)
  |> should.equal("courses")
  let assert [
    documentation.Entry(slug: biology_slug, endpoint: biology_endpoint),
  ] = course_entries
  identifier.slug_to_string(biology_slug)
  |> should.equal("biology")
  biology_endpoint
  |> should.equal("/api/course-site/collections/courses/biology")
  dict.get(course_metadata, "title")
  |> should.equal(
    Ok(documentation.Field(types: [documentation.StringType], present_in: 1)),
  )

  let documentation.Project(
    id: personal_id,
    collections: personal_collections,
    singletons: personal_singletons,
    ..,
  ) = personal_site
  identifier.project_id_to_string(personal_id)
  |> should.equal("personal-site")
  let assert [documentation.Collection(metadata: post_metadata, ..)] =
    personal_collections
  dict.get(post_metadata, "featured")
  |> should.equal(
    Ok(documentation.Field(types: [documentation.BoolType], present_in: 1)),
  )
  let assert [
    documentation.Singleton(
      name: homepage_name,
      endpoint: homepage_endpoint,
      metadata: homepage_metadata,
    ),
  ] = personal_singletons
  identifier.content_name_to_string(homepage_name)
  |> should.equal("homepage")
  homepage_endpoint
  |> should.equal("/api/personal-site/singletons/homepage")
  dict.get(homepage_metadata, "title")
  |> should.equal(
    Ok(documentation.Field(types: [documentation.StringType], present_in: 1)),
  )
}
