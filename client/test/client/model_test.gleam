import birdie
import client/model.{CurrencyInput, Loaded, Model}
import decode/zero
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency}

pub fn main() {
  gleeunit.main()
}

pub fn currency_input_encoder_test() {
  CurrencyInput(Some(1), Some(1.5))
  |> model.currency_input_encoder()
  |> json.to_string
  |> birdie.snap("model_currency_input_encoder_test")
}

pub fn currency_input_encoder_nulls_test() {
  CurrencyInput(None, None)
  |> model.currency_input_encoder()
  |> json.to_string
  |> birdie.snap("currency_input_encoder_nulls_test")
}

pub fn currency_input_decoder_test() {
  let currency_input = CurrencyInput(Some(1), Some(1.5))
  currency_input
  |> model.currency_input_encoder()
  |> json.to_string
  |> json.decode(zero.run(_, model.currency_input_decoder()))
  |> should.be_ok
  |> should.equal(currency_input)
}

pub fn currency_input_decoder_nulls_test() {
  let currency_input = CurrencyInput(None, None)

  currency_input
  |> model.currency_input_encoder()
  |> json.to_string
  |> json.decode(zero.run(_, model.currency_input_decoder()))
  |> should.be_ok
  |> should.equal(currency_input)
}

pub fn model_encoder_test() {
  let crypto = [CryptoCurrency(1, Some(2), "CQ Token", "CQT")]
  let fiat = [FiatCurrency(2, "United States Dollar", "$", "USD")]
  Model(
    Loaded(crypto),
    Loaded(fiat),
    CurrencyInput(Some(1), Some(1.5)),
    CurrencyInput(Some(2), Some(2.5)),
  )
  |> model.encoder()
  |> json.to_string
  |> birdie.snap("model_encoder_test")
}

pub fn model_decoder_test() {
  let crypto = [CryptoCurrency(1, Some(2), "CQ Token", "CQT")]
  let fiat = [FiatCurrency(2, "United States Dollar", "$", "USD")]
  let model =
    Model(
      Loaded(crypto),
      Loaded(fiat),
      CurrencyInput(Some(1), Some(1.5)),
      CurrencyInput(Some(2), Some(2.5)),
    )

  model
  |> model.encoder()
  |> json.to_string
  |> json.decode(zero.run(_, model.decoder()))
  |> should.be_ok
  |> should.equal(model)
}
