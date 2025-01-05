import gleam/dict
import gleam/httpc
import gleam/int
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import server/coin_market_cap.{
  CmcListResponse, CmcResponse, Conversion, HttpError, QuoteItem, Status,
}
import server/routes/home/ssr_data as server_ssr_data
import shared/coin_market_cap_types.{CryptoCurrency, FiatCurrency}
import shared/ssr_data.{Currency, SsrData}

const btc = CryptoCurrency(1, None, "", "BTC")

const usd = FiatCurrency(2, "", "", "USD")

const from_amount = 1.0

const expected_to_amount = 100_000.0

const ok_cmc_status = Status(0, None)

pub fn main() {
  gleeunit.main()
}

pub fn ssr_data_get_error_getting_crypto_test() {
  let request_crypto = fn(_) { Error(HttpError(httpc.InvalidUtf8Response)) }
  let request_fiat = fn(_) { Ok(CmcListResponse(ok_cmc_status, Some([usd]))) }

  server_ssr_data.get(
    request_crypto,
    request_fiat,
    request_ok_conversion,
    btc.symbol,
    usd.symbol,
  )
  |> should.be_error
  |> should.equal(Nil)
}

pub fn ssr_data_get_error_getting_fiat_test() {
  let request_crypto = fn(_) { Ok(CmcListResponse(ok_cmc_status, Some([btc]))) }
  let request_fiat = fn(_) { Error(HttpError(httpc.InvalidUtf8Response)) }

  server_ssr_data.get(
    request_crypto,
    request_fiat,
    request_ok_conversion,
    btc.symbol,
    usd.symbol,
  )
  |> should.be_error
  |> should.equal(Nil)
}

pub fn ssr_data_get_error_getting_conversion_test() {
  let request_crypto = fn(_) { Ok(CmcListResponse(ok_cmc_status, Some([btc]))) }
  let request_fiat = fn(_) { Ok(CmcListResponse(ok_cmc_status, Some([usd]))) }
  let request_conversion = fn(_) { Error(HttpError(httpc.InvalidUtf8Response)) }

  server_ssr_data.get(
    request_crypto,
    request_fiat,
    request_conversion,
    btc.symbol,
    usd.symbol,
  )
  |> should.be_error
  |> should.equal(Nil)
}

pub fn ssr_data_get_happy_path_test() {
  let request_crypto = fn(_) { Ok(CmcListResponse(ok_cmc_status, Some([btc]))) }
  let request_fiat = fn(_) { Ok(CmcListResponse(ok_cmc_status, Some([usd]))) }

  server_ssr_data.get(
    request_crypto,
    request_fiat,
    request_ok_conversion,
    btc.symbol,
    usd.symbol,
  )
  |> should.be_ok
  |> should.equal(
    SsrData([btc], [usd], #(
      Currency(Some(from_amount), Some(btc.id)),
      Currency(Some(expected_to_amount), Some(usd.id)),
    )),
  )
}

fn request_ok_conversion(_) {
  let quote =
    dict.from_list([#(int.to_string(usd.id), QuoteItem(expected_to_amount))])
  let conversion = Conversion(btc.id, "", "", from_amount, quote)
  Ok(CmcResponse(ok_cmc_status, Some(conversion)))
}
