import gleam/json.{type Json}
import non_empty_list.{type NonEmptyList}

pub type ValidationResponse {
  ValidationResponse(errors: NonEmptyList(ValidationError))
}

pub type ValidationError {
  ValidationError(param_name: String, message: String)
}

pub fn encode(validation_response: ValidationResponse) -> Json {
  let errs = validation_response.errors |> non_empty_list.to_list

  json.object([
    #(
      "errors",
      json.array(errs, fn(validation_error) {
        json.object([
          #("paramName", json.string(validation_error.param_name)),
          #("message", json.string(validation_error.message)),
        ])
      }),
    ),
  ])
}
