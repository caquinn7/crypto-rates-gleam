import client/api
import client/browser/element as browser_element
import client/browser/event as browser_event
import client/button_dropdown.{type ButtonDropdown, ButtonDropdown}
import client/model.{
  type CurrencyInputGroup, type Model, type Side, CurrencyInputGroup, Left,
  Model, Right,
}
import decode/zero
import gleam/json
import gleam/option.{Some}
import gleam/result
import lustre
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import lustre_http.{type HttpError}
import plinth/browser/document
import plinth/browser/element as plinth_element
import plinth/browser/event as plinth_event
import plinth/browser/window
import shared/coin_market_cap_types.{type CryptoCurrency, type FiatCurrency}
import shared/ssr_data

pub type Msg {
  ApiReturnedCrypto(Result(List(CryptoCurrency), HttpError))
  ApiReturnedFiat(Result(List(FiatCurrency), HttpError))
  UserClickedInDocument(
    plinth_event.Event(plinth_event.UIEvent(browser_event.MouseEvent)),
  )
  UserTypedAmount(Side, String)
  UserClickedCurrencySelector(Side)
  UserFilteredCurrencies(Side, String)
  UserSelectedCurrency(Side, String)
}

pub fn main() {
  let ssr_data = {
    use json_str <- result.try(
      document.query_selector("#model")
      |> result.map(plinth_element.inner_text),
    )

    json_str
    |> json.decode(zero.run(_, ssr_data.decoder()))
    |> result.replace_error(Nil)
  }

  let model = case ssr_data {
    Ok(data) ->
      model.from_ssr_data(
        data,
        UserClickedCurrencySelector,
        UserFilteredCurrencies,
        UserSelectedCurrency,
      )
    Error(_) ->
      model.init(
        UserClickedCurrencySelector,
        UserFilteredCurrencies,
        UserSelectedCurrency,
      )
  }

  let app = lustre.application(init, update, view)
  let assert Ok(to_runtime) = lustre.start(app, "#app", model)

  // now your lustre app is running, and you have a reference
  // to the runtime so you can dispatch messages to it.
  document.add_event_listener("click", fn(event) {
    event
    |> UserClickedInDocument
    |> lustre.dispatch
    |> to_runtime
  })

  Nil
}

pub fn init(model: Model(Msg)) -> #(Model(Msg), Effect(Msg)) {
  let effect = case model {
    Model([], [], ..) ->
      effect.batch([
        api.get_crypto(ApiReturnedCrypto),
        api.get_fiat(ApiReturnedFiat),
      ])
    Model([], _, ..) -> api.get_crypto(ApiReturnedCrypto)
    Model(_, [], ..) -> api.get_fiat(ApiReturnedFiat)
    _ -> effect.none()
  }

  #(model, effect)
}

pub fn update(model: Model(Msg), msg: Msg) -> #(Model(Msg), Effect(Msg)) {
  case msg {
    ApiReturnedCrypto(Ok(crypto)) -> #(
      model.with_crypto(model, crypto),
      effect.none(),
    )

    ApiReturnedCrypto(Error(_)) -> #(model, effect.none())

    ApiReturnedFiat(Ok(fiat)) -> #(model.with_fiat(model, fiat), effect.none())

    ApiReturnedFiat(Error(_)) -> #(model, effect.none())

    UserClickedInDocument(event) -> {
      let assert Ok(clicked_elem) =
        event
        |> plinth_event.target
        |> plinth_element.cast

      let update_side = fn(side: Side, model: Model(Msg)) {
        let currency_input_group = case side {
          Left -> model.currency_input_groups.0
          Right -> model.currency_input_groups.1
        }
        let CurrencyInputGroup(_, btn_dd) = currency_input_group
        let ButtonDropdown(_, btn_dd_id, _, _, _, visible, ..) = btn_dd
        let assert Ok(btn_dd_elem) = document.get_element_by_id(btn_dd_id)

        let clicked_outside_dd =
          !browser_element.contains(btn_dd_elem, clicked_elem)

        let should_toggle = visible && clicked_outside_dd
        case should_toggle {
          True ->
            model
            |> model.toggle_selector_dropdown(side)
            |> model.filter_currencies(side, "")
          _ -> model
        }
      }

      let model =
        model
        |> update_side(Left, _)
        |> update_side(Right, _)

      #(model, effect.none())
    }

    UserTypedAmount(side, amount_str) -> #(
      model.with_amount(model, side, amount_str),
      effect.none(),
    )

    UserClickedCurrencySelector(side) -> {
      let model =
        model
        |> model.toggle_selector_dropdown(side)
        |> model.filter_currencies(side, "")

      let target_currency_selector = {
        let target_group = case side {
          Left -> model.currency_input_groups.0
          Right -> model.currency_input_groups.1
        }
        target_group.currency_selector
      }

      let search_focus_effect =
        effect.from(fn(_) {
          window.request_animation_frame(fn(_) {
            let assert Ok(search_elem) =
              document.get_element_by_id(
                target_currency_selector.search_input_id,
              )
            plinth_element.focus(search_elem)
          })
          Nil
        })

      let effect = case target_currency_selector.show_dropdown {
        True -> search_focus_effect
        _ -> effect.none()
      }

      #(model, effect)
    }

    UserFilteredCurrencies(side, filter) -> #(
      model.filter_currencies(model, side, filter),
      effect.none(),
    )

    UserSelectedCurrency(side, selected_val) -> {
      let assert Ok(model) =
        model.with_selected_currency(model, side, Some(selected_val))

      let model =
        model
        |> model.toggle_selector_dropdown(side)
        |> model.filter_currencies(side, "")

      #(model, effect.none())
    }
  }
}

pub fn view(model: Model(Msg)) -> Element(Msg) {
  html.div([attribute.class("flex flex-col gap-12")], [
    header(),
    main_content(model),
  ])
}

fn header() -> Element(Msg) {
  html.header([attribute.class("p-4 bg-red-500 text-white")], [
    html.h1(
      [attribute.class("w-full mx-auto max-w-screen-xl text-4xl font-bold")],
      [html.text("Crypto Rates")],
    ),
  ])
}

fn main_content(model: Model(Msg)) -> Element(Msg) {
  let #(side1, side2) = model.currency_input_groups

  let equal_sign =
    html.p([attribute.attribute("class", "text-xl font-bold text-gray-700")], [
      element.text("="),
    ])

  html.main([attribute.class("flex items-center")], [
    html.div(
      [
        attribute.class(
          "flex flex-col items-center gap-8 w-full max-w-screen-lg mx-auto",
        ),
      ],
      [
        html.div([attribute.class("flex items-center space-x-4")], [
          currency_input_group(side1, UserTypedAmount(Left, _)),
          equal_sign,
          currency_input_group(side2, UserTypedAmount(Right, _)),
        ]),
      ],
    ),
  ])
}

fn currency_input_group(
  currency_input_group: CurrencyInputGroup(Msg),
  on_amount_input: fn(String) -> Msg,
) -> Element(Msg) {
  html.div([attribute.class("flex items-center space-x-4")], [
    html.input([
      attribute.class(
        "w-24 p-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:outline-none",
      ),
      attribute.value(currency_input_group.amount),
      event.on_input(on_amount_input),
    ]),
    button_dropdown.view(currency_input_group.currency_selector),
  ])
}
