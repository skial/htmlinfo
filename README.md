# Html Info

Html Info adds additional metadata to the standard library JS extern type definitions, 
allowing improved code generation via custom macros.

## Metadata

### `@:html.attr`

- _Sig:_ `@:html.attr($ident, ?$access)`, where:
    + `$ident` is a html attribute name or `_` which matches any attribute.
    + `?$access` is an optional single access of either `get` or `set`. If omitted, `@:html.attr` will match both `get` and `set`.

### `@:default`

- _Sig:_ `@:default(?$attributes)` where:
    + `?$attributes` is an optional object, where `{$key:$value}`
        - `$key` is the attribute name.
        - `$value` is the attribute value.

### `@:events`

- _Sig:_ `@:events(?$attributes, $idents)` where:
    + `?$attributes` is the same as `@:default` above.
    + `$idents` is a String array of preffered event names.