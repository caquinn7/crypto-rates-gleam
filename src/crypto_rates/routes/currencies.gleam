import crypto_rates/coin_market_cap.{
  type CmcListResponse, type CryptoCurrency, type FiatCurrency, CmcListResponse,
}
import gleam/dynamic.{type Dynamic}
import gleam/json
import gleam/list
import gleam/option.{Some}
import wisp.{type Response}

pub fn get_crypto(
  reguest_crypto: fn(Int) -> Result(CmcListResponse(CryptoCurrency), Dynamic),
) -> Response {
  let assert Ok(CmcListResponse(_status, Some(crypto))) = reguest_crypto(100)

  crypto
  |> list.unique
  |> json.array(fn(currency) {
    json.object([
      #("id", json.int(currency.id)),
      #("rank", json.nullable(currency.rank, json.int)),
      #("name", json.string(currency.name)),
      #("symbol", json.string(currency.symbol)),
    ])
  })
  |> json.to_string_builder
  |> wisp.json_response(200)
}

pub fn get_fiat(
  reguest_fiat: fn(Int) -> Result(CmcListResponse(FiatCurrency), Dynamic),
) -> Response {
  let assert Ok(CmcListResponse(_status, Some(fiat))) = reguest_fiat(100)

  fiat
  |> list.unique
  |> json.array(fn(currency) {
    json.object([
      #("id", json.int(currency.id)),
      #("name", json.string(currency.name)),
      #("sign", json.string(currency.sign)),
      #("symbol", json.string(currency.symbol)),
    ])
  })
  |> json.to_string_builder
  |> wisp.json_response(200)
}
