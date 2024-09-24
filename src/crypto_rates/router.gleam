import crypto_rates/coin_market_cap.{CmcResponse}
import crypto_rates/web
import dot_env/env
import gleam/http
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/string_builder
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)
  case wisp.path_segments(req) {
    ["ping"] -> wisp.html_response(string_builder.from_string("pong"), 200)
    ["currencies", "crypto"] -> {
      use <- wisp.require_method(req, http.Get)
      get_crypto_currencies()
    }
    ["currencies", "fiat"] -> {
      use <- wisp.require_method(req, http.Get)
      get_fiat_currencies()
    }
    _ -> wisp.not_found()
  }
}

fn get_crypto_currencies() {
  let assert Ok(api_key) = env.get_string("COIN_MARKET_CAP_API_KEY")
  let assert Ok(coin_market_cap.CmcResponse(_status, Some(crypto))) =
    coin_market_cap.get_crypto_currencies(api_key, 100)

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

fn get_fiat_currencies() {
  let assert Ok(api_key) = env.get_string("COIN_MARKET_CAP_API_KEY")
  let assert Ok(coin_market_cap.CmcResponse(_status, Some(fiat))) =
    coin_market_cap.get_fiat_currencies(api_key, 100)

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
