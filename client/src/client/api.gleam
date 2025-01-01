import decode/zero
import gleam/float
import gleam/int
import lustre/effect.{type Effect}
import lustre_http.{type HttpError}
import shared/coin_market_cap_types.{
  type ConversionParameters, type CryptoCurrency, type FiatCurrency,
  ConversionParameters,
} as cmc_types
import shared/conversion_response.{type ConversionResponse}

pub fn get_crypto(
  on_result_msg: fn(Result(List(CryptoCurrency), HttpError)) -> msg,
) -> Effect(msg) {
  let decoder = zero.run(_, zero.list(cmc_types.crypto_currency_decoder()))
  let expect = lustre_http.expect_json(decoder, on_result_msg)
  lustre_http.get(get_app_url() <> "/api/currencies/crypto", expect)
}

pub fn get_fiat(
  on_result_msg: fn(Result(List(FiatCurrency), HttpError)) -> msg,
) -> Effect(msg) {
  let decoder = zero.run(_, zero.list(cmc_types.fiat_currency_decoder()))
  let expect = lustre_http.expect_json(decoder, on_result_msg)
  lustre_http.get(get_app_url() <> "/api/currencies/fiat", expect)
}

pub fn get_conversion(
  conversion_params: ConversionParameters,
  on_result_msg: fn(Result(ConversionResponse, HttpError)) -> msg,
) -> Effect(msg) {
  let ConversionParameters(amount, from, to) = conversion_params

  let decoder = zero.run(_, conversion_response.decoder())
  let expect = lustre_http.expect_json(decoder, on_result_msg)
  let path =
    "/api/conversions?amount="
    <> float.to_string(amount)
    <> "&from="
    <> int.to_string(from)
    <> "&to="
    <> int.to_string(to)
  lustre_http.get(get_app_url() <> path, expect)
}

@external(javascript, "../window_ffi.mjs", "get_app_url")
fn get_app_url() -> String
