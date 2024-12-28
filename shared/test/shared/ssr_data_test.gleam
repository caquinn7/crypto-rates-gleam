import birdie
import decode/zero
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import shared/coin_market_cap_types as cmc_types
import shared/ssr_data.{Currency, SsrData}

pub fn main() {
  gleeunit.main()
}

pub fn ssr_data_encoder_test() {
  SsrData(
    [cmc_types.CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
    [cmc_types.FiatCurrency(2, "United States Dollar", "$", "USD")],
    #(Currency(None, Some(1)), Currency(Some(1.1), None)),
  )
  |> ssr_data.encoder()
  |> json.to_string
  |> birdie.snap("ssr_data_encoder_test")
}

pub fn ssr_data_decoder_test() {
  let ssr_data =
    SsrData(
      [cmc_types.CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [cmc_types.FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(None, Some(1)), Currency(Some(1.1), None)),
    )

  ssr_data
  |> ssr_data.encoder()
  |> json.to_string
  |> json.decode(zero.run(_, ssr_data.decoder()))
  |> should.be_ok
  |> should.equal(ssr_data)
}
