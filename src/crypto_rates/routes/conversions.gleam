import crypto_rates/coin_market_cap.{
  type CmcResponse, type Conversion, type ConversionParameters, type Status,
  CmcResponse, ConversionParameters, QuoteItem, Status,
}
import crypto_rates/validation_failed.{type ValidationFailed}
import gleam/dict
import gleam/dynamic.{type Dynamic}
import gleam/float
import gleam/http/request
import gleam/int
import gleam/json
import gleam/list
import gleam/option.{type Option, Some}
import gleam/result
import non_empty_list
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

type ConversionRequest {
  ConversionRequest(
    amount: Option(String),
    from: Option(String),
    to: Option(String),
  )
}

pub fn validate_request(
  req: Request,
) -> Result(ConversionParameters, ValidationFailed) {
  let error_msg = fn(param_name, problem) {
    "\"" <> param_name <> "\" " <> problem
  }

  let amount_validator = {
    let string_is_number = fn(str, param_name) {
      str
      |> float.parse
      |> result.try_recover(fn(_) {
        int.parse(str)
        |> result.map(int.to_float)
      })
      |> result.map_error(fn(_) {
        non_empty_list.new(
          error_msg(
            param_name,
            "must be either an integer or a floating-point number",
          ),
          [],
        )
      })
    }

    let param_name = "amount"

    valid.is_some(error_msg(param_name, "is required"))
    |> valid.then(string_is_number(_, param_name))
    |> valid.then(fn(x) {
      let min = 0.00000001
      case x >. min {
        True -> Ok(x)
        _ ->
          Error(
            non_empty_list.new(
              error_msg(
                param_name,
                "must be greater than " <> float.to_string(min),
              ),
              [],
            ),
          )
      }
    })
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

  let conversion_req = {
    let get_params = fn(param_names) {
      let assert Ok(query_params) = request.get_query(req)

      param_names
      |> list.map(fn(name) {
        query_params
        |> list.key_find(name)
        |> option.from_result
      })
    }

    let assert [amount, from, to] = get_params(["amount", "from", "to"])

    ConversionRequest(amount, from, to)
  }

  valid.build3(ConversionParameters)
  |> valid.check(conversion_req.amount, amount_validator)
  |> valid.check(conversion_req.from, id_validator("from"))
  |> valid.check(conversion_req.to, id_validator("to"))
}

pub fn get(
  conversion_params: ConversionParameters,
  request_conversion: fn(ConversionParameters) ->
    Result(CmcResponse(Conversion), Dynamic),
) -> Response {
  let assert Ok(CmcResponse(status, data)) =
    request_conversion(conversion_params)

  conversion_params
  |> map_cmc_response(status, data)
  |> result.map(fn(conversion_response) {
    conversion_response
    |> encode_conversion_response
    |> json.to_string_builder
    |> wisp.json_response(200)
  })
  |> result.map_error(fn(conversion_err) {
    let CurrencyNotFound(invalid_id) = conversion_err
    let err =
      "currency with id \"" <> int.to_string(invalid_id) <> "\" does not exist"

    err
    |> validation_failed.from_error
    |> validation_failed.encode
    |> json.to_string_builder
    |> wisp.json_response(400)
  })
  |> result.unwrap_both
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
