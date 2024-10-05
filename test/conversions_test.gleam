import crypto_rates/coin_market_cap.{CmcResponse, Conversion, QuoteItem, Status}
import crypto_rates/routes/conversions.{ConversionParameters, validate_request}
import crypto_rates/validation_response.{ValidationError}
import gleam/dict
import gleam/float
import gleam/http/request
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import non_empty_list.{NonEmptyList}
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn conversions_validate_request_amount_param_missing_test() {
  test_validate_request([#("from", "1"), #("to", "2")])
  |> should.be_error
  |> should.equal(NonEmptyList(ValidationError("amount", "is required"), []))
}

pub fn conversions_validate_request_amount_param_not_a_number_test() {
  test_validate_request([#("amount", "x"), #("from", "1"), #("to", "2")])
  |> should.be_error
  |> should.equal(
    NonEmptyList(
      ValidationError(
        "amount",
        "must be either an integer or a floating-point number",
      ),
      [],
    ),
  )
}

pub fn conversions_validate_request_amount_param_less_than_min_test() {
  test_validate_request([
    #("amount", "0.00000001"),
    #("from", "1"),
    #("to", "2"),
  ])
  |> should.be_error
  |> should.equal(
    NonEmptyList(ValidationError("amount", "must be greater than 1.0e-8"), []),
  )
}

pub fn conversions_validate_request_from_param_missing_test() {
  test_validate_request([#("amount", "1.0"), #("to", "2")])
  |> should.be_error
  |> should.equal(NonEmptyList(ValidationError("from", "is required"), []))
}

pub fn conversions_validate_request_from_param_not_an_integer_test() {
  test_validate_request([#("amount", "1.0"), #("from", "x"), #("to", "2")])
  |> should.be_error
  |> should.equal(
    NonEmptyList(ValidationError("from", "must be an integer"), []),
  )
}

pub fn conversions_validate_request_from_param_is_zero_test() {
  test_validate_request([#("amount", "1.0"), #("from", "0"), #("to", "2")])
  |> should.be_error
  |> should.equal(
    NonEmptyList(ValidationError("from", "must be greater than 0"), []),
  )
}

pub fn conversions_validate_request_to_param_missing_test() {
  test_validate_request([#("amount", "1.0"), #("from", "1")])
  |> should.be_error
  |> should.equal(NonEmptyList(ValidationError("to", "is required"), []))
}

pub fn conversions_validate_request_to_param_not_an_integer_test() {
  test_validate_request([#("amount", "1.0"), #("from", "1"), #("to", "x")])
  |> should.be_error
  |> should.equal(NonEmptyList(ValidationError("to", "must be an integer"), []))
}

pub fn conversions_validate_request_to_param_is_zero_test() {
  test_validate_request([#("amount", "1.0"), #("from", "1"), #("to", "0")])
  |> should.be_error
  |> should.equal(
    NonEmptyList(ValidationError("to", "must be greater than 0"), []),
  )
}

pub fn conversions_validate_request_amount_is_integer_test() {
  test_validate_request([#("amount", "1"), #("from", "1"), #("to", "2")])
  |> should.be_ok
  |> should.equal(ConversionParameters(1.0, 1, 2))
}

pub fn conversions_validate_request_amount_is_float_test() {
  test_validate_request([#("amount", "1.0"), #("from", "1"), #("to", "2")])
  |> should.be_ok
  |> should.equal(ConversionParameters(1.0, 1, 2))
}

pub fn conversions_get_test() {
  let price = 60_000.01

  let do_get = fn(amount, id, convert_id) {
    let quote =
      dict.new()
      |> dict.insert(int.to_string(convert_id), QuoteItem(price))

    Conversion(id, "BTC", "Bitcoin", amount, quote)
    |> Some
    |> CmcResponse(Status(0, None), _)
    |> Ok
  }

  let conversion_params = ConversionParameters(1.0, 1, 2)
  let ConversionParameters(amount, from, to) = conversion_params

  let response =
    conversion_params
    |> conversions.get(do_get)

  response.status
  |> should.equal(200)

  let expected_json =
    "{\"from\":{\"id\":"
    <> int.to_string(from)
    <> ",\"amount\":"
    <> float.to_string(amount)
    <> "},\"to\":{\"id\":"
    <> int.to_string(to)
    <> ",\"amount\":"
    <> float.to_string(price)
    <> "}}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

fn test_validate_request(query_params) {
  testing.get("", [])
  |> request.set_query(query_params)
  |> validate_request
}
