import crypto_rates/web
import gleam/string_builder
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> {
      wisp.html_response(string_builder.from_string("Home"), 200)
    }
    _ -> wisp.not_found()
  }
}
