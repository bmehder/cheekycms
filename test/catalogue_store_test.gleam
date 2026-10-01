import cheekycms/catalogue
import cheekycms/catalogue_store
import cheekycms/discovery
import gleam/erlang/process
import gleam/option
import gleeunit/should
import simplifile

const root = "/tmp/cheekycms-catalogue-store-test"

const page = "/tmp/cheekycms-catalogue-store-test/site/singletons/home.md"

const second_page = "/tmp/cheekycms-catalogue-store-test/site/singletons/contact.md"

pub fn keeps_the_last_working_catalogue_after_a_failed_reload_test() {
  let assert Ok(Nil) = simplifile.delete_all([root])
  let assert Ok(Nil) =
    simplifile.create_directory_all(root <> "/site/singletons")
  let assert Ok(Nil) =
    simplifile.write(page, "---\ntitle: Home\n---\n# Working\n")
  let assert Ok(initial) = discovery.discover(root)
  let assert Ok(store) = catalogue_store.start(initial, root)

  let assert Ok(Nil) =
    simplifile.write(page, "---\ntags: [one, two\n---\n# Invalid\n")
  catalogue_store.reload(store)
  process.sleep(50)

  let catalogue_store.Snapshot(catalogue: retained, status: failed_status) =
    catalogue_store.snapshot(store)
  catalogue.size(retained)
  |> should.equal(1)
  let catalogue_store.Status(
    successful_reloads: failed_reloads,
    last_error: failed_error,
    ..,
  ) = failed_status
  failed_reloads
  |> should.equal(0)
  option.is_some(failed_error)
  |> should.be_true

  let assert Ok(Nil) =
    simplifile.write(page, "---\ntitle: Home\n---\n# Fixed\n")
  let assert Ok(Nil) =
    simplifile.write(second_page, "---\ntitle: Contact\n---\n# Contact\n")
  catalogue_store.reload(store)
  process.sleep(50)

  let catalogue_store.Snapshot(catalogue: updated, status: updated_status) =
    catalogue_store.snapshot(store)
  catalogue.size(updated)
  |> should.equal(2)
  let catalogue_store.Status(
    successful_reloads: successful_reloads,
    last_error: updated_error,
    ..,
  ) = updated_status
  successful_reloads
  |> should.equal(1)
  updated_error
  |> should.equal(option.None)

  let assert Ok(Nil) = simplifile.delete_all([root])
}
