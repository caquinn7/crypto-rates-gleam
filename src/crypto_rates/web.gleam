import crypto_rates/problem_details
import crypto_rates/response_utils
import gleam/bool
import gleam/option.{None, Some}
import gleam/result
import wisp.{type Request, type Response}

pub type Context {
  Context(cmc_api_key: String)
}

pub fn middleware(
  req: Request,
  handle_request: fn(Request) -> Response,
) -> Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- set_default_response(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  handle_request(req)
}

pub fn set_default_response(req: Request, handler: fn() -> Response) -> Response {
  let res = handler()
  use <- bool.guard(when: res.body != wisp.Empty, return: res)

  res.status
  |> problem_details.new_problem_status
  |> result.map_error(fn(_) { res })
  |> result.map(fn(problem_status) {
    let detail = case res.status {
      500 -> Some("An error occurred while processing your request.")
      _ -> None
    }

    problem_status
    |> problem_details.new_details(detail, req)
    |> response_utils.problem_details_response
  })
  |> result.unwrap_both
}
