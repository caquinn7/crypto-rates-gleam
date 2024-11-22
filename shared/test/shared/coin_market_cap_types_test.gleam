import birdie
import decode/zero
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency} as cmc_types

pub fn main() {
  gleeunit.main()
}

pub fn crypto_currency_encoder_test() {
  CryptoCurrency(1, Some(2), "CQ Token", "CQT")
  |> cmc_types.crypto_currency_encoder()
  |> json.to_string
  |> birdie.snap("crypto_currency_encoder_test")
}

pub fn crypto_currency_encoder_null_rank_test() {
  CryptoCurrency(1, None, "CQ Token", "CQT")
  |> cmc_types.crypto_currency_encoder()
  |> json.to_string
  |> birdie.snap("crypto_currency_encoder_null_rank_test")
}

pub fn crypto_currency_decoder_test() {
  let currency = CryptoCurrency(1, Some(2), "CQ Token", "CQT")

  currency
  |> cmc_types.crypto_currency_encoder()
  |> json.to_string
  |> json.decode(zero.run(_, cmc_types.crypto_currency_decoder()))
  |> should.be_ok
  |> should.equal(currency)
}

pub fn crypto_currency_decoder_null_rank_test() {
  let currency = CryptoCurrency(1, None, "CQ Token", "CQT")

  currency
  |> cmc_types.crypto_currency_encoder()
  |> json.to_string
  |> json.decode(zero.run(_, cmc_types.crypto_currency_decoder()))
  |> should.be_ok
  |> should.equal(currency)
}

pub fn fiat_currency_encoder_test() {
  FiatCurrency(2, "United States Dollar", "$", "USD")
  |> cmc_types.fiat_currency_encoder()
  |> json.to_string
  |> birdie.snap("fiat_currency_encoder_test")
}

pub fn fiat_currency_decoder_test() {
  let currency = FiatCurrency(2, "United States Dollar", "$", "USD")

  currency
  |> cmc_types.fiat_currency_encoder()
  |> json.to_string
  |> json.decode(zero.run(_, cmc_types.fiat_currency_decoder()))
  |> should.be_ok
  |> should.equal(currency)
}
