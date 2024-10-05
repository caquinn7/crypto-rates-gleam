import crypto_rates/coin_market_cap.{
  type CmcListResponse, type CryptoCurrency, type FiatCurrency, CmcListResponse,
}
import gleam/json
import gleam/list
import gleam/option.{Some}
import wisp.{type Response}

pub fn get_crypto(
  do_get: fn(Int) -> Result(CmcListResponse(CryptoCurrency), Nil),
) -> Response {
  let assert Ok(CmcListResponse(_status, Some(crypto))) = do_get(100)

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
  do_get: fn(Int) -> Result(CmcListResponse(FiatCurrency), Nil),
) -> Response {
  let assert Ok(CmcListResponse(_status, Some(fiat))) = do_get(100)

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
