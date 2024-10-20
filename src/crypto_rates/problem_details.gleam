import gleam/json.{type Json}
import gleam/list
import gleam/option.{type Option, Some}
import non_empty_list.{type NonEmptyList}

pub opaque type ProblemDetails {
  Details(title: String, status: Int, detail: Option(String), instance: String)
  ValidationDetails(
    title: String,
    status: Int,
    detail: String,
    instance: String,
    errors: NonEmptyList(String),
  )
}

pub opaque type ProblemStatus {
  BadRequest
  NotFound
  MethodNotAllowed
  UnsupportedMediaType
  InternalServerError
}

pub fn new_problem_status(code: Int) -> Result(ProblemStatus, Nil) {
  case code {
    400 -> Ok(BadRequest)
    404 -> Ok(NotFound)
    405 -> Ok(MethodNotAllowed)
    415 -> Ok(UnsupportedMediaType)
    500 -> Ok(InternalServerError)
    _ -> Error(Nil)
  }
}

pub fn unwrap_problem_status(problem_status: ProblemStatus) -> #(Int, String) {
  case problem_status {
    BadRequest -> #(400, "Bad Request")
    NotFound -> #(404, "Not Found")
    MethodNotAllowed -> #(405, "Method Not Allowed")
    UnsupportedMediaType -> #(415, "Unsupported Media Type")
    InternalServerError -> #(500, "Internal Server Error")
  }
}

pub fn new_details(
  status: ProblemStatus,
  detail: Option(String),
  instance: String,
) -> ProblemDetails {
  let #(status_code, status_descr) = unwrap_problem_status(status)
  Details(status_descr, status_code, detail, instance)
}

pub fn new_validation_details(
  status: ProblemStatus,
  detail: String,
  instance: String,
  errors: NonEmptyList(String),
) -> ProblemDetails {
  let #(status_code, status_descr) = unwrap_problem_status(status)
  ValidationDetails(status_descr, status_code, detail, instance, errors)
}

pub fn get_status(problem_details: ProblemDetails) -> Int {
  problem_details.status
}

pub fn encode(problem_details: ProblemDetails) -> Json {
  let encode_common_fields = fn(title, status, detail, instance) {
    [
      #("title", json.string(title)),
      #("status", json.int(status)),
      #("detail", json.nullable(detail, json.string)),
      #("instance", json.string(instance)),
    ]
  }
  case problem_details {
    Details(title, status, detail, instance) ->
      json.object(encode_common_fields(title, status, detail, instance))

    ValidationDetails(title, status, detail, instance, errs) -> {
      let errs_array =
        errs
        |> non_empty_list.to_list
        |> json.array(json.string)

      json.object(
        list.append(
          encode_common_fields(title, status, Some(detail), instance),
          [#("errors", errs_array)],
        ),
      )
    }
  }
}
// HTTP/1.1 401 Unauthorized
// Content-Type: application/problem+json; charset=utf-8
// Date: Wed, 07 Aug 2019 10:10:06 GMT
// {
//     "type": "https://example.com/probs/cant-view-account-details",
//     "title": "Not authorized to view account details",
//     "status": 401,
//     "detail": "Due to privacy concerns you are not allowed to view account details of others. Only users with the role administrator are allowed to do this.",
//     "instance": "/account/123456/details"
// }

// When type is not provided (undefined) the consumers must assume that type equals about:blank.
// When type equals about:blank then title should equal the description of the HTTP status code
