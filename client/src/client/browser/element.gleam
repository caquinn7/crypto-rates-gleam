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
