import gleam/http
import gleam/option.{None, Some}
import gleam/result
import gleam/string_tree
import server/coin_market_cap as cmc
import server/routes/conversions
import server/routes/currencies
import server/routes/pages
import server/web.{type Context}
import shared/ssr_data.{Currency, SsrData}
import timestamps
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  let request_crypto = cmc.get_crypto_currencies(ctx.cmc_api_key, _)
  let request_fiat = cmc.get_fiat_currencies(ctx.cmc_api_key, _)

  use req <- web.middleware(req, ctx)

  case wisp.path_segments(req) {
    [] -> {
      let crypto =
        request_crypto(100)
        |> result.map(fn(cmc_response) {
          case cmc_response.data {
            Some(crypto) -> crypto
            _ -> []
          }
        })
        |> result.unwrap([])

      let fiat =
        request_fiat(100)
        |> result.map(fn(cmc_response) {
          case cmc_response.data {
            Some(fiat) -> fiat
            _ -> []
          }
        })
        |> result.unwrap([])

      SsrData(crypto, fiat, #(Currency(None, None), Currency(None, None)))
      |> pages.home(ctx)
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
      conversions.get(req, cmc.get_conversion(ctx.cmc_api_key, _))
    }

    _ -> wisp.not_found()
  }
}
