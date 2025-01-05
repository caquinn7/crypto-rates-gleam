import decode/zero.{type Decoder}
import gleam/json.{type Json}
import gleam/option.{type Option, None}
import shared/coin_market_cap_types.{type CryptoCurrency, type FiatCurrency} as cmc_types

pub type SsrData {
  SsrData(
    crypto: List(CryptoCurrency),
    fiat: List(FiatCurrency),
    currencies: #(Currency, Currency),
  )
}

pub type Currency {
  Currency(amount: Option(Float), id: Option(Int))
}

pub fn empty() -> SsrData {
  let empty_currency = Currency(None, None)
  SsrData([], [], #(empty_currency, empty_currency))
}

pub fn encoder() -> fn(SsrData) -> Json {
  fn(data: SsrData) {
    let currency_encoder = fn(currency: Currency) {
      json.object([
        #("amount", json.nullable(currency.amount, json.float)),
        #("id", json.nullable(currency.id, json.int)),
      ])
    }

    json.object([
      #("crypto", json.array(data.crypto, cmc_types.crypto_currency_encoder())),
      #("fiat", json.array(data.fiat, cmc_types.fiat_currency_encoder())),
      #("currency_1", currency_encoder(data.currencies.0)),
      #("currency_2", currency_encoder(data.currencies.1)),
    ])
  }
}

pub fn decoder() -> Decoder(SsrData) {
  let currency_decoder = {
    use id <- zero.field("id", zero.optional(zero.int))
    use amount <- zero.field("amount", zero.optional(zero.float))
    zero.success(Currency(amount, id))
  }

  use crypto <- zero.field(
    "crypto",
    zero.list(cmc_types.crypto_currency_decoder()),
  )
  use fiat <- zero.field("fiat", zero.list(cmc_types.fiat_currency_decoder()))
  use currency_1 <- zero.field("currency_1", currency_decoder)
  use currency_2 <- zero.field("currency_2", currency_decoder)
  zero.success(SsrData(crypto:, fiat:, currencies: #(currency_1, currency_2)))
}
