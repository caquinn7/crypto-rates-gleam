import client.{
  ApiReturnedConversion, ApiReturnedCrypto, ApiReturnedFiat,
  UserClickedCurrencySelector, UserFilteredCurrencies, UserSelectedCurrency,
  UserTypedAmount,
}
import gleam/result

// import client/api
import client/model.{Left, Right}
import gleam/float
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import lustre/effect
import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency}
import shared/conversion_response.{ConversionResponse, Currency}

// currently unable to test scenarios
// where functions from client/api module are called
// due to error "ReferenceError: window is not defined".
// seems to be an issue with the lustre_http library.

pub fn main() {
  gleeunit.main()
}

// pub fn client_init_crypto_empty_test() {
//   let model =
//     model.init(
//       UserClickedCurrencySelector,
//       UserFilteredCurrencies,
//       UserSelectedCurrency,
//     )
//     |> model.with_fiat([FiatCurrency(2, "", "", "")])

//   model
//   |> client.init
//   |> should.equal(#(model, api.get_crypto(ApiReturnedCrypto)))
// }

pub fn client_init_currencies_not_empty_test() {
  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([CryptoCurrency(1, None, "", "")])
    |> model.with_fiat([FiatCurrency(2, "", "", "")])

  model
  |> client.init
  |> should.equal(#(model, effect.none()))
}

pub fn client_update_api_returned_crypto_ok_test() {
  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let expected_crypto = [CryptoCurrency(1, None, "", "")]

  model
  |> client.update(ApiReturnedCrypto(Ok(expected_crypto)))
  |> should.equal(#(model.with_crypto(model, expected_crypto), effect.none()))
}

// pub fn client_update_api_returned_crypto_error_test() {
//   todo
// }

pub fn client_update_api_returned_fiat_ok_test() {
  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  let expected_fiat = [FiatCurrency(1, "", "", "")]

  model
  |> client.update(ApiReturnedFiat(Ok(expected_fiat)))
  |> should.equal(#(model.with_fiat(model, expected_fiat), effect.none()))
}

// pub fn client_update_api_returned_fiat_error_test() {
//   todo
// }

pub fn client_update_api_returned_conversion_ok_left_to_right_test() {
  let expected_from_currency = Currency(1, 1.0)
  let expected_to_currency = Currency(2, 2.0)

  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([
      CryptoCurrency(expected_from_currency.id, None, "", ""),
      CryptoCurrency(expected_to_currency.id, None, "", ""),
    ])
    |> model.with_amount(Left, float.to_string(expected_from_currency.amount))

  let assert Ok(model) =
    model.with_selected_currency(
      model,
      Left,
      Some(int.to_string(expected_from_currency.id)),
    )
  let assert Ok(model) =
    model.with_selected_currency(
      model,
      Right,
      Some(int.to_string(expected_to_currency.id)),
    )

  let conversion_response =
    ConversionResponse(expected_from_currency, expected_to_currency)

  model
  |> client.update(ApiReturnedConversion(Ok(conversion_response)))
  |> should.equal(#(
    model.with_amount(
      model,
      Right,
      float.to_string(expected_to_currency.amount),
    ),
    effect.none(),
  ))
}

pub fn client_update_api_returned_conversion_ok_right_to_left_test() {
  let expected_from_currency = Currency(1, 1.0)
  let expected_to_currency = Currency(2, 2.0)

  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([
      CryptoCurrency(expected_from_currency.id, None, "", ""),
      CryptoCurrency(expected_to_currency.id, None, "", ""),
    ])
    |> model.with_amount(Right, float.to_string(expected_from_currency.amount))

  let assert Ok(model) =
    model.with_selected_currency(
      model,
      Left,
      Some(int.to_string(expected_to_currency.id)),
    )
  let assert Ok(model) =
    model.with_selected_currency(
      model,
      Right,
      Some(int.to_string(expected_from_currency.id)),
    )

  let conversion_response =
    ConversionResponse(expected_from_currency, expected_to_currency)

  model
  |> client.update(ApiReturnedConversion(Ok(conversion_response)))
  |> should.equal(#(
    model.with_amount(model, Left, float.to_string(expected_to_currency.amount)),
    effect.none(),
  ))
}

// pub fn client_update_api_returned_conversion_error_test() {
//   todo
// }

pub fn client_update_user_typed_amount_left_invalid_amount_test() {
  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_amount(Left, "1.0")
    |> model.with_amount(Right, "2.0")

  let typed_input = "."
  let expected_model =
    model
    |> model.with_amount(Left, typed_input)
    |> model.with_amount(Right, "")

  model
  |> client.update(UserTypedAmount(Left, typed_input))
  |> should.equal(#(expected_model, effect.none()))
}

pub fn client_update_user_typed_amount_right_invalid_amount_test() {
  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_amount(Left, "1.0")
    |> model.with_amount(Right, "2.0")

  let typed_input = "."
  let expected_model =
    model
    |> model.with_amount(Left, "")
    |> model.with_amount(Right, typed_input)

  model
  |> client.update(UserTypedAmount(Right, typed_input))
  |> should.equal(#(expected_model, effect.none()))
}

// pub fn client_update_user_typed_amount_valid_amount_test() {
//   let model =
//     model.init(
//       UserClickedCurrencySelector,
//       UserFilteredCurrencies,
//       UserSelectedCurrency,
//     )
//     |> model.with_crypto([
//       CryptoCurrency(1, None, "", ""),
//       CryptoCurrency(2, None, "", ""),
//     ])
//     |> model.with_amount(Left, "1.0")

//   let assert Ok(model) =
//     model.with_selected_currency(model, Left, Some(int.to_string(1)))
//   let assert Ok(model) =
//     model.with_selected_currency(model, Right, Some(int.to_string(2)))

//   let expected_model = model.with_amount(model, Right, "2.0")

//   let assert Ok(conversion_params) =
//     model.to_conversion_params(expected_model, Right)
//   let expected_effect =
//     api.get_conversion(conversion_params, ApiReturnedConversion)

//   model
//   |> client.update(UserTypedAmount(Right, "2.0"))
//   |> should.equal(#(expected_model, expected_effect))
// }

pub fn client_update_user_clicked_currency_selector_not_currently_visible_test() {
  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )

  model
  |> model.map_currency_input_group(Left, fn(group) {
    group.currency_selector.show_dropdown
  })
  |> should.be_false

  let #(result_model, result_effect) =
    model
    |> client.update(UserClickedCurrencySelector(Left))

  result_model
  |> should.equal(
    model
    |> model.toggle_selector_dropdown(Left)
    |> model.filter_currencies(Left, ""),
  )

  result_effect
  |> should.not_equal(effect.none())
}

pub fn client_update_user_clicked_currency_selector_currently_visible_test() {
  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.toggle_selector_dropdown(Left)
    |> model.filter_currencies(Left, "filter")

  model
  |> model.map_currency_input_group(Left, fn(group) {
    group.currency_selector.show_dropdown
  })
  |> should.be_true

  let #(result_model, result_effect) =
    model
    |> client.update(UserClickedCurrencySelector(Left))

  result_model
  |> should.equal(
    model
    |> model.toggle_selector_dropdown(Left)
    |> model.filter_currencies(Left, ""),
  )

  result_effect
  |> should.equal(effect.none())
}

pub fn client_update_user_filtered_currencies_test() {
  let model =
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

  let filter = "test"
  model
  |> client.update(UserFilteredCurrencies(Left, filter))
  |> should.equal(#(model.filter_currencies(model, Left, filter), effect.none()))
}

pub fn client_update_user_selected_currency_expected_model_test() {
  let model =
    model.init(
      UserClickedCurrencySelector,
      UserFilteredCurrencies,
      UserSelectedCurrency,
    )
    |> model.with_crypto([
      CryptoCurrency(1, None, "", ""),
      CryptoCurrency(2, None, "", ""),
    ])

  let expected_model =
    model
    |> model.with_selected_currency(Left, Some("1"))
    |> result.unwrap(or: model)
    |> model.toggle_selector_dropdown(Left)
    |> model.filter_currencies(Left, "")

  model
  |> client.update(UserSelectedCurrency(Left, "1"))
  |> should.equal(#(expected_model, effect.none()))
}
// pub fn client_update_user_selected_currency_get_conversion_effect_test() {
//   todo
// }
