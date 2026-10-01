import cheekycms/identifier
import gleeunit/should

pub fn identifiers_are_trimmed_test() {
  let assert Ok(slug) = identifier.slug("hello-world")

  identifier.slug("  hello-world  ")
  |> should.equal(Ok(slug))
}

pub fn empty_identifiers_are_rejected_test() {
  identifier.project_id(" \n\t")
  |> should.equal(Error(identifier.EmptyIdentifier))
}

pub fn path_segments_are_rejected_test() {
  identifier.slug("nested/entry")
  |> should.equal(Error(identifier.PathSeparatorNotAllowed))
  identifier.project_id("..")
  |> should.equal(Error(identifier.ReservedPathSegment))
}
