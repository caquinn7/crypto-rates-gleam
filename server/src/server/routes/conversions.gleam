import gleam/dict
import gleam/float
import gleam/http/request
import gleam/int
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import non_empty_list.{type NonEmptyList}
import server/coin_market_cap.{
  type CmcResponse, type Conversion, type Status, CmcResponse, QuoteItem, Status,
} as cmc
import server/response_utils
import server/validation_utils.{error_msg}
import shared/coin_market_cap_types.{
  type ConversionParameters, ConversionParameters,
}
import shared/conversion_response.{
  type ConversionResponse, type Currency, ConversionResponse, Currency,
}
import valid
import wisp.{type Request, type Response}

pub type ConversionError {
  CurrencyNotFound(Int)
}

pub fn get(
  req: Request,
  request_conversion: fn(ConversionParameters) ->
    Result(CmcResponse(Conversion), cmc.RequestError),
) -> Response {
  req
  |> validate_request
  |> result.map_error(response_utils.bad_request_response(req, _))
  |> result.map(fn(conversion_params) {
    let assert Ok(CmcResponse(status, data)) =
      request_conversion(conversion_params)

    conversion_params
    |> map_cmc_response(status, data)
    |> result.map(fn(conversion_response) {
      conversion_response
      |> conversion_response.encoder()
      |> response_utils.json_response(200)
    })
    |> result.map_error(fn(conversion_err) {
      let CurrencyNotFound(invalid_id) = conversion_err

      let err =
        "currency with id \""
        <> int.to_string(invalid_id)
        <> "\" does not exist"

      non_empty_list.new(err, [])
      |> response_utils.bad_request_response(req, _)
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
