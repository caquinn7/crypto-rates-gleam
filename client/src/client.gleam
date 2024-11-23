import client/api
import client/model.{type Model, CurrencyInput, Loaded, Loading, Model}
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

pub fn init(maybe_model) -> #(Model, Effect(Msg)) {
  case maybe_model {
    Some(model) -> #(model, effect.none())
    None -> #(
      Model(
        Loading,
        Loading,
        CurrencyInput(None, None),
        CurrencyInput(None, None),
      ),
      effect.batch([
        api.get_crypto(ApiReturnedCrypto),
        api.get_fiat(ApiReturnedFiat),
      ]),
    )
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    ApiReturnedCrypto(Ok(currencies)) -> #(
      Model(..model, crypto: Loaded(currencies)),
      effect.none(),
    )

    ApiReturnedCrypto(Error(_)) -> #(model, effect.none())

    ApiReturnedFiat(Ok(currencies)) -> #(
      Model(..model, fiat: Loaded(currencies)),
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
