import gleam/http
import gleam/list
import gleam/option.{Some}
import gleam/result
import gleam/string_tree
import server/coin_market_cap as cmc
import server/routes/conversions
import server/routes/currencies
import server/routes/home/home
import server/web.{type Context}
import timestamps
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  let request_crypto = cmc.get_crypto_currencies(ctx.cmc_api_key, _)
  let request_fiat = cmc.get_fiat_currencies(ctx.cmc_api_key, _)
  let request_conversion = cmc.get_conversion(ctx.cmc_api_key, _)

  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> {
      use <- wisp.require_method(req, http.Get)
      let request_crypto = fn() { request_crypto(ctx.crypto_limit) }
      let get_fiat = fn() {
        use cmc_response <- result.try(
          request_fiat(100)
          |> result.replace_error(Nil),
        )
        case cmc_response.data {
          Some(currencies) ->
            list.unique(currencies)
            |> list.filter(fn(currency) {
              list.is_empty(ctx.fiats)
              || list.contains(ctx.fiats, currency.symbol)
            })
          _ -> []
        }
        |> Ok
      }
      home.get(req, request_crypto, get_fiat, request_conversion, ctx)
    }

    ["api", "ping"] -> {
      wisp.json_response(
        timestamps.new()
          |> timestamps.to_string
          |> string_tree.from_string,
        200,
      )
    }

    ["api", "currencies", "crypto"] -> {
      use <- wisp.require_method(req, http.Get)
      currencies.get_crypto(req, request_crypto)
    }

    ["api", "currencies", "fiat"] -> {
      use <- wisp.require_method(req, http.Get)
      currencies.get_fiat(req, request_fiat)
    }

    ["api", "conversions"] -> {
      use <- wisp.require_method(req, http.Get)
      conversions.get(req, request_conversion)
    }

    _ -> wisp.not_found()
  }
}
