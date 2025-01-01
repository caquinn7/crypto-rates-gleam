import decode/zero.{type Decoder}
import gleam/json.{type Json}

pub type ConversionResponse {
  ConversionResponse(from: Currency, to: Currency)
}

pub type Currency {
  Currency(id: Int, amount: Float)
}

pub fn encoder() -> fn(ConversionResponse) -> Json {
  fn(conversion_response: ConversionResponse) {
    let encode_currency = fn(currency: Currency) {
      json.object([
        #("id", json.int(currency.id)),
        #("amount", json.float(currency.amount)),
      ])
    }

    json.object([
      #("from", encode_currency(conversion_response.from)),
      #("to", encode_currency(conversion_response.to)),
    ])
  }
}

pub fn decoder() -> Decoder(ConversionResponse) {
  let currency_decoder = {
    use id <- zero.field("id", zero.int)
    use amount <- zero.field("amount", zero.float)
    zero.success(Currency(id, amount))
  }

  use from <- zero.field("from", currency_decoder)
  use to <- zero.field("to", currency_decoder)
  zero.success(ConversionResponse(from, to))
}
