import client.{
  UserClickedCurrencySelector, UserFilteredCurrencies, UserSelectedCurrency,
  UserTypedAmount,
}
import client/model.{type Model, Model}
import client/model_utils.{type Side, Left, Right}
import client/models/auto_resize_input.{type AutoResizeInput, AutoResizeInput}
import client/models/button.{Button}
import client/models/button_dropdown.{ButtonDropdown}
import client/models/currency_input_group.{
  type CurrencyInputGroup, CurrencyInputGroup,
}
import gleam/dict
import gleam/float
import gleam/int
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import gleeunit
import gleeunit/should
import shared/coin_market_cap_types.{
  ConversionParameters, CryptoCurrency, FiatCurrency,
}
import shared/ssr_data.{Currency, SsrData}

pub fn main() {
  gleeunit.main()
}

const on_amount_input = UserTypedAmount

const on_button_click = UserClickedCurrencySelector

const on_search_input = UserFilteredCurrencies

const on_select = UserSelectedCurrency

pub fn model_init_currencies_empty_test() {
  let result =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  result.crypto
  |> should.equal([])

  result.fiat
  |> should.equal([])
}

pub fn model_init_amounts_empty_str_test() {
  let result =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let Model(
    _,
    _,
    #(
      CurrencyInputGroup(amount_input_1, _),
      CurrencyInputGroup(amount_input_2, _),
    ),
  ) = result

  amount_input_1.value
  |> should.equal("")

  amount_input_2.value
  |> should.equal("")
}

pub fn model_init_left_amount_input_test() {
  let result =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let Model(_, _, #(CurrencyInputGroup(amount_input, _), _)) = result

  amount_input.id
  |> should.equal("amount-input-1")

  amount_input.value
  |> should.equal("")

  amount_input.width
  |> should.equal(model_utils.default_amount_input_width)

  amount_input.on_input("1.0")
  |> should.equal(UserTypedAmount(Left, "1.0"))
}

pub fn model_init_right_amount_input_test() {
  let result =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let Model(_, _, #(_, CurrencyInputGroup(amount_input, _))) = result

  amount_input.id
  |> should.equal("amount-input-2")

  amount_input.value
  |> should.equal("")

  amount_input.width
  |> should.equal(model_utils.default_amount_input_width)

  amount_input.on_input("1.0")
  |> should.equal(UserTypedAmount(Right, "1.0"))
}

pub fn model_init_left_currency_selector_test() {
  let result =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let Model(_, _, #(CurrencyInputGroup(_, selector_1), _)) = result

  selector_1.id
  |> should.equal("btn-dd-1")

  selector_1.button
  |> should.equal(Button(
    model_utils.default_button_dropdown_text,
    UserClickedCurrencySelector(Left),
  ))

  selector_1.dropdown_options
  |> should.equal(
    dict.from_list([
      #(model_utils.crypto_group_key, []),
      #(model_utils.fiat_group_key, []),
    ]),
  )

  selector_1.show_dropdown
  |> should.be_false

  selector_1.filter
  |> should.equal("")

  selector_1.search_input_id
  |> should.equal("btn-dd-1-search")

  selector_1.on_search_input("hi")
  |> should.equal(UserFilteredCurrencies(Left, "hi"))

  selector_1.on_select("hi")
  |> should.equal(UserSelectedCurrency(Left, "hi"))
}

pub fn model_init_right_currency_selector_test() {
  let result =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let Model(_, _, #(_, CurrencyInputGroup(_, selector_2))) = result

  selector_2.id
  |> should.equal("btn-dd-2")

  selector_2.button
  |> should.equal(Button(
    model_utils.default_button_dropdown_text,
    UserClickedCurrencySelector(Right),
  ))

  selector_2.dropdown_options
  |> should.equal(
    dict.from_list([
      #(model_utils.crypto_group_key, []),
      #(model_utils.fiat_group_key, []),
    ]),
  )

  selector_2.show_dropdown
  |> should.be_false

  selector_2.filter
  |> should.equal("")

  selector_2.search_input_id
  |> should.equal("btn-dd-2-search")

  selector_2.on_search_input("hi")
  |> should.equal(UserFilteredCurrencies(Right, "hi"))

  selector_2.on_select("hi")
  |> should.equal(UserSelectedCurrency(Right, "hi"))
}

pub fn model_from_ssr_data_test() {
  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(None, Some(1)), Currency(Some(1.1), None)),
    )

  let result =
    model_utils.from_ssr_data(
      ssr_data,
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  result.crypto
  |> should.equal(ssr_data.crypto)

  result.fiat
  |> should.equal(ssr_data.fiat)

  let #(
    CurrencyInputGroup(amount_input_1, currency_selector_1),
    CurrencyInputGroup(amount_input_2, currency_selector_2),
  ) = result.currency_input_groups

  amount_input_1.value
  |> should.equal("")

  amount_input_2.value
  |> should.equal("1.1")

  currency_selector_1.current_value
  |> should.be_some
  |> should.equal("1")

  currency_selector_2.current_value
  |> should.be_none
}

pub fn model_from_ssr_data_left_currency_id_invalid_test() {
  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(Some(1.0), Some(3)), Currency(Some(1.1), Some(2))),
    )

  let result =
    model_utils.from_ssr_data(
      ssr_data,
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  result.crypto
  |> should.equal(ssr_data.crypto)

  result.fiat
  |> should.equal(ssr_data.fiat)

  let #(
    CurrencyInputGroup(amount_input_1, currency_selector_1),
    CurrencyInputGroup(amount_input_2, currency_selector_2),
  ) = result.currency_input_groups

  amount_input_1.value
  |> should.equal("1.0")

  amount_input_2.value
  |> should.equal("1.1")

  currency_selector_1.current_value
  |> should.be_none

  currency_selector_2.current_value
  |> should.be_some
  |> should.equal("2")
}

pub fn model_from_ssr_data_right_currency_id_invalid_test() {
  let ssr_data =
    SsrData(
      [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
      [FiatCurrency(2, "United States Dollar", "$", "USD")],
      #(Currency(Some(1.0), Some(1)), Currency(Some(1.1), Some(3))),
    )

  let result =
    model_utils.from_ssr_data(
      ssr_data,
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  result.crypto
  |> should.equal(ssr_data.crypto)

  result.fiat
  |> should.equal(ssr_data.fiat)

  let #(
    CurrencyInputGroup(amount_input_1, currency_selector_1),
    CurrencyInputGroup(amount_input_2, currency_selector_2),
  ) = result.currency_input_groups

  amount_input_1.value
  |> should.equal("1.0")

  amount_input_2.value
  |> should.equal("1.1")

  currency_selector_1.current_value
  |> should.be_some
  |> should.equal("1")

  currency_selector_2.current_value
  |> should.be_none
}

pub fn model_with_amount_only_updates_value_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let before =
    model_utils.map_currency_input_group(model, Left, fn(group) {
      group.amount_input
    })

  let AutoResizeInput(id, _, width, on_input) =
    model
    |> model_utils.with_amount(Left, "1.0")
    |> model_utils.map_currency_input_group(Left, fn(group) {
      group.amount_input
    })

  id
  |> should.equal(before.id)

  width
  |> should.equal(before.width)

  on_input("1.0")
  |> should.equal(UserTypedAmount(Left, "1.0"))
}

pub fn model_with_amount_correctly_parses_value_test() {
  let input_outputs = [
    #("", ""),
    #("+", ""),
    #("-", ""),
    #("a", ""),
    #(".", "."),
    #("0.", "0."),
    #(".0", ".0"),
    #("1.0", "1.0"),
    #("+1a2-3.4!.5", "123.45"),
  ]

  list.each(input_outputs, fn(input_output) {
    let #(input, expected_amount) = input_output
    let input_chars = string.to_graphemes(input)

    let initial_model =
      model_utils.init(
        on_amount_input,
        on_button_click,
        on_search_input,
        on_select,
      )

    let final_model =
      list.fold(input_chars, initial_model, fn(acc, curr) {
        let acc_amount =
          model_utils.map_currency_input_group(acc, Left, fn(group) {
            group.amount_input.value
          })

        model_utils.with_amount(acc, Left, acc_amount <> curr)
      })

    let result =
      final_model
      |> model_utils.map_currency_input_group(Left, fn(group) {
        group.amount_input
      })

    result.value
    |> should.equal(expected_amount)
  })
}

pub fn with_amount_width_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let before =
    model_utils.map_currency_input_group(model, Left, fn(group) {
      group.amount_input
    })

  let AutoResizeInput(id, val, width, on_input) =
    model
    |> model_utils.with_amount_width(Left, 76)
    |> model_utils.map_currency_input_group(Left, fn(group) {
      group.amount_input
    })

  id
  |> should.equal(before.id)

  val
  |> should.equal(before.value)

  width
  |> should.equal(76)

  on_input("1.0")
  |> should.equal(UserTypedAmount(Left, "1.0"))
}

pub fn model_toggle_selector_dropdown_test() {
  let initial_model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let initial_show_dd =
    model_utils.map_currency_input_group(initial_model, Left, fn(group) {
      group.currency_selector.show_dropdown
    })

  let result =
    initial_model
    |> model_utils.toggle_selector_dropdown(Left)

  let new_show_dd =
    model_utils.map_currency_input_group(result, Left, fn(group) {
      group.currency_selector.show_dropdown
    })

  new_show_dd
  |> should.not_equal(initial_show_dd)

  result.currency_input_groups.1
  |> should.equal(initial_model.currency_input_groups.1)
}

pub fn model_filter_currencies_filter_is_empty_string_test() {
  let initial_model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([CryptoCurrency(1, Some(2), "CQ Token", "CQT")])
    |> model_utils.with_fiat([
      FiatCurrency(2, "United States Dollar", "$", "USD"),
    ])

  let result =
    initial_model
    |> model_utils.filter_currencies(Left, "")

  result
  |> should.equal(initial_model)
}

pub fn model_filter_currencies_case_insensitive_test() {
  let result =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([
      CryptoCurrency(1, None, "ABC", ""),
      CryptoCurrency(2, None, "DEF", ""),
    ])
    |> model_utils.filter_currencies(Left, "def")

  result
  |> get_dd_option_values(Left, model_utils.crypto_group_key)
  |> should.equal(["2"])
}

pub fn model_filter_currencies_no_match_test() {
  let result =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([
      CryptoCurrency(1, None, "ABC", ""),
      CryptoCurrency(2, None, "DEF", ""),
    ])
    |> model_utils.filter_currencies(Left, "XYZ")

  get_dd_option_values(result, Left, model_utils.crypto_group_key)
  |> should.equal([])
}

pub fn model_filter_currencies_test() {
  let initial_model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([
      CryptoCurrency(1, None, "test str", ""),
      CryptoCurrency(2, None, "another test str", ""),
      CryptoCurrency(3, None, "AAA", ""),
    ])
    |> model_utils.with_fiat([
      FiatCurrency(4, "a test", "", ""),
      FiatCurrency(5, "BBB", "", ""),
      FiatCurrency(6, "test", "", ""),
    ])

  let result =
    initial_model
    |> model_utils.filter_currencies(Left, "test")

  get_dd_option_values(result, Left, model_utils.crypto_group_key)
  |> should.equal(["1", "2"])

  get_dd_option_values(result, Left, model_utils.fiat_group_key)
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
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let result =
    initial_model
    |> model_utils.with_selected_currency(Left, None)

  result
  |> should.be_ok
  |> model_utils.map_currency_input_group(Left, fn(group) {
    group.currency_selector.current_value
  })
  |> should.be_none
}

pub fn model_with_selected_currency_invalid_currency_id_test() {
  let initial_model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let result =
    initial_model
    |> model_utils.with_selected_currency(Left, Some("1"))

  result
  |> should.be_error
  |> should.equal(Nil)
}

pub fn model_with_selected_currency_test() {
  let expected_currency_id = 1
  let initial_model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([
      CryptoCurrency(expected_currency_id, None, "", ""),
    ])

  let result =
    initial_model
    |> model_utils.with_selected_currency(
      Left,
      Some(int.to_string(expected_currency_id)),
    )
    |> should.be_ok

  result
  |> model_utils.map_currency_input_group(Left, fn(group) {
    group.currency_selector.current_value
  })
  |> should.be_some
  |> should.equal(int.to_string(expected_currency_id))

  result.currency_input_groups.1
  |> should.equal(initial_model.currency_input_groups.1)
}

pub fn model_map_currency_input_groups_left_test() {
  let initial_model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let expected_btn_txt = "click me"

  let result =
    initial_model.currency_input_groups
    |> model_utils.map_currency_input_groups(Some(Left), fn(group) {
      CurrencyInputGroup(
        ..group,
        currency_selector: ButtonDropdown(
          ..group.currency_selector,
          button: Button(
            ..group.currency_selector.button,
            text: expected_btn_txt,
          ),
        ),
      )
    })

  { result.0 }.currency_selector.button.text
  |> should.equal(expected_btn_txt)

  { result.1 }.currency_selector.button.text
  |> should.equal(model_utils.default_button_dropdown_text)
}

pub fn model_map_currency_input_groups_right_test() {
  let initial_model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let expected_btn_txt = "click me"

  let result =
    initial_model.currency_input_groups
    |> model_utils.map_currency_input_groups(Some(Right), fn(group) {
      CurrencyInputGroup(
        ..group,
        currency_selector: ButtonDropdown(
          ..group.currency_selector,
          button: Button(
            ..group.currency_selector.button,
            text: expected_btn_txt,
          ),
        ),
      )
    })

  { result.1 }.currency_selector.button.text
  |> should.equal(expected_btn_txt)

  { result.0 }.currency_selector.button.text
  |> should.equal(model_utils.default_button_dropdown_text)
}

pub fn model_map_currency_input_groups_both_sides_test() {
  let initial_model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let expected_btn_txt = "click me"

  let result =
    initial_model.currency_input_groups
    |> model_utils.map_currency_input_groups(None, fn(group) {
      CurrencyInputGroup(
        ..group,
        currency_selector: ButtonDropdown(
          ..group.currency_selector,
          button: Button(
            ..group.currency_selector.button,
            text: expected_btn_txt,
          ),
        ),
      )
    })

  { result.0 }.currency_selector.button.text
  |> should.equal(expected_btn_txt)

  { result.1 }.currency_selector.button.text
  |> should.equal(expected_btn_txt)
}

pub fn model_to_conversion_params_invalid_amount_test() {
  let expected_currency_id_1 = 1
  let expected_currency_id_2 = 2

  let assert Ok(model) =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_amount(Left, ".")
    |> model_utils.with_crypto([
      CryptoCurrency(expected_currency_id_1, None, "", ""),
      CryptoCurrency(expected_currency_id_2, None, "", ""),
    ])
    |> model_utils.with_selected_currency(
      Left,
      Some(int.to_string(expected_currency_id_1)),
    )

  let assert Ok(model) =
    model_utils.with_selected_currency(
      model,
      Right,
      Some(int.to_string(expected_currency_id_2)),
    )

  model
  |> model_utils.to_conversion_params(Left, _)
  |> should.be_error
  |> should.equal(Nil)
}

pub fn model_to_conversion_params_invalid_left_currency_test() {
  let expected_currency_id_2 = 2

  let assert Ok(model) =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_amount(Left, float.to_string(1.0))
    |> model_utils.with_crypto([
      CryptoCurrency(1, None, "", ""),
      CryptoCurrency(expected_currency_id_2, None, "", ""),
    ])
    |> model_utils.with_selected_currency(
      Right,
      Some(int.to_string(expected_currency_id_2)),
    )

  model
  |> model_utils.to_conversion_params(Left, _)
  |> should.be_error
  |> should.equal(Nil)
}

pub fn model_to_conversion_params_invalid_right_currency_test() {
  let expected_currency_id_1 = 1

  let assert Ok(model) =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_amount(Left, float.to_string(1.0))
    |> model_utils.with_crypto([
      CryptoCurrency(expected_currency_id_1, None, "", ""),
      CryptoCurrency(2, None, "", ""),
    ])
    |> model_utils.with_selected_currency(
      Left,
      Some(int.to_string(expected_currency_id_1)),
    )

  model
  |> model_utils.to_conversion_params(Left, _)
  |> should.be_error
  |> should.equal(Nil)
}

pub fn model_to_conversion_params_from_left_happy_path_test() {
  let expected_amount = 1.0
  let expected_currency_id_1 = 1
  let expected_currency_id_2 = 2

  let assert Ok(model) =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_amount(Left, float.to_string(expected_amount))
    |> model_utils.with_crypto([
      CryptoCurrency(expected_currency_id_1, None, "", ""),
      CryptoCurrency(expected_currency_id_2, None, "", ""),
    ])
    |> model_utils.with_selected_currency(
      Left,
      Some(int.to_string(expected_currency_id_1)),
    )

  let assert Ok(model) =
    model_utils.with_selected_currency(
      model,
      Right,
      Some(int.to_string(expected_currency_id_2)),
    )

  model
  |> model_utils.to_conversion_params(Left, _)
  |> should.be_ok
  |> should.equal(ConversionParameters(
    expected_amount,
    expected_currency_id_1,
    expected_currency_id_2,
  ))
}

pub fn model_to_conversion_params_from_right_happy_path_test() {
  let expected_amount = 1.0
  let expected_currency_id_1 = 1
  let expected_currency_id_2 = 2

  let assert Ok(model) =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_amount(Left, float.to_string(2.0))
    |> model_utils.with_amount(Right, float.to_string(expected_amount))
    |> model_utils.with_crypto([
      CryptoCurrency(expected_currency_id_1, None, "", ""),
      CryptoCurrency(expected_currency_id_2, None, "", ""),
    ])
    |> model_utils.with_selected_currency(
      Left,
      Some(int.to_string(expected_currency_id_1)),
    )

  let assert Ok(model) =
    model_utils.with_selected_currency(
      model,
      Right,
      Some(int.to_string(expected_currency_id_2)),
    )

  model
  |> model_utils.to_conversion_params(Right, _)
  |> should.be_ok
  |> should.equal(ConversionParameters(
    expected_amount,
    expected_currency_id_2,
    expected_currency_id_1,
  ))
}

fn get_dd_option_values(
  model: Model(msg),
  side: Side,
  group_key: String,
) -> List(String) {
  model
  |> model_utils.map_currency_input_group(side, fn(group) {
    group.currency_selector.dropdown_options
  })
  |> dict.get(group_key)
  |> result.unwrap([])
  |> list.map(fn(dd_option) { dd_option.value })
}
