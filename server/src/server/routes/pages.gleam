import client.{
  UserClickedCurrencySelector, UserFilteredCurrencies, UserSelectedCurrency,
}
import client/model
import gleam/json
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/web.{type Context}
import shared/ssr_data.{type SsrData, SsrData}
import wisp.{type Response}

pub fn home(ssr_data: SsrData, ctx: Context) -> Response {
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
      html.title([], "🚧 client"),
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
