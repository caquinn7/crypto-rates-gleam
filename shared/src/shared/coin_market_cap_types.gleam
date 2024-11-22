import decode/zero.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None}

pub type CryptoCurrency {
  CryptoCurrency(id: Int, rank: Option(Int), name: String, symbol: String)
}

pub type FiatCurrency {
  FiatCurrency(id: Int, name: String, sign: String, symbol: String)
}

pub fn crypto_currency_decoder() -> Decoder(CryptoCurrency) {
  use id <- zero.field("id", zero.int)
  use rank <- zero.optional_field("rank", None, zero.optional(zero.int))
  use name <- zero.field("name", zero.string)
  use symbol <- zero.field("symbol", zero.string)
  zero.success(CryptoCurrency(id, rank, name, symbol))
}

pub fn crypto_currency_encoder() -> fn(CryptoCurrency) -> Json {
  fn(currency: CryptoCurrency) {
    json.object([
      #("id", json.int(currency.id)),
      #("rank", json.nullable(currency.rank, json.int)),
      #("name", json.string(currency.name)),
      #("symbol", json.string(currency.symbol)),
    ])
  }
}

pub fn fiat_currency_decoder() -> Decoder(FiatCurrency) {
  use id <- zero.field("id", zero.int)
  use name <- zero.field("name", zero.string)
  use sign <- zero.field("sign", zero.string)
  use symbol <- zero.field("symbol", zero.string)
  zero.success(FiatCurrency(id, name, sign, symbol))
}

pub fn fiat_currency_encoder() -> fn(FiatCurrency) -> Json {
  fn(currency: FiatCurrency) {
    json.object([
      #("id", json.int(currency.id)),
      #("name", json.string(currency.name)),
      #("sign", json.string(currency.sign)),
      #("symbol", json.string(currency.symbol)),
    ])
  }
}
