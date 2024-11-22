import decode/zero
import lustre/effect.{type Effect}
import lustre_http.{type HttpError}
import shared/coin_market_cap_types.{type CryptoCurrency, type FiatCurrency} as cmc_types

pub fn get_crypto(
  on_result_msg: fn(Result(List(CryptoCurrency), HttpError)) -> a,
) -> Effect(a) {
  let decoder = zero.run(_, zero.list(cmc_types.crypto_currency_decoder()))
  let expect = lustre_http.expect_json(decoder, on_result_msg)
  lustre_http.get(get_app_url() <> "/api/currencies/crypto", expect)
}

pub fn get_fiat(
  on_result_msg: fn(Result(List(FiatCurrency), HttpError)) -> a,
) -> Effect(a) {
  let decoder = zero.run(_, zero.list(cmc_types.fiat_currency_decoder()))
  let expect = lustre_http.expect_json(decoder, on_result_msg)
  lustre_http.get(get_app_url() <> "/api/currencies/fiat", expect)
}

@external(javascript, "./ffi.mjs", "get_app_url")
fn get_app_url() -> String
