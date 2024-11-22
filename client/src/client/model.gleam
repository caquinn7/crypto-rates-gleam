import decode/zero.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option}
import shared/coin_market_cap_types.{
  type CryptoCurrency, type FiatCurrency, CryptoCurrency, FiatCurrency,
} as cmc_types

pub type Model {
  Model(
    crypto: List(CryptoCurrency),
    fiat: List(FiatCurrency),
    currency_input1: CurrencyInput,
    currency_input2: CurrencyInput,
  )
}

pub type CurrencyInput {
  CurrencyInput(id: Option(Int), amount: Option(Float))
}

pub fn decoder() -> Decoder(Model) {
  use crypto <- zero.field(
    "crypto",
    zero.list(cmc_types.crypto_currency_decoder()),
  )
  use fiat <- zero.field("fiat", zero.list(cmc_types.fiat_currency_decoder()))
  use currency_input1 <- zero.field("currency_input1", currency_input_decoder())
  use currency_input2 <- zero.field("currency_input2", currency_input_decoder())
  zero.success(Model(crypto, fiat, currency_input1, currency_input2))
}

pub fn currency_input_decoder() -> Decoder(CurrencyInput) {
  use id <- zero.field("id", zero.optional(zero.int))
  use amount <- zero.field("amount", zero.optional(zero.float))
  zero.success(CurrencyInput(id, amount))
}

pub fn encoder() -> fn(Model) -> Json {
  fn(model: Model) {
    json.object([
      #("crypto", json.array(model.crypto, cmc_types.crypto_currency_encoder())),
      #("fiat", json.array(model.fiat, cmc_types.fiat_currency_encoder())),
      #("currency_input1", model.currency_input1 |> currency_input_encoder()),
      #("currency_input2", model.currency_input2 |> currency_input_encoder()),
    ])
  }
}

pub fn currency_input_encoder() -> fn(CurrencyInput) -> Json {
  fn(currency_input: CurrencyInput) {
    json.object([
      #("id", json.nullable(currency_input.id, json.int)),
      #("amount", json.nullable(currency_input.amount, json.float)),
    ])
  }
}
