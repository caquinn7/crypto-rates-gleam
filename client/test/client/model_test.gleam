// // import birdie
// // import client/button_dropdown.{ButtonDropdown}
// import client/model

// // import gleam/dict
// // import gleam/option.{None, Some}
// import gleeunit
// import gleeunit/should

// // import gleeunit/should
// // import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency}
// // import shared/ssr_data.{Currency, SsrData}

// pub fn main() {
//   gleeunit.main()
// }

// pub fn model_init_test() {
//   let on_button_click = fn(_) { 1 }
//   let on_search_input = fn(_, _) { 2 }
//   let on_select = fn(_, _) { 3 }

//   1 |> should.equal(1)
//   // model.init(on_button_click, on_search_input, on_select)
//   // |> should.equal(
//   //   Model([], [], #(
//   //     model.CurrencyInputGroup(
//   //       None,
//   //       ButtonDropdown(
//   //         Left,
//   //         "btn-dd-1",
//   //         "Select one...",
//   //         dict.from_list([
//   //           #(model.crypto_group_key, []),
//   //           #(model.fiat_group_key, []),
//   //         ]),
//   //         None,
//   //         False,
//   //         "",
//   //         "btn-dd-1-search",
//   //         on_button_click,
//   //         on_search_input,
//   //         on_select,
//   //       ),
//   //     ),
//   //     model.CurrencyInputGroup(
//   //       None,
//   //       ButtonDropdown(
//   //         Left,
//   //         "btn-dd-2",
//   //         "Select one...",
//   //         dict.from_list([
//   //           #(model.crypto_group_key, []),
//   //           #(model.fiat_group_key, []),
//   //         ]),
//   //         None,
//   //         False,
//   //         "",
//   //         "btn-dd-2-search",
//   //         on_button_click,
//   //         on_search_input,
//   //         on_select,
//   //       ),
//   //     ),
//   //   )),
//   // )
// }
// // pub fn model_from_ssr_data_test() {
// //   let on_button_click = fn(side) { 1 }
// //   let on_search_input = fn(side, str) { 2 }
// //   let on_select = fn(side, str) { 3 }
// //   let ssr_data =
// //     SsrData(
// //       [CryptoCurrency(1, Some(2), "CQ Token", "CQT")],
// //       [FiatCurrency(2, "United States Dollar", "$", "USD")],
// //       #(Currency(None, Some(1)), Currency(Some(1.1), None)),
// //     )

// //   ssr_data
// //   |> model.from_ssr_data(on_button_click, on_search_input, on_select)
// //   |> should.equal(
// //     Model(ssr_data.crypto, ssr_data.fiat, )
// //   )
// // }
