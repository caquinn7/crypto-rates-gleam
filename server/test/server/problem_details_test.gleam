import birdie
import gleam/json
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import non_empty_list
import server/problem_details
import wisp/testing

pub fn main() {
  gleeunit.main()
}

pub fn new_problem_status_400_test() {
  400
  |> problem_details.new_problem_status
  |> should.be_ok
  |> problem_details.unwrap_problem_status
  |> should.equal(#(400, "Bad Request"))
}

pub fn new_problem_status_404_test() {
  404
  |> problem_details.new_problem_status
  |> should.be_ok
  |> problem_details.unwrap_problem_status
  |> should.equal(#(404, "Not Found"))
}

pub fn new_problem_status_405_test() {
  405
  |> problem_details.new_problem_status
  |> should.be_ok
  |> problem_details.unwrap_problem_status
  |> should.equal(#(405, "Method Not Allowed"))
}

pub fn new_problem_status_415_test() {
  415
  |> problem_details.new_problem_status
  |> should.be_ok
  |> problem_details.unwrap_problem_status
  |> should.equal(#(415, "Unsupported Media Type"))
}

pub fn new_problem_status_500_test() {
  500
  |> problem_details.new_problem_status
  |> should.be_ok
  |> problem_details.unwrap_problem_status
  |> should.equal(#(500, "Internal Server Error"))
}

pub fn new_problem_status_non_error_status_test() {
  200
  |> problem_details.new_problem_status
  |> should.be_error
  |> should.equal(Nil)
}

pub fn new_details_test() {
  500
  |> problem_details.new_problem_status
  |> should.be_ok
  |> problem_details.new_details(
    Some("Error occurred"),
    testing.get("/endpoint", []),
  )
  |> problem_details.encode
  |> json.to_string
  |> birdie.snap("new_details_test")
}

pub fn new_details_detail_is_none_test() {
  500
  |> problem_details.new_problem_status
  |> should.be_ok
  |> problem_details.new_details(None, testing.get("/endpoint", []))
  |> problem_details.encode
  |> json.to_string
  |> birdie.snap("new_details_detail_is_none_test")
}

pub fn new_validation_details_test() {
  400
  |> problem_details.new_problem_status
  |> should.be_ok
  |> problem_details.new_validation_details(
    testing.get("/endpoint", []),
    non_empty_list.new("error 1", ["error 2"]),
  )
  |> problem_details.encode
  |> json.to_string
  |> birdie.snap("new_validation_details_test")
}
