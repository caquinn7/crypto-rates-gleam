import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/result
import non_empty_list.{type NonEmptyList}
import server/coin_market_cap.{
  type CmcListResponse, type RequestError, CmcListResponse,
}
import server/response_utils
import server/validation_utils.{error_msg}
import shared/coin_market_cap_types.{type CryptoCurrency, type FiatCurrency} as cmc_types
import valid
import wisp.{type Request, type Response}

pub fn get_crypto(
  req: Request,
  request_crypto: fn(Int) ->
    Result(CmcListResponse(CryptoCurrency), RequestError),
) -> Response {
  req
  |> validate_request
  |> result.map_error(response_utils.bad_request_response(req, _))
  |> result.map(fn(limit) {
    let assert Ok(CmcListResponse(_status, Some(crypto))) =
      request_crypto(limit)

    crypto
    |> list.unique
    |> json.array(cmc_types.crypto_currency_encoder())
    |> response_utils.json_response(200)
  })
  |> result.unwrap_both
}

pub fn get_fiat(
  req: Request,
  request_fiat: fn(Int) -> Result(CmcListResponse(FiatCurrency), RequestError),
) -> Response {
  req
  |> validate_request
  |> result.map_error(response_utils.bad_request_response(req, _))
  |> result.map(fn(limit) {
    let assert Ok(CmcListResponse(_status, Some(fiat))) = request_fiat(limit)

    fiat
    |> list.unique
    |> json.array(cmc_types.fiat_currency_encoder())
    |> response_utils.json_response(200)
  })
  |> result.unwrap_both
}

pub fn validate_request(req: Request) -> Result(Int, NonEmptyList(String)) {
  let limit_name = "limit"

  let validator =
    valid.string_is_int(error_msg(limit_name, "must be an integer"))
    |> valid.then(valid.int_min(
      1,
      error_msg(limit_name, "must be greater than or equal to 1"),
    ))

  let assert Ok(query_params) = request.get_query(req)

  query_params
  |> list.key_find(limit_name)
  |> result.unwrap("100")
  |> validator
}
