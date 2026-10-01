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
