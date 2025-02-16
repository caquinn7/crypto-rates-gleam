import client/browser/element as browser_element
import gleam/float
import gleam/int
import gleam/result
import gleam/string
import lustre/effect.{type Effect}
import plinth/browser/document
import plinth/browser/element as plinth_element
import plinth/browser/window

pub fn resize_input(
  element_id: String,
  min_width: Int,
  msg_fun: fn(Int) -> msg,
) -> Effect(msg) {
  effect.from(fn(dispatch) {
    window.request_animation_frame(fn(_) {
      let assert Ok(input_elem) = document.get_element_by_id(element_id)
      let assert Ok(mirror_elem) =
        browser_element.next_element_sibling(input_elem)

      browser_element.copy_input_styles(input_elem, mirror_elem)

      let parse_from_input_elem = fn(property_name) {
        let val =
          browser_element.get_computed_style_property(input_elem, property_name)

        let assert True = string.ends_with(val, "px")

        let pixel_count_str = string.replace(val, "px", "")

        let assert Ok(parsed) =
          pixel_count_str
          |> float.parse
          |> result.lazy_or(fn() {
            int.parse(pixel_count_str)
            |> result.map(int.to_float)
          })

        parsed
      }

      let new_width =
        mirror_elem
        |> browser_element.get_offset_width
        |> int.to_float
        |> fn(mirror_offset_width) {
          mirror_offset_width
          +. parse_from_input_elem("paddingLeft")
          +. parse_from_input_elem("paddingRight")
          +. parse_from_input_elem("borderLeftWidth")
          +. parse_from_input_elem("borderRightWidth")
          +. 2.0
        }
        |> float.truncate
        |> int.max(min_width)

      new_width
      |> msg_fun
      |> dispatch

      Nil
    })

    Nil
  })
}

pub fn focus(element_id: String) {
  effect.from(fn(_) {
    window.request_animation_frame(fn(_) {
      let assert Ok(search_elem) = document.get_element_by_id(element_id)
      plinth_element.focus(search_elem)
    })

    Nil
  })
}
