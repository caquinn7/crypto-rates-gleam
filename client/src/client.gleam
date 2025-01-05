import client/api
import client/browser/element as browser_element
import client/browser/event as browser_event
import client/button_dropdown.{type ButtonDropdown, ButtonDropdown}
import client/model.{
  type CurrencyInputGroup, type Model, type Side, CurrencyInputGroup, Left,
  Model, Right,
}
import decode/zero
import gleam/float
import gleam/io
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
import shared/conversion_response.{
  type ConversionResponse, type Currency, ConversionResponse, Currency,
}
import shared/ssr_data

pub type Msg {
  ApiReturnedCrypto(Result(List(CryptoCurrency), HttpError))
  ApiReturnedFiat(Result(List(FiatCurrency), HttpError))
  ApiReturnedConversion(Result(ConversionResponse, HttpError))
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

    ApiReturnedCrypto(Error(_)) -> todo

    ApiReturnedFiat(Ok(fiat)) -> #(model.with_fiat(model, fiat), effect.none())

    ApiReturnedFiat(Error(_)) -> todo

    ApiReturnedConversion(Ok(conversion)) -> {
      let ConversionResponse(
        Currency(from_id, _from_amount),
        Currency(to_id, to_amount),
      ) = conversion |> io.debug

      let assert Ok(currency_1_id) = model.get_currency_id(model, Left)

      let model = case currency_1_id, from_id, to_id {
        _, _, _ if currency_1_id == from_id ->
          model.with_amount(model, Right, float.to_string(to_amount))
        _, _, _ if currency_1_id == to_id ->
          model.with_amount(model, Left, float.to_string(to_amount))
        _, _, _ -> panic
      }

      #(model, effect.none())
    }

    ApiReturnedConversion(Error(_)) -> todo

    UserClickedInDocument(event) -> {
      let assert Ok(clicked_elem) =
        event
        |> plinth_event.target
        |> plinth_element.cast

      let update_side = fn(side, model) {
        let #(btn_dd_id, dd_visible) =
          model.map_currency_input_group(model, side, fn(group) {
            let ButtonDropdown(_, id, _, _, _, show_dropdown, ..) =
              group.currency_selector

            #(id, show_dropdown)
          })

        let assert Ok(btn_dd_elem) = document.get_element_by_id(btn_dd_id)

        let clicked_outside_dd =
          !browser_element.contains(btn_dd_elem, clicked_elem)

        let should_toggle = dd_visible && clicked_outside_dd
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

    UserTypedAmount(side, amount_str) -> {
      let model = {
        let model = model.with_amount(model, side, amount_str)
        let amount_result = model.get_amount(model, side)
        case side, amount_result {
          _, Ok(_) -> model
          Left, Error(_) -> model.with_amount(model, Right, "")
          Right, Error(_) -> model.with_amount(model, Left, "")
        }
      }

      let effect = case model.to_conversion_params(model, side) {
        Ok(params) -> api.get_conversion(params, ApiReturnedConversion)
        Error(_) -> effect.none()
      }

      #(model, effect)
    }

    UserClickedCurrencySelector(side) -> {
      let model =
        model
        |> model.toggle_selector_dropdown(side)
        |> model.filter_currencies(side, "")

      let search_focus_effect =
        effect.from(fn(_) {
          window.request_animation_frame(fn(_) {
            let search_input_id =
              model.map_currency_input_group(model, side, fn(group) {
                group.currency_selector.search_input_id
              })

            let assert Ok(search_elem) =
              document.get_element_by_id(search_input_id)
            plinth_element.focus(search_elem)
          })

          Nil
        })

      let dd_visible =
        model.map_currency_input_group(model, side, fn(group) {
          group.currency_selector.show_dropdown
        })
      let effect = case dd_visible {
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

      let effect = case model.to_conversion_params(model, side) {
        Ok(params) -> api.get_conversion(params, ApiReturnedConversion)
        Error(_) -> effect.none()
      }

      #(model, effect)
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
  let #(left_group, right_group) = model.currency_input_groups

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
          currency_input_group(left_group, UserTypedAmount(Left, _)),
          equal_sign,
          currency_input_group(right_group, UserTypedAmount(Right, _)),
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
