# Html Info

Html Info adds additional metadata to the standard library JS extern type definitions, allowing improved code generation via custom macros.

## Metadata

### `@:html.attr`

> This metadata links a html attribute to its JavaScript property.   
> `<input value="foo" />`.  
> The `value` attribute would be linked to `js.html.InputElement.value` for reading & `js.html.InputElement.defaultValue` for writing.

- _Sig:_ `@:html.attr($ident, ?$access)`, where:
    + `$ident` is a html attribute name or `_` which matches any attribute.
    + `?$access` is an optional single access of either `get` or `set`. If omitted, `@:html.attr` will match both `get` and `set`.

### `@:html.default`

> `@:html.default` indicates which field should be accessed for reading and writing.   
> `@:html.default({type:"date"})` requires matching attributes.

- _Sig:_ `@:html.default(?$attributes)` where:
    + `?$attributes` is an optional object, where `{$key:$value}`
        - `$key` is the attribute name.
        - `$value` is the attribute value. `$value` can be `_`, meaning any value matches.

### `@:html.events`

> `@:events(['click'])` indicates which events are expected to be offered/selected by default for a particular element, if any.   
> `@:events({type:"reset"}, ['click'])` requires matching attributes.

- _Sig:_ `@:events(?$attributes, $idents)` where:
    + `?$attributes` is the same as `@:html.default` above.
    + `$idents` is a String array of preferred event names.

### `@:html.expr`

- _Sig:_ `@:html.expr($attribute, $handler, ?$access)` where:
    + `$attribute`

---

### Goals

To enhance the typed API's and to have JavaScript properties and values persist in HTML.

This library picks properties which update the HTML over faster, non-persisting property accesses.

### Reasons

- Not all JavaScript properties match their respective HTML attributes names or have consistent access patterns as you would expect. 
- Some properties don't update their HTML counterparts when set. 
- Accessing one property over another can be faster or slower. 
- Some properties have strict requirements, which are better suited to be represented by a typed language.

- IDL attributes *e.g native property access*
  - > dot access property on native javascript object
  - enums
  - numeric
  - `get` => `ele.$fieldname`
  - `set` => `ele.$fieldname = $value`
  - `has` => `"$fieldname" in ele`
  - `remove` => `!error`
- `data-*` attributes
  - > dot access property on `.dataset` object
  - > https://developer.mozilla.org/en-US/docs/Web/API/HTMLOrForeignElement/dataset
  - `get` => `ele.dataset.$fieldname`
  - `set` => `ele.dataset.$fieldname = $value`
  - `has` => `"$fieldname" in ele.dataset`
  - `remove` => `delete ele.dataset.$fieldname`
- other attributes
  - > `.{get/set/has/remove}Attribute`
  - > https://developer.mozilla.org/en-US/docs/Web/API/Element/removeAttribute#usage_notes
  - `get` => `ele.getAttribute("$fieldname")`
  - `set` => `ele.setAttribute("$fieldname", $value)`
  - `has` => `ele.hasAttribute("$fieldname")`
  - `remove` => `ele.removeAttribute("$fieldname")`