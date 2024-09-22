import crypto_rates/coin_market_cap.{
  CmcResponse, CryptoCurrency, Status, get_crypto,
}
import dot_env
import dot_env/env
import gleam/list
import gleeunit
import gleeunit/should

pub fn main() {
  gleeunit.main()
}

pub fn coin_market_cap_get_crypto_happy_path_test() {
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(False)
  |> dot_env.load

  let assert Ok(api_key) = env.get_string("COIN_MARKET_CAP_API_KEY")

  let CmcResponse(Status(error_code, error_message), data) =
    api_key
    |> get_crypto
    |> should.be_ok

  error_code |> should.equal(0)
  error_message |> should.be_none

  let crypto = data |> should.be_some
  crypto
  |> list.length
  |> should.equal(100)

  let assert Ok(CryptoCurrency(_id, rank, _name, _symbol)) = list.first(crypto)

  rank
  |> should.be_some
  |> should.equal(1)
}

pub fn coin_market_cap_get_crypto_invalid_api_key_test() {
  let CmcResponse(Status(error_code, error_message), data) =
    "invalid_api_key"
    |> get_crypto
    |> should.be_ok

  { error_code > 0 } |> should.be_true
  error_message |> should.be_some
  data |> should.be_none
}
