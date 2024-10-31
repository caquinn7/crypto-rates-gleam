import crypto_rates/problem_details.{type ProblemDetails}
import gleam/json.{type Json}
import non_empty_list.{type NonEmptyList}
import wisp.{type Request, type Response}

pub fn json_response(json: Json, status: Int) -> Response {
  json
  |> json.to_string_builder
  |> wisp.json_response(status)
}

pub fn bad_request_response(req: Request, errs: NonEmptyList(String)) {
  let assert Ok(status) = problem_details.new_problem_status(400)
  status
  |> problem_details.new_validation_details(req, errs)
  |> problem_details_response
}

pub fn problem_details_response(problem_details: ProblemDetails) -> Response {
  problem_details
  |> problem_details.encode
  |> json_response(problem_details.get_status(problem_details))
  |> wisp.set_header("content-type", "application/problem+json; charset=utf-8")
}
