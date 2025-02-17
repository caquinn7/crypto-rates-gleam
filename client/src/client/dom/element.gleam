import plinth/browser/element

/// Returns `True` if:
/// 
/// * the second element is a descendant of the first
/// 
/// or
/// 
/// * the second element is the same element as the first
/// 
/// Otherwise `False`.
@external(javascript, "../../element_ffi.mjs", "contains")
pub fn contains(element1: element.Element, element2: element.Element) -> Bool

@external(javascript, "../../element_ffi.mjs", "previousElementSibling")
pub fn previous_element_sibling(
  element: element.Element,
) -> Result(element.Element, Nil)

@external(javascript, "../../element_ffi.mjs", "nextElementSibling")
pub fn next_element_sibling(
  element: element.Element,
) -> Result(element.Element, Nil)

@external(javascript, "../../element_ffi.mjs", "copyInputStyles")
pub fn copy_input_styles(
  from element1: element.Element,
  to element2: element.Element,
) -> Nil

@external(javascript, "../../element_ffi.mjs", "getOffsetWidth")
pub fn get_offset_width(element: element.Element) -> Int

@external(javascript, "../../element_ffi.mjs", "getComputedStyleProperty")
pub fn get_computed_style_property(
  element: element.Element,
  property_name: String,
) -> String
