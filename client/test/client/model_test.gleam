import client/button_dropdown.{ButtonDropdown}
import client/model.{CurrencyInputGroup, Left, Model, Right}
import gleam/dict
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency}
import shared/ssr_data.{Currency, SsrData}

pub fn main() {
  gleeunit.main()
}

pub fn model_init_test() {
  let on_button_click = fn(_) { Nil }
  let on_search_input = fn(_, _) { Nil }
  let on_select = fn(_, _) { Nil }

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
  let on_button_click = fn(_) { Nil }
  let on_search_input = fn(_, _) { Nil }
  let on_select = fn(_, _) { Nil }

  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(None, Some(1)), Currency(Some(1.1), None)),
    )

  let result =
    model.from_ssr_data(ssr_data, on_button_click, on_search_input, on_select)

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
  let on_button_click = fn(_) { Nil }
  let on_search_input = fn(_, _) { Nil }
  let on_select = fn(_, _) { Nil }

  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(Some(1.0), Some(3)), Currency(Some(1.1), Some(2))),
    )

  let result =
    model.from_ssr_data(ssr_data, on_button_click, on_search_input, on_select)

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
  let on_button_click = fn(_) { Nil }
  let on_search_input = fn(_, _) { Nil }
  let on_select = fn(_, _) { Nil }

  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(Some(1.0), Some(1)), Currency(Some(1.1), Some(3))),
    )

  let result =
    model.from_ssr_data(ssr_data, on_button_click, on_search_input, on_select)

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
