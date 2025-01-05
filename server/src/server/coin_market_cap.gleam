import decode/zero.{type Decoder}
import gleam/dict.{type Dict}
import gleam/dynamic.{type Dynamic}
import gleam/float
import gleam/http/request.{type Request}
import gleam/httpc
import gleam/int
import gleam/json
import gleam/option.{type Option, None}
import gleam/result
import shared/coin_market_cap_types.{
  type ConversionParameters, type CryptoCurrency, type FiatCurrency,
  ConversionParameters, CryptoCurrency, FiatCurrency,
} as cmc_types

pub type RequestError {
  HttpError(httpc.HttpError)
  JsonDecodeError(json.DecodeError)
}

pub type CmcResponse(a) {
  CmcResponse(status: Status, data: Option(a))
}

pub type CmcListResponse(a) {
  CmcListResponse(status: Status, data: Option(List(a)))
}

pub type Status {
  Status(error_code: Int, error_message: Option(String))
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
) -> Result(CmcListResponse(CryptoCurrency), RequestError) {
  // only fails if url can't be parsed
  let assert Ok(req) = request.to(base_url <> "/v1/cryptocurrency/map")
  let req =
    req
    |> set_headers(api_key)
    |> request.set_query([
      #("sort", "cmc_rank"),
      #("limit", int.to_string(limit)),
      #("listing_status", "active"),
      #("aux", ""),
    ])

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(HttpError),
  )

  resp.body
  |> json.decode(
    decode_cmc_list_response(_, cmc_types.crypto_currency_decoder()),
  )
  |> result.map_error(JsonDecodeError)
}

pub fn get_fiat_currencies(
  api_key: String,
  limit: Int,
) -> Result(CmcListResponse(FiatCurrency), RequestError) {
  let assert Ok(req) = request.to(base_url <> "/v1/fiat/map")
  let req =
    req
    |> set_headers(api_key)
    |> request.set_query([#("sort", "id"), #("limit", int.to_string(limit))])

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(HttpError),
  )

  resp.body
  |> json.decode(decode_cmc_list_response(_, cmc_types.fiat_currency_decoder()))
  |> result.map_error(JsonDecodeError)
}

pub fn get_conversion(
  api_key: String,
  params: ConversionParameters,
) -> Result(CmcResponse(Conversion), RequestError) {
  let ConversionParameters(amount, id, convert_id) = params

  let assert Ok(req) = request.to(base_url <> "/v2/tools/price-conversion")
  let req =
    req
    |> set_headers(api_key)
    |> request.set_query([
      #("amount", float.to_string(amount)),
      #("id", int.to_string(id)),
      #("convert_id", int.to_string(convert_id)),
    ])

  use resp <- result.try(
    httpc.send(req)
    |> result.map_error(HttpError),
  )

  resp.body
  |> json.decode(decode_cmc_response(_, conversion_decoder()))
  |> result.map_error(JsonDecodeError)
}

fn set_headers(req: Request(a), api_key: String) -> Request(a) {
  req
  |> request.set_header("x-cmc_pro_api_key", api_key)
  |> request.set_header("accept", "application/json")
}

pub fn conversion_decoder() -> Decoder(Conversion) {
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
  let int_or_float_decoder =
    zero.one_of(zero.float, [zero.int |> zero.map(int.to_float)])

  let quote_decoder = {
    use price <- zero.field("price", int_or_float_decoder)
    zero.success(QuoteItem(price))
  }

  use id <- zero.field("id", zero.int)
  use symbol <- zero.field("symbol", zero.string)
  use name <- zero.field("name", zero.string)
  use amount <- zero.field("amount", int_or_float_decoder)
  use quote <- zero.field("quote", zero.dict(zero.string, quote_decoder))
  zero.success(Conversion(id, symbol, name, amount, quote))
}

fn decode_cmc_list_response(json: Dynamic, data_decoder: Decoder(a)) {
  let decoder = {
    use status <- zero.field("status", status_decoder())
    use data <- zero.optional_field(
      "data",
      None,
      zero.optional(zero.list(data_decoder)),
    )
    zero.success(CmcListResponse(status, data))
  }
  zero.run(json, decoder)
}

fn decode_cmc_response(json: Dynamic, data_decoder: Decoder(a)) {
  let decoder = {
    use status <- zero.field("status", status_decoder())
    use data <- zero.optional_field("data", None, zero.optional(data_decoder))
    zero.success(CmcResponse(status, data))
  }
  zero.run(json, decoder)
}

pub fn status_decoder() -> Decoder(Status) {
  use error_code <- zero.field("error_code", zero.int)
  use error_message <- zero.optional_field(
    "error_message",
    None,
    zero.optional(zero.string),
  )
  zero.success(Status(error_code, error_message))
}
