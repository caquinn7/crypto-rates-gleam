import client.{
  ApiReturnedConversion, ApiReturnedCrypto, ApiReturnedFiat,
  UserClickedCurrencySelector, UserFilteredCurrencies, UserSelectedCurrency,
  UserTypedAmount,
}
import gleam/result

// import client/api
import client/model_utils.{Left, Right}
import gleam/float
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import lustre/effect
import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency}
import shared/conversion_response.{ConversionResponse, Currency}

const on_amount_input = UserTypedAmount

const on_button_click = UserClickedCurrencySelector

const on_search_input = UserFilteredCurrencies

const on_select = UserSelectedCurrency

// currently unable to test scenarios
// where functions from client/api module are called
// due to error "ReferenceError: window is not defined".
// seems to be an issue with the lustre_http library.

// also need to figure out how to assert on effects that are not effect.none() in general

pub fn main() {
  gleeunit.main()
}

// pub fn client_init_crypto_empty_test() {
//   let model =
//     model_utils.init(on_button_click, on_search_input, on_select)
//     |> model_utils.with_fiat([FiatCurrency(2, "", "", "")])

//   model
//   |> client.init
//   |> should.equal(#(model, api.get_crypto(ApiReturnedCrypto)))
// }

pub fn client_init_currencies_not_empty_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([CryptoCurrency(1, None, "", "")])
    |> model_utils.with_fiat([FiatCurrency(2, "", "", "")])

  let #(result_model, result_effect) =
    model
    |> client.init

  result_model
  |> should.equal(model)

  result_effect
  |> should.not_equal(effect.none())
}

pub fn client_update_api_returned_crypto_ok_test() {
  let expected_crypto = [CryptoCurrency(1, None, "", "")]

  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  model
  |> client.update(ApiReturnedCrypto(Ok(expected_crypto)))
  |> should.equal(#(
    model_utils.with_crypto(model, expected_crypto),
    effect.none(),
  ))
}

// pub fn client_update_api_returned_crypto_error_test() {
//   todo
// }

pub fn client_update_api_returned_fiat_ok_test() {
  let expected_fiat = [FiatCurrency(1, "", "", "")]

  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  model
  |> client.update(ApiReturnedFiat(Ok(expected_fiat)))
  |> should.equal(#(model_utils.with_fiat(model, expected_fiat), effect.none()))
}

// pub fn client_update_api_returned_fiat_error_test() {
//   todo
// }

pub fn client_update_api_returned_conversion_ok_left_to_right_test() {
  let expected_from_currency = Currency(1, 1.0)
  let expected_to_currency = Currency(2, 2.0)

  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([
      CryptoCurrency(expected_from_currency.id, None, "", ""),
      CryptoCurrency(expected_to_currency.id, None, "", ""),
    ])
    |> model_utils.with_amount(
      Left,
      float.to_string(expected_from_currency.amount),
    )

  let assert Ok(model) =
    model_utils.with_selected_currency(
      model,
      Left,
      Some(int.to_string(expected_from_currency.id)),
    )

  let assert Ok(model) =
    model_utils.with_selected_currency(
      model,
      Right,
      Some(int.to_string(expected_to_currency.id)),
    )

  let conversion_response =
    ConversionResponse(expected_from_currency, expected_to_currency)

  let #(result_model, result_effect) =
    model
    |> client.update(ApiReturnedConversion(Ok(conversion_response)))

  result_model
  |> should.equal(model_utils.with_amount(
    model,
    Right,
    float.to_string(expected_to_currency.amount),
  ))

  result_effect
  |> should.not_equal(effect.none())
}

pub fn client_update_api_returned_conversion_ok_right_to_left_test() {
  let expected_from_currency = Currency(1, 1.0)
  let expected_to_currency = Currency(2, 2.0)
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([
      CryptoCurrency(expected_from_currency.id, None, "", ""),
      CryptoCurrency(expected_to_currency.id, None, "", ""),
    ])
    |> model_utils.with_amount(
      Right,
      float.to_string(expected_from_currency.amount),
    )

  let assert Ok(model) =
    model_utils.with_selected_currency(
      model,
      Left,
      Some(int.to_string(expected_to_currency.id)),
    )

  let assert Ok(model) =
    model_utils.with_selected_currency(
      model,
      Right,
      Some(int.to_string(expected_from_currency.id)),
    )

  let conversion_response =
    ConversionResponse(expected_from_currency, expected_to_currency)

  let #(result_model, result_effect) =
    model
    |> client.update(ApiReturnedConversion(Ok(conversion_response)))

  result_model
  |> should.equal(model_utils.with_amount(
    model,
    Left,
    float.to_string(expected_to_currency.amount),
  ))

  result_effect
  |> should.not_equal(effect.none())
}

pub fn client_update_user_typed_amount_left_invalid_amount_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_amount(Left, "1.0")
    |> model_utils.with_amount(Right, "2.0")

  let typed_input = "."
  let expected_model =
    model
    |> model_utils.with_amount(Left, typed_input)
    |> model_utils.with_amount(Right, "")

  let #(result_model, result_effect) =
    model
    |> client.update(UserTypedAmount(Left, typed_input))

  result_model
  |> should.equal(expected_model)

  result_effect
  |> should.not_equal(effect.none())
}

pub fn client_update_user_typed_amount_right_invalid_amount_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_amount(Left, "1.0")
    |> model_utils.with_amount(Right, "2.0")

  let typed_input = "."
  let expected_model =
    model
    |> model_utils.with_amount(Left, "")
    |> model_utils.with_amount(Right, typed_input)

  let #(result_model, result_effect) =
    model
    |> client.update(UserTypedAmount(Right, typed_input))

  result_model
  |> should.equal(expected_model)

  result_effect
  |> should.not_equal(effect.none())
}

pub fn client_update_user_typed_amount_error_getting_conversion_params_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  let typed_input = "1"
  let expected_model =
    model
    |> model_utils.with_amount(Left, typed_input)

  let #(result_model, result_effect) =
    model
    |> client.update(UserTypedAmount(Left, typed_input))

  result_model
  |> should.equal(expected_model)

  result_effect
  |> should.not_equal(effect.none())
}

// pub fn client_update_user_typed_amount_gets_conversion_params_test() {
//   todo
// }

pub fn client_update_user_resized_amount_input_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  model
  |> client.update(client.UserResizedAmountInput(Left, 100))
  |> should.equal(#(
    model_utils.with_amount_width(model, Left, 100),
    effect.none(),
  ))
}

pub fn client_update_user_clicked_currency_selector_not_currently_visible_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )

  model
  |> model_utils.map_currency_input_group(Left, fn(group) {
    group.currency_selector.show_dropdown
  })
  |> should.be_false

  let #(result_model, result_effect) =
    model
    |> client.update(UserClickedCurrencySelector(Left))

  result_model
  |> should.equal(
    model
    |> model_utils.toggle_selector_dropdown(Left)
    |> model_utils.filter_currencies(Left, ""),
  )

  result_effect
  |> should.not_equal(effect.none())
}

pub fn client_update_user_clicked_currency_selector_currently_visible_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.toggle_selector_dropdown(Left)
    |> model_utils.filter_currencies(Left, "filter")

  model
  |> model_utils.map_currency_input_group(Left, fn(group) {
    group.currency_selector.show_dropdown
  })
  |> should.be_true

  let #(result_model, result_effect) =
    model
    |> client.update(UserClickedCurrencySelector(Left))

  result_model
  |> should.equal(
    model
    |> model_utils.toggle_selector_dropdown(Left)
    |> model_utils.filter_currencies(Left, ""),
  )

  result_effect
  |> should.equal(effect.none())
}

pub fn client_update_user_filtered_currencies_test() {
  let model =
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

  let filter = "test"
  model
  |> client.update(UserFilteredCurrencies(Left, filter))
  |> should.equal(#(
    model_utils.filter_currencies(model, Left, filter),
    effect.none(),
  ))
}

pub fn client_update_user_selected_currency_expected_model_test() {
  let model =
    model_utils.init(
      on_amount_input,
      on_button_click,
      on_search_input,
      on_select,
    )
    |> model_utils.with_crypto([
      CryptoCurrency(1, None, "", ""),
      CryptoCurrency(2, None, "", ""),
    ])

  let expected_model =
    model
    |> model_utils.with_selected_currency(Left, Some("1"))
    |> result.unwrap(or: model)
    |> model_utils.toggle_selector_dropdown(Left)
    |> model_utils.filter_currencies(Left, "")

  model
  |> client.update(UserSelectedCurrency(Left, "1"))
  |> should.equal(#(expected_model, effect.none()))
}
// pub fn client_update_user_selected_currency_get_conversion_effect_test() {
//   todo
// }
