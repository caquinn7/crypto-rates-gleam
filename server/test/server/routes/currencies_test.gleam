import birdie
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import server/coin_market_cap.{CmcListResponse, Status}
import server/routes/currencies.{get_crypto, get_fiat}
import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency}
import wisp/testing

pub fn main() {
  gleeunit.main()
}

// get_crypto

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

pub fn currencies_get_crypto_limit_not_an_integer_test() {
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
  |> birdie.snap("currencies_get_crypto_limit_not_an_integer_test")
}

pub fn currencies_get_crypto_limit_less_than_one_test() {
  let request_crypto = fn(_) {
    CmcListResponse(Status(0, None), Some([]))
    |> Ok
  }

  let response =
    testing.get("/currencies/crypto?limit=0", [])
    |> get_crypto(request_crypto)

  response.status
  |> should.equal(400)

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_crypto_limit_less_than_one_test")
}

// get_fiat

pub fn currencies_get_fiat_test() {
  let request_fiat = fn(_limit) {
    [
      FiatCurrency(1, "United States Dollar", "$", "USD"),
      FiatCurrency(2, "Pound Sterling", "£", "GBP"),
    ]
    |> Some
    |> CmcListResponse(Status(0, None), _)
    |> Ok
  }

  let response =
    testing.get("/currencies/fiat", [])
    |> get_fiat(request_fiat)

  response.status
  |> should.equal(200)

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_fiat_test")
}

pub fn currencies_get_fiat_with_limit_test() {
  let request_fiat = fn(limit) {
    [
      FiatCurrency(1, "United States Dollar", "$", "USD"),
      FiatCurrency(2, "Pound Sterling", "£", "GBP"),
    ]
    |> list.take(limit)
    |> Some
    |> CmcListResponse(Status(0, None), _)
    |> Ok
  }

  let response =
    testing.get("/currencies/fiat?limit=1", [])
    |> get_fiat(request_fiat)

  response.status
  |> should.equal(200)

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_fiat_with_limit_test")
}

pub fn currencies_get_fiat_limit_not_an_integer_test() {
  let request_fiat = fn(_) {
    CmcListResponse(Status(0, None), Some([]))
    |> Ok
  }

  let response =
    testing.get("/currencies/fiat?limit=abc", [])
    |> get_fiat(request_fiat)

  response.status
  |> should.equal(400)

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_fiat_limit_not_an_integer_test")
}

pub fn currencies_get_fiat_limit_less_than_one_test() {
  let request_fiat = fn(_) {
    CmcListResponse(Status(0, None), Some([]))
    |> Ok
  }

  let response =
    testing.get("/currencies/fiat?limit=0", [])
    |> get_fiat(request_fiat)

  response.status
  |> should.equal(400)

  response
  |> testing.string_body
  |> birdie.snap("currencies_get_fiat_limit_less_than_one_test")
}
