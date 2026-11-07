//// The demonstration marketing website hosted alongside CheekyCMS.
////
//// Owns the website's routes and connects them to its page responses. It consumes
//// the CMS catalogue but is not part of the content API. Keeping this connection
//// here makes the website-specific choices visible outside the CMS modules.

import cheekycms/content/catalogue
import gleam/http
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import marketing/pages

/// Handle the website's GET routes, or leave the request to the CMS server.
pub fn handle(
  request: Request(body),
  catalogue: catalogue.Catalogue,
) -> Result(Response(String), Nil) {
  case request.method, request.path {
    http.Get, "/" -> Ok(pages.homepage(catalogue))
    http.Get, "/favicon.svg" -> Ok(pages.favicon())
    _, _ -> Error(Nil)
  }
}
