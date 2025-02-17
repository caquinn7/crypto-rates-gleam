import client/models/auto_resize_input.{type AutoResizeInput}
import client/models/button_dropdown.{type ButtonDropdown}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html

pub type CurrencyInputGroup(msg) {
  CurrencyInputGroup(
    amount_input: AutoResizeInput(msg),
    currency_selector: ButtonDropdown(msg),
  )
}

pub fn view(input_group: CurrencyInputGroup(msg)) -> Element(msg) {
  html.span([attribute.class("flex space-x-4")], [
    auto_resize_input.view(input_group.amount_input),
    button_dropdown.view(input_group.currency_selector),
  ])
}
