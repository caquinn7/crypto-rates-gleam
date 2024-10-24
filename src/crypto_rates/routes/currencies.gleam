import crypto_rates/coin_market_cap.{
  type CmcListResponse, type CryptoCurrency, type FiatCurrency, CmcListResponse,
}
import crypto_rates/problem_details
import crypto_rates/response_utils
import crypto_rates/validation_utils.{error_msg}
import gleam/dynamic.{type Dynamic}
import gleam/http/request
import gleam/json
import gleam/list
import gleam/option.{Some}
import gleam/result
import non_empty_list.{type NonEmptyList}
import valid
import wisp.{type Request, type Response}

pub fn get_crypto(
  req: Request,
  reguest_crypto: fn(Int) -> Result(CmcListResponse(CryptoCurrency), Dynamic),
) -> Response {
  req
  |> validate_request
  |> result.map_error(fn(errs) {
    let assert Ok(status) = problem_details.new_problem_status(400)
    status
    |> problem_details.new_validation_details(
      "One or more request parameters are invalid.",
      req,
      errs,
    )
    |> response_utils.problem_details_response
  })
  |> result.map(fn(limit) {
    let assert Ok(CmcListResponse(_status, Some(crypto))) =
      reguest_crypto(limit)

    crypto
    |> list.unique
    |> json.array(fn(currency) {
      json.object([
        #("id", json.int(currency.id)),
        #("rank", json.nullable(currency.rank, json.int)),
        #("name", json.string(currency.name)),
        #("symbol", json.string(currency.symbol)),
      ])
    })
    |> response_utils.json_response(200)
  })
  |> result.unwrap_both
}

pub fn get_fiat(
  req: Request,
  reguest_fiat: fn(Int) -> Result(CmcListResponse(FiatCurrency), Dynamic),
) -> Response {
  req
  |> validate_request
  |> result.map_error(fn(errs) {
    let assert Ok(status) = problem_details.new_problem_status(400)
    status
    |> problem_details.new_validation_details(
      "One or more request parameters are invalid.",
      req,
      errs,
    )
    |> response_utils.problem_details_response
  })
  |> result.map(fn(limit) {
    let assert Ok(CmcListResponse(_status, Some(fiat))) = reguest_fiat(limit)

    fiat
    |> list.unique
    |> json.array(fn(currency) {
      json.object([
        #("id", json.int(currency.id)),
        #("name", json.string(currency.name)),
        #("sign", json.string(currency.sign)),
        #("symbol", json.string(currency.symbol)),
      ])
    })
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
  |> list.key_find("limit")
  |> result.unwrap("100")
  |> validator
}
