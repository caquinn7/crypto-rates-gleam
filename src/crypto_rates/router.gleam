import crypto_rates/coin_market_cap
import crypto_rates/routes/conversions
import crypto_rates/routes/currencies
import crypto_rates/validation_failed
import crypto_rates/web.{type Context}
import gleam/http
import gleam/json
import gleam/result
import gleam/string_builder
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)
  case wisp.path_segments(req) {
    ["ping"] -> wisp.json_response(string_builder.from_string("pong"), 200)

    ["currencies", "crypto"] -> {
      use <- wisp.require_method(req, http.Get)
      currencies.get_crypto(coin_market_cap.get_crypto_currencies(
        ctx.cmc_api_key,
        _,
      ))
    }

    ["currencies", "fiat"] -> {
      use <- wisp.require_method(req, http.Get)
      currencies.get_fiat(coin_market_cap.get_fiat_currencies(
        ctx.cmc_api_key,
        _,
      ))
    }

    ["conversions"] -> {
      use <- wisp.require_method(req, http.Get)
      req
      |> conversions.validate_request
      |> result.map_error(fn(errs) {
        errs
        |> validation_failed.encode
        |> json.to_string_builder
        |> wisp.json_response(400)
      })
      |> result.map(conversions.get(_, fn(conversion_params) {
        coin_market_cap.get_conversion(ctx.cmc_api_key, conversion_params)
      }))
      |> result.unwrap_both
    }

    _ -> wisp.not_found()
  }
}
