import client/models/button.{type Button, Button}
import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type ButtonDropdown(msg) {
  ButtonDropdown(
    id: String,
    button: Button(msg),
    dropdown_options: Dict(String, List(DropdownOption(msg))),
    current_value: Option(String),
    show_dropdown: Bool,
    filter: String,
    search_input_id: String,
    on_search_input: fn(String) -> msg,
    on_select: fn(String) -> msg,
  )
}

pub type DropdownOption(msg) {
  DropdownOption(value: String, display: Element(msg))
}

pub fn view(button_dropdown: ButtonDropdown(msg)) -> Element(msg) {
  html.div([attribute.class("relative"), attribute.id(button_dropdown.id)], [
    button.view(button_dropdown.button),
    dropdown(
      button_dropdown.search_input_id,
      button_dropdown.show_dropdown,
      button_dropdown.filter,
      button_dropdown.dropdown_options,
      button_dropdown.on_search_input,
      button_dropdown.on_select,
    ),
  ])
}

fn dropdown(
  search_input_id: String,
  visible: Bool,
  filter: String,
  dd_options: Dict(String, List(DropdownOption(msg))),
  on_search_input: fn(String) -> msg,
  on_select: fn(String) -> msg,
) {
  html.div(
    [
      attribute.class(
        "currency-dropdown absolute z-10 border rounded-lg shadow-md max-h-64 overflow-y-auto",
      ),
      attribute.class(
        "min-w-max left-1/2 transform -translate-x-1/2 w-auto translate-y-3",
      ),
      case visible {
        True -> attribute.none()
        False -> attribute.class("hidden")
      },
    ],
    [
      search_input(search_input_id, filter, on_search_input),
      html.div(
        [attribute.class("suggestions")],
        dd_options
          |> dict.to_list
          |> list.map(option_group(_, on_select)),
      ),
    ],
  )
}

fn search_input(id: String, value: String, on_input: fn(String) -> msg) {
  html.div([attribute.class("sticky top-0 z-10")], [
    html.input([
      attribute.class(
        "w-full p-2 border-b focus:outline-none bg-neutral text-neutral-content caret-info",
      ),
      attribute.id(id),
      attribute.placeholder("Search"),
      attribute.type_("text"),
      attribute.value(value),
      event.on_input(on_input),
    ]),
  ])
}

fn option_group(
  group: #(String, List(DropdownOption(msg))),
  on_select: fn(String) -> msg,
) -> element.Element(msg) {
  let group_title_div =
    html.div(
      [attribute.class("px-2 py-1 font-bold text-lg text-base-content")],
      [html.text(group.0)],
    )

  html.div([attribute.class("group")], [
    group_title_div,
    options_container(group.1, on_select),
  ])
}

fn options_container(
  dd_options: List(DropdownOption(msg)),
  on_select: fn(String) -> msg,
) {
  let dd_option = fn(item: DropdownOption(msg)) {
    html.div(
      [
        attribute.attribute("data-value", item.value),
        attribute.class("px-6 py-1 cursor-pointer text-base-content"),
        attribute.class("hover:bg-base-content hover:text-base-100"),
        event.on_click(on_select(item.value)),
      ],
      [item.display],
    )
  }

  element.keyed(html.div([attribute.class("options-container")], _), {
    list.map(dd_options, fn(item) {
      let child = dd_option(item)
      #(item.value, child)
    })
  })
}
