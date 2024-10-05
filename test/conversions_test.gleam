import crypto_rates/coin_market_cap.{CmcResponse, Conversion, QuoteItem, Status}
import crypto_rates/routes/conversions
import gleam/dict
import gleam/float
import gleam/http/request
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn conversions_get_amount_param_missing_test() {
  let response =
    testing.get("", [])
    |> request.set_query([#("from", "1"), #("to", "2")])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"amount\",\"message\":\"is required\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn conversions_get_amount_param_not_a_number_test() {
  let response =
    testing.get("", [])
    |> request.set_query([#("amount", "x"), #("from", "1"), #("to", "2")])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"amount\",\"message\":\"must be either an integer or a floating-point number\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn conversions_get_amount_param_less_than_min_test() {
  let response =
    testing.get("", [])
    |> request.set_query([
      #("amount", "0.00000001"),
      #("from", "1"),
      #("to", "2"),
    ])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"amount\",\"message\":\"must be greater than 1.0e-8\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn conversions_get_from_param_missing_test() {
  let response =
    testing.get("", [])
    |> request.set_query([#("amount", "1.0"), #("to", "2")])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"from\",\"message\":\"is required\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn conversions_get_from_param_not_an_integer_test() {
  let response =
    testing.get("", [])
    |> request.set_query([#("amount", "1.0"), #("from", "x"), #("to", "2")])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"from\",\"message\":\"must be an integer\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn conversions_get_from_param_less_than_zero_test() {
  let response =
    testing.get("", [])
    |> request.set_query([#("amount", "1.0"), #("from", "0"), #("to", "2")])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"from\",\"message\":\"must be greater than 0\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn conversions_get_to_param_missing_test() {
  let response =
    testing.get("", [])
    |> request.set_query([#("amount", "1.0"), #("from", "1")])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"to\",\"message\":\"is required\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn conversions_get_to_param_not_an_integer_test() {
  let response =
    testing.get("", [])
    |> request.set_query([#("amount", "1.0"), #("from", "1"), #("to", "x")])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"to\",\"message\":\"must be an integer\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn conversions_get_to_param_less_than_zero_test() {
  let response =
    testing.get("", [])
    |> request.set_query([#("amount", "1.0"), #("from", "1"), #("to", "0")])
    |> conversions.get(fn(_, _, _) { Error(Nil) })

  response.status
  |> should.equal(400)

  let expected_json =
    "{\"errors\":[{\"paramName\":\"to\",\"message\":\"must be greater than 0\"}]}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
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

  let #(amount, from, to) = #(1.0, 1, 2)

  let response =
    testing.get("", [])
    |> request.set_query([
      #("amount", float.to_string(amount)),
      #("from", int.to_string(from)),
      #("to", int.to_string(to)),
    ])
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

pub fn conversions_get_amount_is_integer_test() {
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

  let #(amount, from, to) = #(1, 1, 2)

  let response =
    testing.get("", [])
    |> request.set_query([
      #("amount", int.to_string(amount)),
      #("from", int.to_string(from)),
      #("to", int.to_string(to)),
    ])
    |> conversions.get(do_get)

  response.status
  |> should.equal(200)

  let expected_json =
    "{\"from\":{\"id\":"
    <> int.to_string(from)
    <> ",\"amount\":"
    <> amount |> int.to_float |> float.to_string
    <> "},\"to\":{\"id\":"
    <> int.to_string(to)
    <> ",\"amount\":"
    <> float.to_string(price)
    <> "}}"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}
