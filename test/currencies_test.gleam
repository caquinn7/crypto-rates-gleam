import crypto_rates/coin_market_cap.{
  CmcListResponse, CryptoCurrency, FiatCurrency, Status,
}
import crypto_rates/routes/currencies.{get_crypto, get_fiat}
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn currencies_get_crypto_test() {
  let request_crypto = fn(_limit) {
    [
      CryptoCurrency(1, Some(1), "Bitcoin", "BTC"),
      CryptoCurrency(2, None, "XCoin", "XXX"),
    ]
    |> Some
    |> CmcListResponse(Status(0, None), _)
    |> Ok
  }

  let response =
    request_crypto
    |> get_crypto

  response.status
  |> should.equal(200)

  let expected_json =
    "[{\"id\":1,\"rank\":1,\"name\":\"Bitcoin\",\"symbol\":\"BTC\"},{\"id\":2,\"rank\":null,\"name\":\"XCoin\",\"symbol\":\"XXX\"}]"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}

pub fn currencies_get_fiat_test() {
  let request_fiat = fn(_limit) {
    [FiatCurrency(1, "United States Dollar", "$", "USD")]
    |> Some
    |> CmcListResponse(Status(0, None), _)
    |> Ok
  }

  let response =
    request_fiat
    |> get_fiat

  response.status
  |> should.equal(200)

  let expected_json =
    "[{\"id\":1,\"name\":\"United States Dollar\",\"sign\":\"$\",\"symbol\":\"USD\"}]"

  response
  |> testing.string_body
  |> should.equal(expected_json)
}
