import birdie
import decode/zero
import gleam/json
import gleeunit
import gleeunit/should
import shared/conversion_response.{ConversionResponse, Currency}

pub fn main() {
  gleeunit.main()
}

pub fn conversion_response_encoder_test() {
  ConversionResponse(Currency(1, 1.2), Currency(2, 2.2))
  |> conversion_response.encoder()
  |> json.to_string
  |> birdie.snap("conversion_response_encoder_test")
}

pub fn conversion_response_decoder_test() {
  let conversion_response =
    ConversionResponse(Currency(1, 1.2), Currency(2, 2.2))

  conversion_response
  |> conversion_response.encoder()
  |> json.to_string
  |> json.decode(zero.run(_, conversion_response.decoder()))
  |> should.be_ok
  |> should.equal(conversion_response)
}
