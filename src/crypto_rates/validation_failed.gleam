import gleam/json.{type Json}
import non_empty_list.{type NonEmptyList}

pub type ValidationFailed =
  NonEmptyList(String)

pub fn from_error(err: String) -> ValidationFailed {
  err
  |> non_empty_list.new([])
}

pub fn encode(validation_failed: ValidationFailed) -> Json {
  let errs =
    validation_failed
    |> non_empty_list.to_list

  json.object([#("errors", json.array(errs, json.string))])
}
