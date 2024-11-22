import client/model.{type Model, CurrencyInput, Model}
import decode/zero
import gleam/json
import gleam/option.{None, Some}
import gleam/result
import lustre
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre_http.{type HttpError}
import plinth/browser/document
import plinth/browser/element as browser_element
import shared/coin_market_cap_types.{
  type CryptoCurrency, type FiatCurrency, CryptoCurrency, FiatCurrency,
}

// A model produces some view.
// The view can produce messages in response to user interaction.
// Those messages are passed to the update function to produce a new model.
// … and the cycle continues.

pub type Msg {
  ApiReturnedCrypto(Result(List(CryptoCurrency), HttpError))
  ApiReturnedFiat(Result(List(FiatCurrency), HttpError))
}

pub fn main() {
  let app = lustre.application(init, update, view)
  let model = ssr_model() |> option.from_result
  let assert Ok(_) = lustre.start(app, "#app", model)
  Nil
}

pub fn init(model) -> #(Model, Effect(Msg)) {
  case model {
    Some(m) -> #(m, effect.none())
    None -> #(
      Model([], [], CurrencyInput(None, None), CurrencyInput(None, None)),
      effect.batch([get_crypto(), get_fiat()]),
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ApiReturnedCrypto(Ok(currencies)) -> #(
      Model(..model, crypto: currencies),
      effect.none(),
    )

    ApiReturnedCrypto(Error(_)) -> #(model, effect.none())

    ApiReturnedFiat(Ok(currencies)) -> #(
      Model(..model, fiat: currencies),
      effect.none(),
    )

    ApiReturnedFiat(Error(_)) -> #(model, effect.none())
  }
}

pub fn view(_model: Model) -> Element(Msg) {
  html.h1([], [element.text("Hello, worldz!")])
}

fn ssr_model() -> Result(Model, Nil) {
  use json_str <- result.try(
    document.query_selector("#model")
    |> result.map(browser_element.inner_text),
  )
  use model <- result.try(
    json.decode(json_str, zero.run(_, model.decoder()))
    |> result.replace_error(Nil),
  )
  Ok(model)
}

fn get_crypto() -> Effect(Msg) {
  let decoder = zero.run(_, zero.list(
    coin_market_cap_types.crypto_currency_decoder(),
  ))
  let expect = lustre_http.expect_json(decoder, ApiReturnedCrypto)
  lustre_http.get(get_app_url() <> "/api/currencies/crypto", expect)
}

fn get_fiat() -> Effect(Msg) {
  let decoder = zero.run(_, zero.list(
    coin_market_cap_types.fiat_currency_decoder(),
  ))
  let expect = lustre_http.expect_json(decoder, ApiReturnedFiat)
  lustre_http.get(get_app_url() <> "/api/currencies/fiat", expect)
}

@external(javascript, "./ffi.mjs", "get_app_url")
fn get_app_url() -> String
