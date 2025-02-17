import client/models/currency_input_group.{type CurrencyInputGroup}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import shared/coin_market_cap_types.{type CryptoCurrency, type FiatCurrency}

pub type Model(msg) {
  Model(
    crypto: List(CryptoCurrency),
    fiat: List(FiatCurrency),
    currency_input_groups: #(CurrencyInputGroup(msg), CurrencyInputGroup(msg)),
  )
}

pub fn view(model: Model(msg)) -> Element(msg) {
  element.fragment([header(), main_content(model)])
}

fn header() -> Element(msg) {
  html.header([attribute.class("p-4 border-b border-base-content")], [
    html.h1(
      [
        attribute.class(
          "w-full mx-auto max-w-screen-xl text-4xl text-base-content font-bold",
        ),
      ],
      [html.text("RateRadar")],
    ),
  ])
}

fn main_content(model: Model(msg)) -> Element(msg) {
  let #(left_group, right_group) = model.currency_input_groups

  let equal_sign =
    html.p(
      [attribute.attribute("class", "text-3xl text-base-content font-bold")],
      [element.text("=")],
    )

  html.div(
    [attribute.class("absolute inset-0 flex items-center justify-center p-4")],
    [
      html.div([attribute.class("flex items-center space-x-4")], [
        currency_input_group.view(left_group),
        equal_sign,
        currency_input_group.view(right_group),
      ]),
    ],
  )
}
