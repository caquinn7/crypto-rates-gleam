import birdie
import crypto_rates/web.{set_default_response}
import gleam/string_builder
import gleeunit
import gleeunit/should
import wisp
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn web_set_default_response_body_not_empty_test() {
  let body = "abc"

  let handler = fn() {
    body
    |> string_builder.from_string
    |> wisp.json_response(400)
  }

  let response =
    testing.get("/endpoint", [])
    |> set_default_response(handler)

  response
  |> testing.string_body
  |> should.equal(body)
}

pub fn web_set_default_response_status_not_mapped_test() {
  let handler = fn() { wisp.response(418) }

  let response =
    testing.get("/endpoint", [])
    |> set_default_response(handler)

  response
  |> testing.string_body
  |> should.equal("")
}

pub fn web_set_default_response_status_is_500_test() {
  let handler = fn() { wisp.response(500) }

  let response =
    testing.get("/endpoint", [])
    |> set_default_response(handler)

  response
  |> testing.string_body
  |> birdie.snap("web_set_default_response_status_is_500_test")
}

pub fn web_set_default_response_status_is_not_500_test() {
  let handler = fn() { wisp.response(404) }

  let response =
    testing.get("/endpoint", [])
    |> set_default_response(handler)

  response
  |> testing.string_body
  |> birdie.snap("web_set_default_response_status_is_not_500_test")
}
