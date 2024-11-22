import birdie
import gleam/dict
import gleam/http/request
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import non_empty_list.{NonEmptyList}
import server/coin_market_cap.{
  CmcResponse, Conversion, ConversionParameters, QuoteItem, Status,
}
import server/routes/conversions.{ConversionResponse, Currency, CurrencyNotFound}
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn conversions_validate_request_amount_param_missing_test() {
  test_validate_request([#("from", "1"), #("to", "2")])
  |> should.be_error
  |> should.equal(NonEmptyList("\"amount\" is required", []))
}

pub fn conversions_validate_request_amount_param_not_a_number_test() {
  test_validate_request([#("amount", "x"), #("from", "1"), #("to", "2")])
  |> should.be_error
  |> should.equal(
    NonEmptyList(
      "\"amount\" must be either an integer or a floating-point number",
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
  |> should.equal(NonEmptyList("\"amount\" must be greater than 1.0e-8", []))
}

pub fn conversions_validate_request_from_param_missing_test() {
  test_validate_request([#("amount", "1.0"), #("to", "2")])
  |> should.be_error
  |> should.equal(NonEmptyList("\"from\" is required", []))
}

pub fn conversions_validate_request_from_param_not_an_integer_test() {
  test_validate_request([#("amount", "1.0"), #("from", "x"), #("to", "2")])
  |> should.be_error
  |> should.equal(NonEmptyList("\"from\" must be an integer", []))
}

pub fn conversions_validate_request_from_param_is_zero_test() {
  test_validate_request([#("amount", "1.0"), #("from", "0"), #("to", "2")])
  |> should.be_error
  |> should.equal(NonEmptyList("\"from\" must be greater than 0", []))
}

pub fn conversions_validate_request_to_param_missing_test() {
  test_validate_request([#("amount", "1.0"), #("from", "1")])
  |> should.be_error
  |> should.equal(NonEmptyList("\"to\" is required", []))
}

pub fn conversions_validate_request_to_param_not_an_integer_test() {
  test_validate_request([#("amount", "1.0"), #("from", "1"), #("to", "x")])
  |> should.be_error
  |> should.equal(NonEmptyList("\"to\" must be an integer", []))
}

pub fn conversions_validate_request_to_param_is_zero_test() {
  test_validate_request([#("amount", "1.0"), #("from", "1"), #("to", "0")])
  |> should.be_error
  |> should.equal(NonEmptyList("\"to\" must be greater than 0", []))
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

pub fn conversions_map_cmc_response_invalid_id_test() {
  let id = 1

  ConversionParameters(1.0, id, 2)
  |> conversions.map_cmc_response(
    Status(
      400,
      Some("Invalid value for \"id\": \"" <> int.to_string(id) <> "\""),
    ),
    None,
  )
  |> should.be_error
  |> should.equal(CurrencyNotFound(id))
}

pub fn conversions_map_cmc_response_invalid_convert_id_test() {
  let convert_id = 2

  ConversionParameters(1.0, 1, convert_id)
  |> conversions.map_cmc_response(
    Status(
      400,
      Some(
        "Invalid value for \"convert_id\": \""
        <> int.to_string(convert_id)
        <> "\"",
      ),
    ),
    None,
  )
  |> should.be_error
  |> should.equal(CurrencyNotFound(convert_id))
}

pub fn conversions_map_cmc_response_status_is_zero_test() {
  let conversion_params = ConversionParameters(1.0, 1, 2)
  let ConversionParameters(amount, id, convert_id) = conversion_params

  let price = 60_000.01
  let quote =
    dict.new()
    |> dict.insert(int.to_string(convert_id), QuoteItem(price))

  let conversion = Conversion(id, "BTC", "Bitcoin", amount, quote)

  conversion_params
  |> conversions.map_cmc_response(Status(0, None), Some(conversion))
  |> should.be_ok
  |> should.equal(ConversionResponse(
    Currency(id, amount),
    Currency(convert_id, price),
  ))
}

pub fn conversions_get_invalid_currency_id_test() {
  let request_conversion = fn(params) {
    let ConversionParameters(_, id, _) = params

    Status(
      400,
      Some("Invalid value for \"id\": \"" <> int.to_string(id) <> "\""),
    )
    |> CmcResponse(None)
    |> Ok
  }

  let response =
    testing.get("/conversions", [])
    |> request.set_query([#("amount", "1.0"), #("from", "1"), #("to", "2")])
    |> conversions.get(request_conversion)

  response.status
  |> should.equal(400)

  response
  |> testing.string_body
  |> birdie.snap("conversions_get_invalid_currency_id_test")
}

pub fn conversions_get_happy_path_test() {
  let request_conversion = fn(params) {
    let ConversionParameters(amount, id, convert_id) = params

    let quote =
      dict.new()
      |> dict.insert(int.to_string(convert_id), QuoteItem(60_000.01))

    Conversion(id, "BTC", "Bitcoin", amount, quote)
    |> Some
    |> CmcResponse(Status(0, None), _)
    |> Ok
  }

  let response =
    testing.get("", [])
    |> request.set_query([#("amount", "1.0"), #("from", "1"), #("to", "2")])
    |> conversions.get(request_conversion)

  response.status
  |> should.equal(200)

  response
  |> testing.string_body
  |> birdie.snap("conversions_get_happy_path_test")
}

fn test_validate_request(query_params) {
  testing.get("", [])
  |> request.set_query(query_params)
  |> conversions.validate_request
}
