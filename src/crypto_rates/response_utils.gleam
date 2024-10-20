import crypto_rates/problem_details.{type ProblemDetails}
import gleam/json.{type Json}
import wisp.{type Response}

pub fn json_response(json: Json, status: Int) -> Response {
  json
  |> json.to_string_builder
  |> wisp.json_response(status)
}

pub fn problem_details_response(problem_details: ProblemDetails) -> Response {
  problem_details
  |> problem_details.encode
  |> json_response(problem_details.status)
  |> wisp.set_header("content-type", "application/problem+json; charset=utf-8")
}
