import client
import client/model.{type Model}
import gleam/json
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import server/web.{type Context}
import wisp.{type Response}

pub fn home(model: Model, ctx: Context) -> Response {
  let model_json =
    model
    |> model.encoder()
    |> json.to_string

  let content =
    client.view(model)
    |> page_scaffold(model_json, ctx)

  wisp.response(200)
  |> wisp.html_body(
    content
    |> element.to_document_string_builder(),
  )
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
