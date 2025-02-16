import client/api
import client/browser/element as browser_element
import client/browser/event as browser_event
import client/button_dropdown.{type ButtonDropdown, ButtonDropdown}
import client/custom_effects
import client/model.{type AmountInput, type Model, type Side, Left, Model, Right}
import decode/zero
import gleam/float
import gleam/int
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
  UserResizedAmountInput(Side, Int)
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
        UserTypedAmount,
        UserClickedCurrencySelector,
        UserFilteredCurrencies,
        UserSelectedCurrency,
      )
    Error(_) ->
      model.init(
        UserTypedAmount,
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
  let api_effect = case model {
    Model([], [], ..) ->
      effect.batch([
        api.get_crypto(ApiReturnedCrypto),
        api.get_fiat(ApiReturnedFiat),
      ])
    Model([], _, ..) -> api.get_crypto(ApiReturnedCrypto)
    Model(_, [], ..) -> api.get_fiat(ApiReturnedFiat)
    _ -> effect.none()
  }

  let resize_inputs_effect =
    effect.batch([
      resize_amount_input_effect(model, Left),
      resize_amount_input_effect(model, Right),
    ])

  #(model, effect.batch([api_effect, resize_inputs_effect]))
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
      // user changes left amount -> from: left, to: right
      // user changes left currency -> from: left, to: right
      // user changes right amount -> from: right, to: left
      // user changes right currency -> from: left, to: right
      let ConversionResponse(
        Currency(from_id, _from_amount),
        Currency(to_id, to_amount),
      ) = conversion

      let assert Ok(currency_1_id) = model.get_selected_currency_id(model, Left)
      let to_amount = float.to_string(to_amount)

      case currency_1_id, from_id, to_id {
        _, _, _ if currency_1_id == from_id -> #(
          model.with_amount(model, Right, to_amount),
          resize_amount_input_effect(model, Right),
        )

        _, _, _ if currency_1_id == to_id -> #(
          model.with_amount(model, Left, to_amount),
          resize_amount_input_effect(model, Left),
        )

        _, _, _ -> panic
      }
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
            let ButtonDropdown(id, _, _, _, show_dropdown, ..) =
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

      let effect = case model.to_conversion_params(side, model) {
        Ok(params) ->
          effect.batch([
            api.get_conversion(params, ApiReturnedConversion),
            resize_amount_input_effect(model, side),
          ])
        Error(_) -> resize_amount_input_effect(model, side)
      }

      #(model, effect)
    }

    UserResizedAmountInput(side, width) -> #(
      model.with_amount_width(model, side, width),
      effect.none(),
    )

    UserClickedCurrencySelector(side) -> {
      let model =
        model
        |> model.toggle_selector_dropdown(side)
        |> model.filter_currencies(side, "")

      let dd_visible =
        model.map_currency_input_group(model, side, fn(group) {
          group.currency_selector.show_dropdown
        })

      let effect = case dd_visible {
        True -> custom_effects.focus(model.get_search_input_id(model, side))
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

      let effect = case model.to_conversion_params(Left, model) {
        Ok(params) -> api.get_conversion(params, ApiReturnedConversion)
        Error(_) -> effect.none()
      }

      #(model, effect)
    }
  }
}

fn resize_amount_input_effect(model: Model(Msg), side: Side) -> Effect(Msg) {
  custom_effects.resize_input(
    model.get_amount_input_id(model, side),
    model.default_amount_input_width,
    UserResizedAmountInput(side, _),
  )
}

pub fn view(model: Model(Msg)) -> Element(Msg) {
  element.fragment([header(), main_content(model)])
}

fn header() -> Element(Msg) {
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

fn main_content(model: Model(Msg)) -> Element(Msg) {
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
        amount_input(left_group.amount_input),
        button_dropdown.view(left_group.currency_selector),
        equal_sign,
        amount_input(right_group.amount_input),
        button_dropdown.view(right_group.currency_selector),
      ]),
    ],
  )
}

fn amount_input(amount_input: AmountInput(Msg)) {
  let input =
    html.input([
      attribute.class("amount-input"),
      attribute.class(
        "px-6 py-4 border rounded-lg focus:outline-none bg-neutral text-3xl text-center text-neutral-content caret-info",
      ),
      attribute.id(amount_input.id),
      attribute.style([#("width", int.to_string(amount_input.width) <> "px")]),
      attribute.value(amount_input.value),
      event.on_input(amount_input.on_input),
    ])

  let mirror_input =
    html.span(
      [attribute.class("amount-input-mirror absolute invisible whitespace-pre")],
      [element.text(amount_input.value)],
    )

  html.div([], [input, mirror_input])
}
