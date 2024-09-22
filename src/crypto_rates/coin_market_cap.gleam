import decode
import gleam/dynamic.{type Dynamic}
import gleam/http/request
import gleam/httpc
import gleam/json
import gleam/option.{type Option}
import gleam/result
import gleam/string

pub type CryptoCurrency {
  CryptoCurrency(id: Int, rank: Option(Int), name: String, symbol: String)
}

pub type Status {
  Status(error_code: Int, error_message: Option(String))
}

pub type CmcResponse(a) {
  CmcResponse(status: Status, data: Option(List(a)))
}

const base_url = "https://pro-api.coinmarketcap.com"

pub fn get_crypto_currencies(
  api_key: String,
) -> Result(CmcResponse(CryptoCurrency), Nil) {
  let assert Ok(req) = request.to(base_url <> "/v1/cryptocurrency/map")
  let req =
    req
    |> request.set_header("x-cmc_pro_api_key", api_key)
    |> request.set_query([
      #("sort", "cmc_rank"),
      #("limit", "100"),
      #("listing_status", "active"),
    ])

  case httpc.send(req) {
    Ok(res) ->
      res.body
      |> json.decode(decode)
      |> result.map_error(fn(err) {
        panic as { "failed to decode response: " <> string.inspect(err) }
      })
    Error(err) -> panic as { "request failed: " <> string.inspect(err) }
  }
}

fn decode(json: Dynamic) {
  let status_decoder =
    decode.into({
      use error_code <- decode.parameter
      use error_message <- decode.parameter
      Status(error_code, error_message)
    })
    |> decode.field("error_code", decode.int)
    |> decode.field("error_message", decode.optional(decode.string))

  let data_decoder =
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

  let decoder =
    decode.into({
      use status <- decode.parameter
      use data <- decode.parameter
      CmcResponse(status, data)
    })
    |> decode.field("status", status_decoder)
    |> decode.field("data", decode.optional(decode.list(data_decoder)))

  decoder |> decode.from(json)
}
