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

### Goals

To enhance the typed API's and to have JavaScript properties and values persist in HTML.

This library picks properties which update the HTML over faster, non-persisting property accesses.

### Reasons

- Not all JavaScript properties match their respective HTML attributes names or have consistent access patterns as you would expect. 
- Some properties don't update their HTML counterparts when set. 
- Accessing one property over another can be faster or slower. 
- Some properties have strict requirements, which are better suited to be represented by a typed language.
- Some elements behaviours are dependant on attribute values.
 
### Attribute's

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

### Metadata

- > Namespace all values to @:html
- `@:html.tag("$tagName", ?$selfClosing = false) $type`
- `@:html.events($idents, ?$attributes) $type`
- `@:html.attr("$ident", ?$access, ?$attributes, ?$persistent) $type.$property`
  + `@:html.default(?$attributes, ?$persistent) $type.$property`
  + shortcut for `@:html.attr("$property", _, ?$attributes, ?$persistent) $type.$property`

+ `$idents` are `String`
+ `$attributes` are `haxe.DynamicAccess<String>`
+ `$access` is an enum:
  + `set`
  + `get`
  + `_` matching all other values.

### Resolution

- Node
  - > metadata
  - *properties*
  - Element
    - > metadata
    - *properties*


Start off with the most specific `$Type` passed in, assume in this case an HTMLElement which extends Element.
- Search `$Type` metadata & properties
- Climb the super class tree and repeat.
- All matches are pushed into an array. The first element should be the best match. All expressions in the results array **should** be valid at runtime.
    - *Easier said than done.*

### Processor

- An Array of processors.
  - Macro function to add additional processors.
  - Push to end of list.
- Index 0 processor will always be the standard one to resolve based on the metadata listed above.
- Each processor will have to `implement Interface`.
- Index 0 will implement all interface fields. 
- Others processors can either depend on Index 0 directly or fall through to the next one.

```haxe
interface Processor {
    function get(type:Type, key:String, attributes = {}, follow = true, persist = true):Outcome<Array<Field>, Error>;
    function set(type:Type, key:String, attributes = {}, follow = true, persist = true):Outcome<Array<Field>, Error>;
    function has(type:Type, key:String, attributes = {}, follow = true):Outcome<{runtime:Array<Field>, comptime:Null<Bool>}, Error>;
    function remove(type:Type, key:String, attributes = {}, follow = true, persist = true):Outcome<Array<Field>, Error>;
    function listen(type:Type, event:String, attributes = {}, follow = true):Outcome<Array<Field>, Error>;
}
```

### Library API

```haxe
abstract HtmlTag(String) from String to String;

class HtmlInfo {

    function getType(tag:HtmlTag):Outcome<Type, Error>;
    function getTag(type:Type):Outcome<HtmlTag, Error>;
    function getEvents(type:Type, attributes = {}, follow = true):Outcome<{names:Array<String>, types:Array<Type>}, Error>;

    //

    function getAttribute(type:Type, key:String, attributes = {}, follow = true, persist = true):Outcome<GetterFieldsUtils, Error>;
    function setAttribute(type:Type, key:String, attributes = {}, follow = true, persist = true):Outcome<SetterFieldsUtils, Error>;
    function hasAttribute(type:Type, key:String, attributes = {}, follow = true):Outcome<{runtime:CheckerFields, comptime:Null<Bool>}, Error>;
    function removeAttribute(type:Type, key:String, attributes = {}, follow = true, persist = true):Outcome<RemoverFields, Error>;
    function addEventListener(type:Type, event:String, attributes = {}):Outcome<EventListenerFields, Error>;

}

@:using(GetterFieldsUtils);
typedef GetterFields = Array<Field>;

@:using(SetterFieldsUtils);
typedef SetterFields = Array<Field>;

@:using(CheckerFieldsUtils);
typedef CheckerFields = Array<Field>;

@:using(RemoverFieldsUtils);
typedef RemoverFields = Array<Field>;

@:using(EventListenerFieldsUtils);
typedef EventListenerFields = Array<Field>;

class GetterFieldsUtils {
    function toExpr(fields:GetterFields, obj:Expr, key:Expr):Expr;
    // $obj.$fields[0]($key);
}

class SetterFieldsUtils {
    function toExpr(fields:SetterFieldsUtils, obj:Expr, key:Expr, value:Expr):Expr; 
    // $obj.$fields[0]($key, $value);
}

class CheckerFieldsUtils {
    function toExpr(fields:CheckerFieldsUtils, obj:Expr, key:Expr):Expr; 
    // $obj.$fields[0]($key);
}

class RemoverFieldsUtils {
    function toExpr(fields:RemoverFieldsUtils, obj:Expr, key:Expr):Expr; 
    // $obj.$fields[0]($key);
}

class EventListenerFields {
    function toExpr(fields:EventListenerFields, obj:Expr, event:Expr, toExprback:Expr):Expr; 
    // $obj.$fields[0]($event, $toExprback);
}
```