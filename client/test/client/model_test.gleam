import client.{
  UserClickedCurrencySelector, UserFilteredCurrencies, UserSelectedCurrency,
}
import client/button_dropdown.{ButtonDropdown}
import client/model.{
  type CurrencyInputGroup, type Model, type Side, CurrencyInputGroup, Left,
  Model, Right,
}
import gleam/dict
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleeunit
import gleeunit/should
import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency}
import shared/ssr_data.{Currency, SsrData}

pub fn main() {
  gleeunit.main()
}

pub fn model_init_test() {
  let on_button_click = UserClickedCurrencySelector
  let on_search_input = UserFilteredCurrencies
  let on_select = UserSelectedCurrency

  let expected_options =
    dict.from_list([#(model.crypto_group_key, []), #(model.fiat_group_key, [])])

  let expected_default_text = "Select one..."

  model.init(on_button_click, on_search_input, on_select)
  |> should.equal(
    Model([], [], #(
      CurrencyInputGroup(
        None,
        ButtonDropdown(
          Left,
          "btn-dd-1",
          expected_default_text,
          expected_options,
          None,
          False,
          "",
          "btn-dd-1-search",
          on_button_click,
          on_search_input,
          on_select,
        ),
      ),
      CurrencyInputGroup(
        None,
        ButtonDropdown(
          Right,
          "btn-dd-2",
          expected_default_text,
          expected_options,
          None,
          False,
          "",
          "btn-dd-2-search",
          on_button_click,
          on_search_input,
          on_select,
        ),
      ),
    )),
  )
}

pub fn model_from_ssr_data_test() {
  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(None, Some(1)), Currency(Some(1.1), None)),
    )

  let result =
    model.from_ssr_data(
      ssr_data,
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  result.crypto
  |> should.equal(ssr_data.crypto)

  result.fiat
  |> should.equal(ssr_data.fiat)

  let #(
    CurrencyInputGroup(amount_1, currency_selector_1),
    CurrencyInputGroup(amount_2, currency_selector_2),
  ) = result.currency_input_groups

  amount_1
  |> should.equal({ ssr_data.currencies.0 }.amount)

  amount_2
  |> should.equal({ ssr_data.currencies.1 }.amount)

  currency_selector_1.current_value
  |> should.equal({ ssr_data.currencies.0 }.id |> option.map(int.to_string))

  currency_selector_2.current_value
  |> should.equal({ ssr_data.currencies.1 }.id |> option.map(int.to_string))
}

pub fn model_from_ssr_data_left_currency_id_invalid_test() {
  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(Some(1.0), Some(3)), Currency(Some(1.1), Some(2))),
    )

  let result =
    model.from_ssr_data(
      ssr_data,
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  result.crypto
  |> should.equal(ssr_data.crypto)

  result.fiat
  |> should.equal(ssr_data.fiat)

  let #(
    CurrencyInputGroup(amount_1, currency_selector_1),
    CurrencyInputGroup(amount_2, currency_selector_2),
  ) = result.currency_input_groups

  amount_1
  |> should.equal({ ssr_data.currencies.0 }.amount)

  amount_2
  |> should.equal({ ssr_data.currencies.1 }.amount)

  currency_selector_1.current_value
  |> should.be_none

  currency_selector_2.current_value
  |> should.equal({ ssr_data.currencies.1 }.id |> option.map(int.to_string))
}

pub fn model_from_ssr_data_right_currency_id_invalid_test() {
  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(Some(1.0), Some(1)), Currency(Some(1.1), Some(3))),
    )

  let result =
    model.from_ssr_data(
      ssr_data,
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  result.crypto
  |> should.equal(ssr_data.crypto)

  result.fiat
  |> should.equal(ssr_data.fiat)

  let #(
    CurrencyInputGroup(amount_1, currency_selector_1),
    CurrencyInputGroup(amount_2, currency_selector_2),
  ) = result.currency_input_groups

  amount_1
  |> should.equal({ ssr_data.currencies.0 }.amount)

  amount_2
  |> should.equal({ ssr_data.currencies.1 }.amount)

  currency_selector_1.current_value
  |> should.equal({ ssr_data.currencies.0 }.id |> option.map(int.to_string))

  currency_selector_2.current_value
  |> should.be_none
}

pub fn model_with_amount_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let expected_amt = 1.2
  let result =
    initial_model
    |> model.with_amount(Left, Some(expected_amt))

  result
  |> map_currency_input_group(Left, fn(group) { group.amount })
  |> should.be_some
  |> should.equal(expected_amt)

  result.currency_input_groups.1
  |> should.equal(initial_model.currency_input_groups.1)
}

pub fn model_toggle_selector_dropdown_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let initial_show_dd =
    map_currency_input_group(initial_model, Left, fn(group) {
      group.currency_selector.show_dropdown
    })

  let result =
    initial_model
    |> model.toggle_selector_dropdown(Left)

  let new_show_dd =
    map_currency_input_group(result, Left, fn(group) {
      group.currency_selector.show_dropdown
    })

  new_show_dd
  |> should.not_equal(initial_show_dd)

  result.currency_input_groups.1
  |> should.equal(initial_model.currency_input_groups.1)
}

pub fn model_filter_currencies_filter_is_empty_string_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([CryptoCurrency(1, Some(2), "CQ Token", "CQT")])
    |> model.with_fiat([FiatCurrency(2, "United States Dollar", "$", "USD")])

  let result =
    initial_model
    |> model.filter_currencies(Left, "")

  result
  |> should.equal(initial_model)
}

pub fn model_filter_currencies_case_insensitive_test() {
  let result =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([
      CryptoCurrency(1, None, "ABC", ""),
      CryptoCurrency(2, None, "DEF", ""),
    ])
    |> model.filter_currencies(Left, "def")

  result
  |> get_dd_option_values(Left, model.crypto_group_key)
  |> should.equal(["2"])
}

pub fn model_filter_currencies_no_match_test() {
  let result =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([
      CryptoCurrency(1, None, "ABC", ""),
      CryptoCurrency(2, None, "DEF", ""),
    ])
    |> model.filter_currencies(Left, "XYZ")

  get_dd_option_values(result, Left, model.crypto_group_key)
  |> should.equal([])
}

pub fn model_filter_currencies_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([
      CryptoCurrency(1, None, "test str", ""),
      CryptoCurrency(2, None, "another test str", ""),
      CryptoCurrency(3, None, "AAA", ""),
    ])
    |> model.with_fiat([
      FiatCurrency(4, "a test", "", ""),
      FiatCurrency(5, "BBB", "", ""),
      FiatCurrency(6, "test", "", ""),
    ])

  let result =
    initial_model
    |> model.filter_currencies(Left, "test")

  get_dd_option_values(result, Left, model.crypto_group_key)
  |> should.equal(["1", "2"])

  get_dd_option_values(result, Left, model.fiat_group_key)
  |> should.equal(["4", "6"])

  result.currency_input_groups.1
  |> should.equal(initial_model.currency_input_groups.1)

  result.crypto
  |> should.equal(initial_model.crypto)

  result.fiat
  |> should.equal(initial_model.fiat)
}

pub fn model_with_selected_currency_none_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let result =
    initial_model
    |> model.with_selected_currency(Left, None)

  result
  |> should.be_ok
  |> map_currency_input_group(Left, fn(group) {
    group.currency_selector.current_value
  })
  |> should.be_none
}

pub fn model_with_selected_currency_invalid_currency_id_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let result =
    initial_model
    |> model.with_selected_currency(Left, Some("1"))

  result
  |> should.be_error
  |> should.equal(Nil)
}

pub fn model_with_selected_currency_test() {
  let expected_currency_id = 1
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([CryptoCurrency(expected_currency_id, None, "", "")])

  let result =
    initial_model
    |> model.with_selected_currency(
      Left,
      Some(int.to_string(expected_currency_id)),
    )
    |> should.be_ok

  result
  |> map_currency_input_group(Left, fn(group) {
    group.currency_selector.current_value
  })
  |> should.be_some
  |> should.equal(int.to_string(expected_currency_id))

  result.currency_input_groups.1
  |> should.equal(initial_model.currency_input_groups.1)
}

pub fn model_map_currency_input_groups_left_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let expected_btn_txt = "click me"

  let result =
    initial_model.currency_input_groups
    |> model.map_currency_input_groups(Some(Left), fn(group) {
      CurrencyInputGroup(
        ..group,
        currency_selector: ButtonDropdown(
          ..group.currency_selector,
          button_text: expected_btn_txt,
        ),
      )
    })

  { result.0 }.currency_selector.button_text
  |> should.equal(expected_btn_txt)

  { result.1 }.currency_selector.button_text
  |> should.equal(model.default_button_dropdown_text)
}

pub fn model_map_currency_input_groups_right_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let expected_btn_txt = "click me"

  let result =
    initial_model.currency_input_groups
    |> model.map_currency_input_groups(Some(Right), fn(group) {
      CurrencyInputGroup(
        ..group,
        currency_selector: ButtonDropdown(
          ..group.currency_selector,
          button_text: expected_btn_txt,
        ),
      )
    })

  { result.1 }.currency_selector.button_text
  |> should.equal(expected_btn_txt)

  { result.0 }.currency_selector.button_text
  |> should.equal(model.default_button_dropdown_text)
}

pub fn model_map_currency_input_groups_both_sides_test() {
  let initial_model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let expected_btn_txt = "click me"

  let result =
    initial_model.currency_input_groups
    |> model.map_currency_input_groups(None, fn(group) {
      CurrencyInputGroup(
        ..group,
        currency_selector: ButtonDropdown(
          ..group.currency_selector,
          button_text: expected_btn_txt,
        ),
      )
    })

  { result.0 }.currency_selector.button_text
  |> should.equal(expected_btn_txt)

  { result.1 }.currency_selector.button_text
  |> should.equal(expected_btn_txt)
}

fn get_dd_option_values(
  model: Model(msg),
  side: Side,
  group_key: String,
) -> List(String) {
  model
  |> map_currency_input_group(side, fn(group) {
    group.currency_selector.dropdown_options
  })
  |> dict.get(group_key)
  |> result.unwrap([])
  |> list.map(fn(dd_option) { dd_option.value })
}

fn map_currency_input_group(
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
