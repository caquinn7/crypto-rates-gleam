import gleam/list
import gleam/option.{Some}
import gleam/result
import server/coin_market_cap.{type CmcListResponse, type RequestError}
import server/routes/conversions.{type RequestConversion}
import shared/coin_market_cap_types.{
  type ConversionParameters, type CryptoCurrency, type FiatCurrency,
  ConversionParameters,
}
import shared/ssr_data.{type Currency, type SsrData, Currency, SsrData}

pub fn get(
  request_crypto: fn() -> Result(CmcListResponse(CryptoCurrency), RequestError),
  get_fiat: fn() -> Result(List(FiatCurrency), Nil),
  request_conversion: RequestConversion,
  from_currency: String,
  to_currency: String,
) -> Result(SsrData, Nil) {
  let get_crypto = fn() {
    request_crypto()
    |> result.map(fn(cmc_response) {
      case cmc_response.data {
        Some(currencies) -> list.unique(currencies)
        _ -> []
      }
    })
    |> result.replace_error(Nil)
  }

  let get_conversion = fn(conversion_params) {
    use cmc_conversion_response <- result.try(
      conversion_params
      |> request_conversion
      |> result.replace_error(Nil),
    )

    cmc_conversion_response
    |> conversions.map_cmc_response(conversion_params, _)
    |> result.replace_error(Nil)
  }

  use crypto <- result.try(get_crypto())
  use fiat <- result.try(get_fiat())

  use btc <- result.try(
    list.find(crypto, fn(currency) { currency.symbol == from_currency }),
  )
  use usd <- result.try(
    list.find(fiat, fn(currency) { currency.symbol == to_currency }),
  )

  use conversion <- result.try(
    get_conversion(ConversionParameters(1.0, btc.id, usd.id)),
  )

  let currencies = #(
    Currency(Some(1.0), Some(btc.id)),
    Currency(Some(conversion.to.amount), Some(usd.id)),
  )

  Ok(SsrData(crypto:, fiat:, currencies:))
}
