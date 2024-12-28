import client/button_dropdown.{
  type ButtonDropdown, type DropdownOption, ButtonDropdown, DropdownOption,
}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/pair
import gleam/result
import gleam/string
import shared/coin_market_cap_types.{type CryptoCurrency, type FiatCurrency}
import shared/ssr_data.{type SsrData, SsrData}

pub const crypto_group_key = "Crypto"

pub const fiat_group_key = "Fiat"

pub type Model(msg) {
  Model(
    crypto: List(CryptoCurrency),
    fiat: List(FiatCurrency),
    currency_input_groups: #(CurrencyInputGroup(msg), CurrencyInputGroup(msg)),
  )
}

pub type CurrencyInputGroup(msg) {
  CurrencyInputGroup(
    amount: Option(Float),
    currency_selector: ButtonDropdown(msg, Side),
  )
}

pub type Side {
  Left
  Right
}

pub fn init(
  on_button_click: fn(Side) -> msg,
  on_search_input: fn(Side, String) -> msg,
  on_select: fn(Side, String) -> msg,
) -> Model(msg) {
  let btn_dd_1 =
    ButtonDropdown(
      ctx: Left,
      id: "btn-dd-1",
      button_text: "Select one...",
      dropdown_options: dict.from_list([
        #(crypto_group_key, []),
        #(fiat_group_key, []),
      ]),
      current_value: None,
      show_dropdown: False,
      filter: "",
      search_input_id: "btn-dd-1-search",
      on_button_click:,
      on_search_input:,
      on_select:,
    )

  let currency_input_group_1 =
    CurrencyInputGroup(amount: None, currency_selector: btn_dd_1)

  let currency_input_group_2 =
    CurrencyInputGroup(
      amount: None,
      currency_selector: ButtonDropdown(
        ..btn_dd_1,
        ctx: Right,
        id: "btn-dd-2",
        search_input_id: "btn-dd-2-search",
      ),
    )

  Model([], [], #(currency_input_group_1, currency_input_group_2))
}

pub fn from_ssr_data(
  ssr_data: SsrData,
  on_button_click: fn(Side) -> msg,
  on_search_input: fn(Side, String) -> msg,
  on_select: fn(Side, String) -> msg,
) -> Model(msg) {
  let SsrData(crypto, fiat, #(currency_1, currency_2)) = ssr_data

  let model =
    init(on_button_click, on_search_input, on_select)
    |> with_crypto(crypto)
    |> with_fiat(fiat)
    |> with_amount(Left, currency_1.amount)
    |> with_amount(Right, currency_2.amount)

  model
  |> with_selected_currency(Left, option.map(currency_1.id, int.to_string))
  |> result.try(with_selected_currency(
    _,
    Right,
    option.map(currency_2.id, int.to_string),
  ))
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
    |> list.filter(fn(currency) { currency.name |> is_match })
    |> list.map(crypto_dropdown_option)

  let filtered_fiat =
    model.fiat
    |> list.filter(fn(currency) { currency.name |> is_match })
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

pub fn with_amount(model: Model(msg), side: Side, optional_val: Option(Float)) {
  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(Some(side), fn(currency_input_group) {
      CurrencyInputGroup(..currency_input_group, amount: optional_val)
    })

  Model(..model, currency_input_groups:)
}

pub fn with_selected_currency(
  model: Model(msg),
  side: Side,
  optional_val: Option(String),
) -> Result(Model(msg), Nil) {
  let selected_val = option.unwrap(optional_val, "0")

  let currency_label_result = {
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

  use currency_label <- result.try(currency_label_result)

  let currency_input_groups =
    model.currency_input_groups
    |> map_currency_input_groups(Some(side), fn(currency_input_group) {
      CurrencyInputGroup(
        ..currency_input_group,
        currency_selector: ButtonDropdown(
          ..currency_input_group.currency_selector,
          current_value: optional_val,
          button_text: currency_label,
        ),
      )
    })

  Ok(Model(..model, currency_input_groups:))
}

pub fn map_currency_input_groups(
  currency_input_groups: #(CurrencyInputGroup(msg), CurrencyInputGroup(msg)),
  side: Option(Side),
  map: fn(CurrencyInputGroup(msg)) -> CurrencyInputGroup(msg),
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
  map_pair(currency_input_groups, map)
}

fn crypto_dropdown_option(currency: CryptoCurrency) -> DropdownOption {
  DropdownOption(int.to_string(currency.id), currency.name)
}

fn fiat_dropdown_option(currency: FiatCurrency) -> DropdownOption {
  DropdownOption(int.to_string(currency.id), currency.name)
}
