import gleam/float
import gleam/int
import gleam/result
import non_empty_list
import valid.{type Validator}

pub fn string_is_number(error: e) -> Validator(String, Float, e) {
  fn(value: String) {
    value
    |> float.parse
    |> result.try_recover(fn(_) {
      int.parse(value)
      |> result.map(int.to_float)
    })
    |> result.replace_error(non_empty_list.new(error, []))
  }
}

pub fn float_is_greater_than(x: Float, error: e) -> Validator(Float, Float, e) {
  fn(value: Float) {
    case value >. x {
      True -> Ok(value)
      _ -> Error(non_empty_list.new(error, []))
    }
  }
}

pub fn error_msg(param_name, problem) {
  "\"" <> param_name <> "\" " <> problem
}
