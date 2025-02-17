import gleam/int
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type AutoResizeInput(msg) {
  AutoResizeInput(
    id: String,
    value: String,
    width: Int,
    on_input: fn(String) -> msg,
  )
}

pub fn view(input_model: AutoResizeInput(msg)) -> Element(msg) {
  let input =
    html.input([
      attribute.class("amount-input"),
      attribute.class(
        "px-6 py-4 border rounded-lg focus:outline-none bg-neutral text-3xl text-center text-neutral-content caret-info",
      ),
      attribute.id(input_model.id),
      attribute.style([#("width", int.to_string(input_model.width) <> "px")]),
      attribute.value(input_model.value),
      event.on_input(input_model.on_input),
    ])

  let mirror_input =
    html.span(
      [attribute.class("amount-input-mirror absolute invisible whitespace-pre")],
      [element.text(input_model.value)],
    )

  html.div([], [input, mirror_input])
}
