import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub type ButtonDropdown(msg, ctx) {
  ButtonDropdown(
    ctx: ctx,
    id: String,
    button_text: String,
    dropdown_options: Dict(String, List(DropdownOption)),
    current_value: Option(String),
    show_dropdown: Bool,
    filter: String,
    search_input_id: String,
    on_button_click: fn(ctx) -> msg,
    on_search_input: fn(ctx, String) -> msg,
    on_select: fn(ctx, String) -> msg,
  )
}

pub type DropdownOption {
  DropdownOption(value: String, display: String)
}

pub fn view(button_dropdown: ButtonDropdown(msg, ctx)) {
  html.div(
    [attribute.class("relative w-72"), attribute.id(button_dropdown.id)],
    [
      button(button_dropdown.button_text, fn() {
        button_dropdown.on_button_click(button_dropdown.ctx)
      }),
      dropdown(
        button_dropdown.search_input_id,
        button_dropdown.show_dropdown,
        button_dropdown.filter,
        button_dropdown.dropdown_options,
        button_dropdown.on_search_input(button_dropdown.ctx, _),
        button_dropdown.on_select(button_dropdown.ctx, _),
      ),
    ],
  )
}

fn button(text: String, on_click: fn() -> msg) -> Element(msg) {
  html.button(
    [
      attribute.class(
        "w-full p-2 border border-gray-300 rounded-lg text-left focus:ring-2 focus:ring-blue-500 focus:outline-none",
      ),
      event.on_click(on_click()),
    ],
    [html.text(text)],
  )
}

fn dropdown(
  search_input_id: String,
  visible: Bool,
  filter: String,
  dd_options: Dict(String, List(DropdownOption)),
  on_search_input: fn(String) -> msg,
  on_select: fn(String) -> msg,
) {
  html.div(
    [
      attribute.class(
        "currency-dropdown absolute z-10 w-full bg-white border border-gray-300 rounded-lg shadow-md max-h-64 overflow-y-auto",
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
  html.div([attribute.class("sticky top-0 bg-white z-10")], [
    html.input([
      attribute.class("w-full p-2 border-b border-gray-200 focus:outline-none"),
      attribute.id(id),
      attribute.placeholder("Search..."),
      attribute.type_("text"),
      attribute.value(value),
      event.on_input(on_input),
    ]),
  ])
}

fn option_group(
  group: #(String, List(DropdownOption)),
  on_select: fn(String) -> msg,
) -> element.Element(msg) {
  let group_title_div =
    html.div([attribute.class("font-bold px-2 py-1 bg-gray-100")], [
      html.text(group.0),
    ])

  html.div([attribute.class("group")], [
    group_title_div,
    options_container(group.1, on_select),
  ])
}

fn options_container(
  dd_options: List(DropdownOption),
  on_select: fn(String) -> msg,
) {
  let dd_option = fn(item: DropdownOption) {
    html.div(
      [
        attribute.attribute("data-value", item.value),
        attribute.class("px-4 py-1 cursor-pointer hover:bg-gray-100"),
        event.on_click(on_select(item.value)),
      ],
      [html.text(item.display)],
    )
  }

  element.keyed(html.div([attribute.class("options-container")], _), {
    list.map(dd_options, fn(item) {
      let child = dd_option(item)
      #(item.value, child)
    })
  })
}
