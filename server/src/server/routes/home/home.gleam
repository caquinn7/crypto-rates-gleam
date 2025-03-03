import client.{
  UserClickedCurrencySelector, UserFilteredCurrencies, UserSelectedCurrency,
  UserTypedAmount,
}
import client/model
import client/model_utils
import gleam/json
import gleam/option.{None}
import gleam/result
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/coin_market_cap.{type CmcListResponse, type RequestError}
import server/routes/conversions.{type RequestConversion}
import server/routes/home/ssr_data as server_ssr_data
import server/web.{type Context}
import shared/coin_market_cap_types.{type CryptoCurrency, type FiatCurrency}
import shared/ssr_data.{Currency, SsrData}
import wisp.{type Request, type Response}

pub fn get(
  _req: Request,
  get_crypto: fn() -> Result(CmcListResponse(CryptoCurrency), RequestError),
  get_fiat: fn() -> Result(List(FiatCurrency), Nil),
  get_conversion: RequestConversion,
  ctx: Context,
) -> Response {
  let ssr_data =
    server_ssr_data.get(get_crypto, get_fiat, get_conversion, "BTC", "USD")
    |> result.unwrap(
      or: SsrData([], [], #(Currency(None, None), Currency(None, None))),
    )

  let ssr_json =
    ssr_data
    |> ssr_data.encoder()
    |> json.to_string

  let content =
    model_utils.from_ssr_data(
      ssr_data,
      UserTypedAmount,
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.view
    |> page_scaffold(ssr_json, ctx)

  content
  |> element.to_document_string_builder
  |> wisp.html_body(wisp.response(200), _)
}

// todo?: ideally i could copy the index.html from
// the client app so it would only have to be modified in one place.
// but, I need to be able to inject the ssr data
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
        html.style(
          [],
          "
        @font-face {
          font-family: 'Roboto';
          src: url('/static/fonts/roboto/Roboto-VariableFont_wdth,wght.ttf') format('truetype');
          font-weight: 100 900;
          /* Supports weights from 100 to 900 */
          font-stretch: 75% 125%;
          /* Supports widths (stretch) from 75% to 125% */
          font-style: normal;
        }
        @font-face {
          font-family: 'Roboto';
          src: url('/static/fonts/roboto/Roboto-Italic-VariableFont_wdth,wght.ttf') format('truetype');
          font-weight: 100 900;
          font-stretch: 75% 125%;
          font-style: italic;
        }
        body {
          font-family: 'Roboto', sans-serif;
        }
      ",
        ),
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
      html.body([attribute.class("flex flex-col min-h-screen")], [
        html.div([attribute.id("app")], [content]),
      ]),
    ],
  )
}
