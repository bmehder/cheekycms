import cheekycms/asset
import gleam/list
import gleeunit/should

pub fn resolves_nested_asset_paths_test() {
  asset.resolve("/assets/studio/images/orbit.webp", "assets")
  |> should.equal(
    Ok(asset.Asset(
      path: "assets/studio/images/orbit.webp",
      content_type: "image/webp",
      download: False,
    )),
  )
}

pub fn decodes_safe_asset_names_test() {
  asset.resolve("/assets/documents/field%20notes.pdf", "public")
  |> should.equal(
    Ok(asset.Asset(
      path: "public/documents/field notes.pdf",
      content_type: "application/pdf",
      download: False,
    )),
  )
}

pub fn rejects_path_traversal_and_hidden_files_test() {
  [
    "/assets/../secrets.txt",
    "/assets/%2e%2e/secrets.txt",
    "/assets/.env",
    "/assets/folder%5csecret.txt",
    "/assets/",
  ]
  |> list.each(fn(path) {
    asset.resolve(path, "assets")
    |> should.equal(Error(asset.InvalidPath))
  })
}

pub fn assigns_types_and_downloads_risky_formats_test() {
  asset.content_type("photo.AVIF") |> should.equal("image/avif")
  asset.content_type("recording.mp3") |> should.equal("audio/mpeg")
  asset.content_type("unknown.bin")
  |> should.equal("application/octet-stream")
  asset.must_download("page.html") |> should.be_true
  asset.must_download("drawing.svg") |> should.be_true
  asset.must_download("guide.pdf") |> should.be_false
}

pub fn ignores_non_asset_routes_test() {
  asset.resolve("/api/studio", "assets")
  |> should.equal(Error(asset.NotAssetRoute))
}

pub fn parses_byte_ranges_test() {
  asset.parse_range("bytes=100-199", 1000)
  |> should.equal(Ok(asset.ByteRange(offset: 100, length: 100)))
  asset.parse_range("bytes=900-", 1000)
  |> should.equal(Ok(asset.ByteRange(offset: 900, length: 100)))
  asset.parse_range("bytes=-50", 1000)
  |> should.equal(Ok(asset.ByteRange(offset: 950, length: 50)))
  asset.parse_range("bytes=900-2000", 1000)
  |> should.equal(Ok(asset.ByteRange(offset: 900, length: 100)))
}

pub fn rejects_invalid_or_unsatisfiable_ranges_test() {
  asset.parse_range("items=0-1", 1000)
  |> should.equal(Error(asset.InvalidRange))
  asset.parse_range("bytes=0-1,4-5", 1000)
  |> should.equal(Error(asset.InvalidRange))
  asset.parse_range("bytes=1000-", 1000)
  |> should.equal(Error(asset.UnsatisfiableRange))
}
