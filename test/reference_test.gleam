import cheekycms/asset
import cheekycms/reference
import gleeunit/should

pub fn index_route_test() {
  reference.resolve("/reference/", "reference")
  |> should.equal(
    Ok(asset.Asset("reference/index.html", "text/html; charset=utf-8", False)),
  )
}

pub fn nested_asset_route_test() {
  reference.resolve("/reference/css/index.css", "reference")
  |> should.equal(
    Ok(asset.Asset("reference/css/index.css", "text/css; charset=utf-8", False)),
  )
}

pub fn traversal_is_rejected_test() {
  reference.resolve("/reference/%2e%2e/secret", "reference")
  |> should.equal(Error(reference.InvalidPath))
}

pub fn unrelated_route_test() {
  reference.resolve("/api", "reference")
  |> should.equal(Error(reference.NotReferenceRoute))
}
