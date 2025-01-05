import gleam/http
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
      home.get(req, request_crypto, request_fiat, request_conversion, ctx)
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
