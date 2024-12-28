import { Ok, Error } from "./gleam.mjs";

export function contains(elem1, elem2) {
  return elem1.contains(elem2);
}

export function previousElementSibling(elem) {
  let sibling = elem.previousElementSibling;
  return sibling ? new Ok(sibling) : new Error();
}