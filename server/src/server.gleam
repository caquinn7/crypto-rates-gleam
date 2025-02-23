import dot_env
import dot_env/env
import gleam/erlang/process
import gleam/string
import mist
import server/router
import server/web.{Context}
import wisp
import wisp/wisp_mist

pub fn main() {
  wisp.configure_logger()

  load_env()

  let assert Ok(env) = env.get_string("ENV")
  let assert Ok(css_file) = env.get_string("CSS_FILE")
  let assert Ok(js_file) = env.get_string("JS_FILE")
  let assert Ok(cmc_api_key) = env.get_string("COIN_MARKET_CAP_API_KEY")
  let crypto_limit = env.get_int_or("CRYPTO_LIMIT", 25)
  let fiats = case env.get_string("FIAT_CURRENCIES") {
    Error(_) -> []
    Ok(s) -> string.split(s, ",")
  }

  let ctx =
    Context(
      env:,
      static_directory: static_directory(),
      css_file:,
      js_file:,
      cmc_api_key:,
      crypto_limit:,
      fiats:,
    )

  let assert Ok(secret_key_base) = env.get_string("SECRET_KEY_BASE")
  let assert Ok(_) =
    wisp_mist.handler(router.handle_request(_, ctx), secret_key_base)
    |> mist.new
    |> mist.port(8080)
    |> mist.start_http

  process.sleep_forever()
}

fn load_env() {
  dot_env.new()
  |> dot_env.set_path(".env")
  |> dot_env.set_debug(True)
  |> dot_env.set_ignore_missing_file(True)
  |> dot_env.load
}

/// The priv directory is where we store non-Gleam and non-Erlang files,
/// including static assets to be served.
/// This function returns an absolute path and works both in development and in
/// production after compilation.
fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("server")
  priv_directory <> "/static"
}
