import crypto_rates/coin_market_cap.{
  type CmcResponse, type Conversion, type ConversionParameters, type Status,
  CmcResponse, ConversionParameters, QuoteItem, Status,
}
import crypto_rates/problem_details
import crypto_rates/response_utils
import crypto_rates/validation_utils.{error_msg}
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/float
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import non_empty_list.{type NonEmptyList}
import valid
import wisp.{type Request, type Response}

pub type ConversionResponse {
  ConversionResponse(from: Currency, to: Currency)
}

pub type Currency {
  Currency(id: Int, amount: Float)
}

pub type ConversionError {
  CurrencyNotFound(Int)
}

pub fn get(
  req: Request,
  request_conversion: fn(ConversionParameters) ->
    Result(CmcResponse(Conversion), Dynamic),
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
  |> result.map(fn(conversion_params) {
    let assert Ok(CmcResponse(status, data)) =
      request_conversion(conversion_params)

    conversion_params
    |> map_cmc_response(status, data)
    |> result.map(fn(conversion_response) {
      conversion_response
      |> encode_conversion_response
      |> response_utils.json_response(200)
    })
    |> result.map_error(fn(conversion_err) {
      let CurrencyNotFound(invalid_id) = conversion_err
      let err =
        "currency with id \""
        <> int.to_string(invalid_id)
        <> "\" does not exist"

      let assert Ok(status) = problem_details.new_problem_status(400)
      status
      |> problem_details.new_validation_details(
        "One or more request parameters are invalid.",
        req,
        non_empty_list.new(err, []),
      )
      |> response_utils.problem_details_response
    })
    |> result.unwrap_both
  })
  |> result.unwrap_both
}

pub fn validate_request(
  req: Request,
) -> Result(ConversionParameters, NonEmptyList(String)) {
  let amount_validator = {
    let param_name = "amount"
    let threshold = 0.00000001

    valid.is_some(error_msg(param_name, "is required"))
    |> valid.then(
      validation_utils.string_is_number(error_msg(
        param_name,
        "must be either an integer or a floating-point number",
      )),
    )
    |> valid.then(validation_utils.float_is_greater_than(
      threshold,
      error_msg(
        param_name,
        "must be greater than " <> float.to_string(threshold),
      ),
    ))
  }

  let id_validator = fn(param_name) {
    valid.is_some(error_msg(param_name, "is required"))
    |> valid.then(
      valid.string_is_int(error_msg(param_name, "must be an integer")),
    )
    |> valid.then(valid.int_min(
      1,
      error_msg(param_name, "must be greater than 0"),
    ))
  }

  let assert [amount, from, to] =
    get_query_params(req, ["amount", "from", "to"])

  valid.build3(ConversionParameters)
  |> valid.check(amount, amount_validator)
  |> valid.check(from, id_validator("from"))
  |> valid.check(to, id_validator("to"))
}

pub fn map_cmc_response(
  conversion_params: ConversionParameters,
  cmc_status: Status,
  cmc_conversion: Option(Conversion),
) -> Result(ConversionResponse, ConversionError) {
  let ConversionParameters(_amount, from, to) = conversion_params

  case cmc_status {
    Status(400, Some("Invalid value for \"id\":" <> _)) ->
      CurrencyNotFound(from) |> Error

    Status(400, Some("Invalid value for \"convert_id\":" <> _)) ->
      CurrencyNotFound(to) |> Error

    Status(0, _) -> {
      let assert Some(conversion) = cmc_conversion

      let from_currency = Currency(conversion.id, conversion.amount)

      let assert Ok(QuoteItem(price)) =
        dict.get(conversion.quote, int.to_string(to))

      let to_currency = Currency(to, price)

      ConversionResponse(from_currency, to_currency) |> Ok
    }

    _ -> panic
  }
}

fn get_query_params(
  req: Request,
  param_names: List(String),
) -> List(Option(String)) {
  let assert Ok(query_params) = request.get_query(req)

  param_names
  |> list.map(fn(name) {
    query_params
    |> list.key_find(name)
    |> option.from_result
  })
}

fn encode_conversion_response(conversion_response: ConversionResponse) {
  let encode_currency = fn(currency: Currency) {
    json.object([
      #("id", json.int(currency.id)),
      #("amount", json.float(currency.amount)),
    ])
  }

  json.object([
    #("from", encode_currency(conversion_response.from)),
    #("to", encode_currency(conversion_response.to)),
  ])
}
