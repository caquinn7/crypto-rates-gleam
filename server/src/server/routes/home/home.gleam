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
  html.html([attribute.attribute("lang", "en")], [
    html.head([], [
      html.meta([attribute.attribute("charset", "UTF-8")]),
      html.meta([
        attribute.attribute("content", "width=device-width, initial-scale=1.0"),
        attribute.name("viewport"),
      ]),
      html.title([], "RateRadar 💹 📡"),
      //     html.style(
      //       [],
      //       "
      //   @font-face {
      //     font-family: 'Roboto';
      //     src: url('/static/fonts/roboto/Roboto-VariableFont_wdth,wght.ttf') format('truetype');
      //     font-weight: 100 900;
      //     /* Supports weights from 100 to 900 */
      //     font-stretch: 75% 125%;
      //     /* Supports widths (stretch) from 75% to 125% */
      //     font-style: normal;
      //   }
      //   @font-face {
      //     font-family: 'Roboto';
      //     src: url('/static/fonts/roboto/Roboto-Italic-VariableFont_wdth,wght.ttf') format('truetype');
      //     font-weight: 100 900;
      //     font-stretch: 75% 125%;
      //     font-style: italic;
      //   }
      //   body {
      //     font-family: 'Roboto', sans-serif;
      //   }
      // ",
      //     ),
      html.link([
        attribute.rel("stylesheet"),
        attribute.type_("text/css"),
        attribute.href("/static/client.css"),
      ]),
      html.script(
        [attribute.src("/static/client.mjs"), attribute.type_("module")],
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
  ])
}
