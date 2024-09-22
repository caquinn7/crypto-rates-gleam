import crypto_rates/coin_market_cap.{type CryptoCurrency, CmcResponse}
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
    ["crypto"] -> {
      use <- wisp.require_method(req, http.Get)
      get_crypto_currencies()
    }
    _ -> wisp.not_found()
  }
}

fn get_crypto_currencies() {
  let assert Ok(api_key) = env.get_string("COIN_MARKET_CAP_API_KEY")
  let assert Ok(coin_market_cap.CmcResponse(_status, Some(crypto))) =
    coin_market_cap.get_crypto_currencies(api_key)

  crypto
  |> list.unique
  |> encode_crypto_currencies
  |> json.to_string_builder
  |> wisp.json_response(200)
}

fn encode_crypto_currencies(crypto: List(CryptoCurrency)) -> json.Json {
  let crypto_currency_encoder = fn(crypto_currency: CryptoCurrency) {
    json.object([
      #("id", json.int(crypto_currency.id)),
      #("rank", json.nullable(crypto_currency.rank, json.int)),
      #("name", json.string(crypto_currency.name)),
      #("symbol", json.string(crypto_currency.symbol)),
    ])
  }

  crypto
  |> json.array(crypto_currency_encoder)
}
