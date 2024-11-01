import decode.{type Decoder}
import gleam/dict.{type Dict}
import gleam/dynamic.{type DecodeError, type Dynamic}
import gleam/float
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string

pub type CmcListResponse(a) {
  CmcListResponse(status: Status, data: Option(List(a)))
}

pub type CmcResponse(a) {
  CmcResponse(status: Status, data: Option(a))
}

pub type Status {
  Status(error_code: Int, error_message: Option(String))
}

pub type CryptoCurrency {
  CryptoCurrency(id: Int, rank: Option(Int), name: String, symbol: String)
}

pub type FiatCurrency {
  FiatCurrency(id: Int, name: String, sign: String, symbol: String)
}

pub type ConversionParameters {
  ConversionParameters(amount: Float, id: Int, convert_id: Int)
}

pub type Conversion {
  Conversion(
    id: Int,
    symbol: String,
    name: String,
    amount: Float,
    quote: Dict(String, QuoteItem),
  )
}

pub type QuoteItem {
  QuoteItem(price: Float)
}

const base_url = "https://pro-api.coinmarketcap.com"

pub fn get_crypto_currencies(
  api_key: String,
  limit: Int,
) -> Result(CmcListResponse(CryptoCurrency), Dynamic) {
  let assert Ok(req) = request.to(base_url <> "/v1/cryptocurrency/map")
  req
  |> set_headers(api_key)
  |> request.set_query([
    #("sort", "cmc_rank"),
    #("limit", int.to_string(limit)),
    #("listing_status", "active"),
    #("aux", ""),
  ])
  |> send_request(decode_cmc_list_response, crypto_currency_decoder())
}

pub fn get_fiat_currencies(
  api_key: String,
  limit: Int,
) -> Result(CmcListResponse(FiatCurrency), Dynamic) {
  let assert Ok(req) = request.to(base_url <> "/v1/fiat/map")
  req
  |> set_headers(api_key)
  |> request.set_query([#("sort", "id"), #("limit", int.to_string(limit))])
  |> send_request(decode_cmc_list_response, fiat_currency_decoder())
}

pub fn get_conversion(
  api_key: String,
  params: ConversionParameters,
) -> Result(CmcResponse(Conversion), Dynamic) {
  let ConversionParameters(amount, id, convert_id) = params

  let assert Ok(req) = request.to(base_url <> "/v2/tools/price-conversion")

  req
  |> set_headers(api_key)
  |> request.set_query([
    #("amount", float.to_string(amount)),
    #("id", int.to_string(id)),
    #("convert_id", int.to_string(convert_id)),
  ])
  |> send_request(decode_cmc_response, conversion_decoder())
}

fn set_headers(req: Request(a), api_key: String) -> Request(a) {
  req
  |> request.set_header("x-cmc_pro_api_key", api_key)
  |> request.set_header("accept", "application/json")
}

fn send_request(
  req: Request(String),
  decode: fn(Dynamic, Decoder(a)) -> Result(b, List(DecodeError)),
  decoder: Decoder(a),
) {
  use res <- result.try(httpc.send(req))
  res.body
  |> decode_json_response(decode, decoder)
}

fn decode_json_response(
  json: String,
  decode: fn(Dynamic, Decoder(a)) -> Result(b, List(DecodeError)),
  decoder: Decoder(a),
) {
  json
  |> json.decode(fn(json) { decode(json, decoder) })
  |> result.map_error(fn(err) {
    panic as { "failed to decode response: " <> string.inspect(err) }
  })
}

fn crypto_currency_decoder() -> Decoder(CryptoCurrency) {
  decode.into({
    use id <- decode.parameter
    use rank <- decode.parameter
    use name <- decode.parameter
    use symbol <- decode.parameter
    CryptoCurrency(id, rank, name, symbol)
  })
  |> decode.field("id", decode.int)
  |> decode.field("rank", decode.optional(decode.int))
  |> decode.field("name", decode.string)
  |> decode.field("symbol", decode.string)
}

fn fiat_currency_decoder() -> Decoder(FiatCurrency) {
  decode.into({
    use id <- decode.parameter
    use name <- decode.parameter
    use sign <- decode.parameter
    use symbol <- decode.parameter
    FiatCurrency(id, name, sign, symbol)
  })
  |> decode.field("id", decode.int)
  |> decode.field("name", decode.string)
  |> decode.field("sign", decode.string)
  |> decode.field("symbol", decode.string)
}

fn conversion_decoder() -> Decoder(Conversion) {
  // {
  //     "id": 1,
  //     "symbol": "BTC",
  //     "name": "Bitcoin",
  //     "amount": 1.5,
  //     "last_updated": "2024-09-27T20:57:00.000Z",
  //     "quote": {
  //         "2010": {
  //             "price": 245304.45530431595,
  //             "last_updated": "2024-09-27T20:57:00.000Z"
  //         }
  //     }
  // }
  let quote_decoder = {
    decode.into({
      use price <- decode.parameter
      QuoteItem(price)
    })
    |> decode.field("price", decode.float)
  }

  decode.into({
    use id <- decode.parameter
    use symbol <- decode.parameter
    use name <- decode.parameter
    use amount <- decode.parameter
    use quote <- decode.parameter
    Conversion(id, symbol, name, amount, quote)
  })
  |> decode.field("id", decode.int)
  |> decode.field("symbol", decode.string)
  |> decode.field("name", decode.string)
  |> decode.field(
    "amount",
    decode.one_of([decode.float, decode.int |> decode.map(int.to_float)]),
  )
  |> decode.field("quote", decode.dict(decode.string, quote_decoder))
}

fn status_decoder() -> Decoder(Status) {
  decode.into({
    use error_code <- decode.parameter
    use error_message <- decode.parameter
    Status(error_code, error_message)
  })
  |> decode.field("error_code", decode.int)
  |> decode.field("error_message", decode.optional(decode.string))
}

fn decode_cmc_list_response(
  json: Dynamic,
  data_decoder: Decoder(a),
) -> Result(CmcListResponse(a), List(DecodeError)) {
  decode.into({
    use status <- decode.parameter
    use data <- decode.parameter
    CmcListResponse(status, data)
  })
  |> decode.field("status", status_decoder())
  |> decode.field("data", decode.optional(decode.list(data_decoder)))
  |> decode.from(json)
}

fn decode_cmc_response(
  json: Dynamic,
  data_decoder: Decoder(a),
) -> Result(CmcResponse(a), List(DecodeError)) {
  decode.into({
    use status <- decode.parameter
    use data <- decode.parameter
    CmcResponse(status, data)
  })
  |> decode.field("status", status_decoder())
  |> decode.field("data", decode.optional(data_decoder))
  |> decode.from(json)
}
