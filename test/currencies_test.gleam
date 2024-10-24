import birdie
import crypto_rates/coin_market_cap.{
  CmcListResponse, CryptoCurrency, FiatCurrency, Status,
}
import crypto_rates/routes/currencies.{get_crypto, get_fiat}
import gleam/list
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
    testing.get("", [])
    |> get_crypto(request_crypto)

  response.status
  |> should.equal(200)

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_crypto_test")
}

pub fn currencies_get_crypto_with_limit_test() {
  let request_crypto = fn(limit) {
    [
      CryptoCurrency(1, Some(1), "Bitcoin", "BTC"),
      CryptoCurrency(2, None, "XCoin", "XXX"),
    ]
    |> list.take(limit)
    |> Some
    |> CmcListResponse(Status(0, None), _)
    |> Ok
  }

  let response =
    testing.get("/currencies/crypto?limit=1", [])
    |> get_crypto(request_crypto)

  response.status
  |> should.equal(200)

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_crypto_with_limit_test")
}

pub fn currencies_get_crypto_invalid_limit_test() {
  let request_crypto = fn(_) {
    CmcListResponse(Status(0, None), Some([]))
    |> Ok
  }

  let response =
    testing.get("/currencies/crypto?limit=abc", [])
    |> get_crypto(request_crypto)

  response.status
  |> should.equal(400)

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_crypto_invalid_limit_test")
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

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_fiat_test")
}
