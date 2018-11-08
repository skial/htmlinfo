# Html Info

Html Info adds additional metadata to the standard library JS extern type definitions, sallowing improved code generation via custom macros.

## Metadata

### `@:html.attr`

> This metadata links a html attribute to its JavaScript field.   
> `<input value="foo" />`.  
> The `value` attribute would be linked to `js.html.InputElement.value` for reading & `js.html.InputElement.defaultValue` for writing.

- _Sig:_ `@:html.attr($ident, ?$access)`, where:
    + `$ident` is a html attribute name or `_` which matches any attribute.
    + `?$access` is an optional single access of either `get` or `set`. If omitted, `@:html.attr` will match both `get` and `set`.

### `@:default`

> `@:default` indicates which field should be accessed for reading and writing.   
> `@:default({type:"date"})` requires matching attributes.

- _Sig:_ `@:default(?$attributes)` where:
    + `?$attributes` is an optional object, where `{$key:$value}`
        - `$key` is the attribute name.
        - `$value` is the attribute value. `$value` can be `_`, meaning any value matches.

### `@:events`

> `@:events(['click'])` indicates which events are expected to be offered/selected by default for a particular element, if any.   
> `@:events({type:"reset"}, ['click'])` requires matching attributes.

- _Sig:_ `@:events(?$attributes, $idents)` where:
    + `?$attributes` is the same as `@:default` above.
    + `$idents` is a String array of preffered event names.