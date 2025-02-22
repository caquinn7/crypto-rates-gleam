import client/model.{type Model, Model}
import client/models/auto_resize_input.{type AutoResizeInput, AutoResizeInput}
import client/models/button.{Button}
import client/models/button_dropdown.{
  type ButtonDropdown, type DropdownOption, ButtonDropdown, DropdownOption,
}
import client/models/currency_input_group.{
  type CurrencyInputGroup, CurrencyInputGroup,
}
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/regex
import gleam/result
import gleam/string
import lustre/attribute
import lustre/element/html
import shared/coin_market_cap_types.{
  type ConversionParameters, type CryptoCurrency, type FiatCurrency,
  ConversionParameters,
}
import shared/ssr_data.{type SsrData, SsrData}

pub const crypto_group_key = "Crypto"

pub const fiat_group_key = "Fiat"

pub const default_button_dropdown_text = "Select"

pub const default_amount_input_width = 76

pub type Side {
  Left
  Right
}

pub fn init(
  on_amount_input: fn(Side, String) -> msg,
  on_button_click: fn(Side) -> msg,
  on_search_input: fn(Side, String) -> msg,
  on_select: fn(Side, String) -> msg,
) -> Model(msg) {
  let amount_input_1 =
    AutoResizeInput(
      "amount-input-1",
      "",
      default_amount_input_width,
      on_amount_input(Left, _),
    )

  let btn_dd_1 =
    ButtonDropdown(
      id: "btn-dd-1",
      button: Button(default_button_dropdown_text, on_button_click(Left)),
      dropdown_options: dict.from_list([
        #(crypto_group_key, []),
        #(fiat_group_key, []),
      ]),
      current_value: None,
      show_dropdown: False,
      filter: "",
      search_input_id: "btn-dd-1-search",
      on_search_input: on_search_input(Left, _),
      on_select: on_select(Left, _),
    )

  let currency_input_group_1 =
    CurrencyInputGroup(
      amount_input: amount_input_1,
      currency_selector: btn_dd_1,
    )

  let currency_input_group_2 =
    CurrencyInputGroup(
      amount_input: AutoResizeInput(
        ..amount_input_1,
        id: "amount-input-2",
        on_input: on_amount_input(Right, _),
      ),
      currency_selector: ButtonDropdown(
        ..btn_dd_1,
        id: "btn-dd-2",
        button: Button(..btn_dd_1.button, on_click: on_button_click(Right)),
        search_input_id: "btn-dd-2-search",
        on_search_input: on_search_input(Right, _),
        on_select: on_select(Right, _),
      ),
    )

  Model([], [], #(currency_input_group_1, currency_input_group_2))
}

pub fn from_ssr_data(
  ssr_data: SsrData,
  on_amount_input: fn(Side, String) -> msg,
  on_button_click: fn(Side) -> msg,
  on_search_input: fn(Side, String) -> msg,
  on_select: fn(Side, String) -> msg,
) -> Model(msg) {
  let SsrData(crypto, fiat, #(currency_1, currency_2)) = ssr_data

  let unwrap_amount = fn(optional_float) {
    optional_float
    |> option.map(float.to_string)
    |> option.unwrap("")
  }

  let model =
    init(on_amount_input, on_button_click, on_search_input, on_select)
    |> with_crypto(crypto)
    |> with_fiat(fiat)
    |> with_amount(Left, unwrap_amount(currency_1.amount))
    |> with_amount(Right, unwrap_amount(currency_2.amount))

  let model =
    model
    |> with_selected_currency(Left, option.map(currency_1.id, int.to_string))
    |> result.unwrap(or: model)

  model
  |> with_selected_currency(Right, option.map(currency_2.id, int.to_string))
  |> result.unwrap(or: model)
}

pub fn with_crypto(
  model: Model(msg),
  crypto: List(CryptoCurrency),
) -> Model(msg) {
  let map_currency_input_group = fn(
    currency_input_group: CurrencyInputGroup(msg),
  ) {
    let dropdown_options =
      dict.insert(
        currency_input_group.currency_selector.dropdown_options,
        crypto_group_key,
        list.map(crypto, crypto_dropdown_option),
      )

    CurrencyInputGroup(
      ..currency_input_group,
      currency_selector: ButtonDropdown(
        ..currency_input_group.currency_selector,
        dropdown_options:,
      ),
    )
  }

  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(None, map_currency_input_group)

  Model(..model, crypto:, currency_input_groups:)
}

pub fn with_fiat(model: Model(msg), fiat: List(FiatCurrency)) -> Model(msg) {
  let map_currency_input_group = fn(
    currency_input_group: CurrencyInputGroup(msg),
  ) {
    let dropdown_options =
      dict.insert(
        currency_input_group.currency_selector.dropdown_options,
        fiat_group_key,
        list.map(fiat, fiat_dropdown_option),
      )

    CurrencyInputGroup(
      ..currency_input_group,
      currency_selector: ButtonDropdown(
        ..currency_input_group.currency_selector,
        dropdown_options:,
      ),
    )
  }

  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(None, map_currency_input_group)

  Model(..model, fiat:, currency_input_groups:)
}

pub fn with_amount(model: Model(msg), side: Side, amount: String) -> Model(msg) {
  let assert Ok(re) = regex.from_string("^\\d*\\.?\\d*$")

  let amount = case regex.scan(re, amount) {
    [regex.Match(content, [])] -> content
    [] -> string.slice(amount, 0, string.length(amount) - 1)
    _ -> panic as "this regex should have either 0 or 1 matches"
  }

  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(Some(side), fn(currency_input_group) {
      let amount_input =
        AutoResizeInput(..currency_input_group.amount_input, value: amount)

      CurrencyInputGroup(..currency_input_group, amount_input:)
    })

  Model(..model, currency_input_groups:)
}

pub fn with_amount_width(
  model: Model(msg),
  side: Side,
  width: Int,
) -> Model(msg) {
  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(Some(side), fn(currency_input_group) {
      let amount_input =
        AutoResizeInput(..currency_input_group.amount_input, width: width)

      CurrencyInputGroup(..currency_input_group, amount_input:)
    })

  Model(..model, currency_input_groups:)
}

pub fn with_selected_currency(
  model: Model(msg),
  side: Side,
  currency_id: Option(String),
) -> Result(Model(msg), Nil) {
  let currency_label_result = {
    case currency_id {
      None -> Ok(default_button_dropdown_text)

      Some(selected_val) -> {
        list.find_map(model.crypto, fn(currency) {
          case int.to_string(currency.id) == selected_val {
            True -> Ok(currency.name)
            _ -> Error(Nil)
          }
        })
        |> result.lazy_or(fn() {
          list.find_map(model.fiat, fn(currency) {
            case int.to_string(currency.id) == selected_val {
              True -> Ok(currency.name)
              _ -> Error(Nil)
            }
          })
        })
      }
    }
  }

  use currency_label <- result.try(currency_label_result)

  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(Some(side), fn(currency_input_group) {
      CurrencyInputGroup(
        ..currency_input_group,
        currency_selector: ButtonDropdown(
          ..currency_input_group.currency_selector,
          current_value: currency_id,
          button: Button(
            ..currency_input_group.currency_selector.button,
            text: currency_label,
          ),
        ),
      )
    })

  Ok(Model(..model, currency_input_groups:))
}

pub fn toggle_selector_dropdown(model: Model(msg), side: Side) -> Model(msg) {
  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(Some(side), fn(currency_input_group) {
      CurrencyInputGroup(
        ..currency_input_group,
        currency_selector: ButtonDropdown(
          ..currency_input_group.currency_selector,
          show_dropdown: !currency_input_group.currency_selector.show_dropdown,
        ),
      )
    })

  Model(..model, currency_input_groups:)
}

pub fn filter_currencies(
  model: Model(msg),
  side: Side,
  filter: String,
) -> Model(msg) {
  let is_match = fn(str) {
    str
    |> string.lowercase
    |> string.contains(string.lowercase(filter))
  }

  let filtered_crypto =
    model.crypto
    |> list.filter(fn(currency) {
      is_match(currency.name) || is_match(currency.symbol)
    })
    |> list.map(crypto_dropdown_option)

  let filtered_fiat =
    model.fiat
    |> list.filter(fn(currency) {
      is_match(currency.name) || is_match(currency.symbol)
    })
    |> list.map(fiat_dropdown_option)

  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(Some(side), fn(currency_input_group) {
      let dropdown_options =
        currency_input_group.currency_selector.dropdown_options
        |> dict.insert(crypto_group_key, filtered_crypto)
        |> dict.insert(fiat_group_key, filtered_fiat)

      CurrencyInputGroup(
        ..currency_input_group,
        currency_selector: ButtonDropdown(
          ..currency_input_group.currency_selector,
          filter:,
          dropdown_options:,
        ),
      )
    })

  Model(..model, currency_input_groups:)
}

pub fn to_conversion_params(
  from_side: Side,
  model: Model(msg),
) -> Result(ConversionParameters, Nil) {
  use amount <- result.try(get_amount(model, from_side))
  use currency_1 <- result.try(get_selected_currency_id(model, Left))
  use currency_2 <- result.try(get_selected_currency_id(model, Right))

  let params = case from_side {
    Left -> ConversionParameters(amount, currency_1, currency_2)
    _ -> ConversionParameters(amount, currency_2, currency_1)
  }
  Ok(params)
}

pub fn get_amount(model: Model(msg), side: Side) -> Result(Float, Nil) {
  let to_float = fn(str) {
    str
    |> float.parse
    |> result.lazy_or(fn() {
      int.parse(str)
      |> result.map(int.to_float)
    })
  }
  map_currency_input_group(model, side, fn(group) {
    to_float(group.amount_input.value)
  })
}

pub fn get_amount_input_id(model: Model(msg), side: Side) -> String {
  map_currency_input_group(model, side, fn(group) { group.amount_input.id })
}

pub fn get_search_input_id(model: Model(msg), side: Side) -> String {
  map_currency_input_group(model, side, fn(group) {
    group.currency_selector.search_input_id
  })
}

pub fn get_selected_currency_id(
  model: Model(msg),
  side: Side,
) -> Result(Int, Nil) {
  map_currency_input_group(model, side, fn(group) {
    let id_str = group.currency_selector.current_value
    case id_str {
      Some(str) -> int.parse(str)
      None -> Error(Nil)
    }
  })
}

pub fn map_currency_input_groups(
  currency_input_groups: #(CurrencyInputGroup(msg), CurrencyInputGroup(msg)),
  side: Option(Side),
  fun: fn(CurrencyInputGroup(msg)) -> CurrencyInputGroup(msg),
) -> #(CurrencyInputGroup(msg), CurrencyInputGroup(msg)) {
  let map_pair = case side {
    Some(Left) -> pair.map_first
    Some(Right) -> pair.map_second
    None -> fn(pair, map) {
      pair
      |> pair.map_first(map)
      |> pair.map_second(map)
    }
  }
  map_pair(currency_input_groups, fun)
}

pub fn map_currency_input_group(
  model: Model(msg),
  side: Side,
  fun: fn(CurrencyInputGroup(msg)) -> a,
) -> a {
  let target = case side {
    Left -> model.currency_input_groups.0
    Right -> model.currency_input_groups.1
  }
  fun(target)
}

fn crypto_dropdown_option(currency: CryptoCurrency) -> DropdownOption(msg) {
  let display_element =
    html.div([attribute.class("flex justify-between space-x-2")], [
      html.span([], [html.text(currency.name)]),
      html.span([], [html.text(currency.symbol)]),
    ])

  DropdownOption(int.to_string(currency.id), display_element)
}

fn fiat_dropdown_option(currency: FiatCurrency) -> DropdownOption(msg) {
  let display_element =
    html.div([attribute.class("flex justify-between space-x-2")], [
      html.span([], [html.text(currency.name)]),
      html.span([], [html.text(currency.symbol)]),
    ])

  DropdownOption(int.to_string(currency.id), display_element)
}
