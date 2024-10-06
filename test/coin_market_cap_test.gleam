import crypto_rates/coin_market_cap.{
  CmcListResponse, CmcResponse, Conversion, ConversionParameters, Status,
  get_conversion, get_crypto_currencies, get_fiat_currencies,
}
import dot_env
import dot_env/env
import gleam/dict
import gleam/int
import gleam/list
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn coin_market_cap_get_crypto_currencies_happy_path_test() {
  use <- load_env

  let assert Ok(api_key) = env.get_string("COIN_MARKET_CAP_API_KEY")
  let limit = 100

  let CmcListResponse(Status(error_code, error_message), data) =
    api_key
    |> get_crypto_currencies(limit)
    |> should.be_ok

  // there should be no error code or msg
  error_code |> should.equal(0)
  error_message |> should.be_none

  // number of items should not exceed the limit
  let currencies = data |> should.be_some
  currencies
  |> list.length
  |> fn(x) { x > 0 && x <= limit }
  |> should.be_true

  // items should be sorted ascending by rank
  currencies
  |> list.sort(fn(c1, c2) {
    // making the assumption that all active coins have a rank
    let rank1 = c1.rank |> should.be_some
    let rank2 = c2.rank |> should.be_some
    int.compare(rank1, rank2)
  })
  |> should.equal(currencies)
}

pub fn coin_market_cap_get_crypto_currencies_invalid_api_key_test() {
  let CmcListResponse(Status(error_code, error_message), data) =
    "invalid_api_key"
    |> get_crypto_currencies(100)
    |> should.be_ok

  { error_code > 0 } |> should.be_true
  error_message |> should.be_some
  data |> should.be_none
}

pub fn coin_market_cap_get_fiat_currencies_happy_path_test() {
  use <- load_env

  let assert Ok(api_key) = env.get_string("COIN_MARKET_CAP_API_KEY")
  let limit = 100

  let CmcListResponse(Status(error_code, error_message), data) =
    api_key
    |> get_fiat_currencies(limit)
    |> should.be_ok

  // there should be no error code or msg
  error_code |> should.equal(0)
  error_message |> should.be_none

  // number of items should not exceed the limit
  let currencies = data |> should.be_some
  currencies
  |> list.length
  |> fn(x) { x > 0 && x <= limit }
  |> should.be_true

  // items should be sorted ascending by rank
  currencies
  |> list.sort(fn(c1, c2) { int.compare(c1.id, c2.id) })
  |> should.equal(currencies)
}

pub fn coin_market_cap_get_conversion_happy_path_test() {
  use <- load_env

  let assert Ok(api_key) = env.get_string("COIN_MARKET_CAP_API_KEY")

  let #(from_amount, from_id, to_id) = #(1.5, 1, 2010)

  let CmcResponse(Status(error_code, error_message), data) =
    api_key
    |> get_conversion(ConversionParameters(from_amount, from_id, to_id))
    |> should.be_ok

  error_code |> should.equal(0)
  error_message |> should.be_none

  let conversion = data |> should.be_some
  let Conversion(id, _symbol, _name, amount, quote) = conversion

  id |> should.equal(from_id)
  amount |> should.equal(from_amount)

  quote
  |> dict.size
  |> should.equal(1)

  quote
  |> dict.get(int.to_string(to_id))
  |> should.be_ok
}

fn load_env(then: fn() -> a) {
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  then()
}
