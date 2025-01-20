import client.{
  UserClickedCurrencySelector, UserFilteredCurrencies, UserSelectedCurrency,
}
import client/model
import gleam/json
import gleam/result
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/routes/conversions.{type RequestConversion}
import server/routes/currencies.{type RequestCrypto, type RequestFiat}
import server/routes/home/ssr_data as server_ssr_data
import server/web.{type Context}
import shared/ssr_data
import wisp.{type Request, type Response}

pub fn get(
  _req: Request,
  get_crypto: RequestCrypto,
  get_fiat: RequestFiat,
  get_conversion: RequestConversion,
  ctx: Context,
) -> Response {
  let ssr_data =
    server_ssr_data.get(get_crypto, get_fiat, get_conversion, "BTC", "USD")
    |> result.unwrap(or: ssr_data.empty())

  let ssr_json =
    ssr_data
    |> ssr_data.encoder()
    |> json.to_string

  let content =
    model.from_ssr_data(
      ssr_data,
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> client.view
    |> page_scaffold(ssr_json, ctx)

  content
  |> element.to_document_string_builder
  |> wisp.html_body(wisp.response(200), _)
}

fn page_scaffold(
  content: Element(a),
  init_json: String,
  ctx: Context,
) -> Element(a) {
  html.html(
    [
      attribute.attribute("lang", "en"),
      attribute.attribute("data-theme", "business"),
    ],
    [
      html.head([], [
        html.meta([attribute.attribute("charset", "UTF-8")]),
        html.meta([
          attribute.attribute(
            "content",
            "width=device-width, initial-scale=1.0",
          ),
          attribute.name("viewport"),
        ]),
        html.title([], "RateRadar 💹 📡"),
        html.link([
          attribute.rel("stylesheet"),
          attribute.type_("text/css"),
          attribute.href("/static/" <> ctx.css_file),
        ]),
        html.script(
          [attribute.src("/static/" <> ctx.js_file), attribute.type_("module")],
          "",
        ),
        html.script(
          [attribute.type_("application/json"), attribute.id("model")],
          init_json,
        ),
        html.script(
          [attribute.type_("text/javascript")],
          "window.__ENV__ = " <> "\"" <> ctx.env <> "\"",
        ),
      ]),
      html.body([], [html.div([attribute.id("app")], [content])]),
    ],
  )
}
