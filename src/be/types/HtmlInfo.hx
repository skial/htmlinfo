package be.types;

import haxe.ds.StringMap;
import haxe.DynamicAccess;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Defines;

using StringTools;
using tink.CoreApi;
using tink.MacroApi;
using haxe.macro.TypeTools;
using be.types.HtmlInfo.CacheUtils;
using be.types.HtmlInfo.ObjectFieldUtils;

interface HtmlHandler {
    function get(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error>;
    function set(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error>;
    function has(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error>;
    function remove(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error>;
    function listen(type:Type, event:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error>;
}

@:forward
@:forwardStatics
@:using(be.types.HtmlInfo.HtmlMetadataUsings)
enum abstract HtmlMetadata(String) to String from String {
    // @:html.tag(string, bool) $type
    var _Tag = ':html.tag';
    // @:html.attr(string, ?access, ?attributes) $property
    var _Attribute = ':html.attr';
    // @:html.events(array<string>, ?attributes) $type
    var _Events = ':html.events';

    //

    public var ident(get, never):Int;

    private inline function get_ident():Int {
        return switch this {
            case _Tag, _Attribute, _Events: 0;
            case _: -1;
        }
    }

    public var attr(get, never):Int;

    private inline function get_attr():Int {
        return switch this {
            case _Tag: -1;
            case _Attribute: 2;
            case _Events: 1;
            case _: -1;
        }
    }

    public var action(get, never):Int;
    private inline function get_action():Int {
        return switch this {
            case _Attribute: 1;
            case _: -1;
        }
    }

}

@:forward
@:forwardStatics
enum abstract Action(String) to String from String {
    public var Get = 'get';
    public var Set = 'set';
    public var Has = 'has';
    public var Delete = 'del';
    public var All = '_';

    @:op(A == B) public static inline function equals(a:Action, b:String):Bool {
        return ((a:String) == All || b == All) || (a:String) == b;
    }
}

@:nullSafety(Strict)
class CacheUtils {

    public static var attributes:StringMap<DynamicAccess<String>> = new StringMap();

    public static function cacheKey(entry:MetadataEntry, type:Type, fieldName:String = ''):Null<String> {
        var key = null;
        var meta:HtmlMetadata = entry.name;
        if (meta.ident == -1 || meta.attr == -1) return key;
        var action = meta.action > -1 ? entry.params[meta.action].toString() : '';

        key = type.toString() + fieldName + meta + entry.params[meta.ident].toString() + action;

        return key;
    }

}

@:nullSafety(Strict)
class ObjectFieldUtils {

    /**
        A simple, stringified `obj.$key=$value` to `$key:$vale` conversion.
    **/
    public static function asDynamicAccess(fields:Array<ObjectField>):DynamicAccess<String> {
        var obj = new DynamicAccess<String>();

        for (field in fields) {
            obj.set( field.field, field.expr.toString() );
        }

        return obj;
    }

}

@:nullSafety(Strict)
class HtmlMetadataUsings {

    /**
        Finds `self` in `entry` matching `ident` againsts `entry`
    **/
    public static function matches(self:HtmlMetadata, entry:MetadataEntry, ident:String, action:Action = All):Bool {
        // None of the metadata entries are empty.
        if (entry.params.length == 0) return false;
        var name = self.ident > -1 ? entry.params[self.ident].toString().replace('"', '') : '/';
        var fit = self.action > -1 ? entry.params[self.action].toString().replace('"', '') : '/';

        return switch self {
            case _Attribute == entry.name => true if ((name == ident || name == All) && action == fit):
                true;

            case _Events == entry.name => true if (name.indexOf(ident) > -1 || name == All):
                true;

            case '_' if (entry.name.startsWith(':html.')):
                (_Attribute.matches(entry, ident, action) || _Events.matches(entry, ident, action));

            case _:
                false;
        }
    }

    public static function filter(self:HtmlMetadata, entry:MetadataEntry, attributes:DynamicAccess<String>, type:Type, ?field:ClassField):Bool {
        switch self {
            case _Attribute, _Events:
                var expr = self.attr > -1 ? entry.params[self.attr] : null;
                expr = expr == null ? macro null : expr;
                var key = entry.cacheKey(type, field == null ? '' : field.name);
                var attrs = if (CacheUtils.attributes.exists(key)) {
                    CacheUtils.attributes.get(key);

                } else {
                    var tmp = switch expr {
                        case _.expr => EObjectDecl(fields) if (fields.length > 0):
                            fields.asDynamicAccess();

                        case _:
                            new DynamicAccess<String>();
                    }
                    CacheUtils.attributes.set(key, tmp);
                    tmp;

                }

                var val = '';
                for (key => value in attrs) {
                    if (!attributes.exists(key)) return false;
                    val = attributes.get(key);
                    if (val != value || val != All) return false;
                }

                return true;

            case _:
                return false;

        }

    }

}

@:nullSafety(Strict)
class StdHandler implements HtmlHandler {

    public function new() {}

    public function search(type:Type, ident:String, metadata:HtmlMetadata, action:Action, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $ident.'));

        switch type {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                if (Debug) {
                    trace( '<checking type ...>' );
                    trace( '⨽ type      : ' + cls.name );
                    trace( '<for ...>' );
                    trace( '⨽ ident     : ' + ident );
                    trace( '⨽ action    : ' + action );
                    trace( '⨽ attrs     : ' + attributes );

                }
                var array:Array<ClassField> = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(metadata)) {
                        var meta = field.meta.extract(metadata)[0];
                        var aKeeper = metadata.matches(meta, ident, action);

                        if (attributes.keys().length > 0) {
                            aKeeper = aKeeper && metadata.filter(meta, attributes, type, field);
                        }

                        if (Debug) {
                            trace( '<checking ...>' );
                            trace( '⨽ field     : ' + field.name );
                            trace( '⨽ meta      : ' + meta.toString() );
                            trace( '<keep ...>' );
                            trace( '⨽ bool      : ' + aKeeper );
                        }

                        if (aKeeper) array.push( field );

                    }

                }

                if (follow && cls.superClass != null) {
                    if (Debug) {
                        trace( '<checking parent ...>' );
                        trace( '⨽ name      : ' + cls.superClass.t.get().name );
                    }
                    switch get(TInst(cls.superClass.t, cls.superClass.params), ident, attributes, follow) {
                        case Success(values): for (value in values) array.push( value );
                        case _:
                    }

                }

                if (array.length > 0) result = Success(array);

            case x:
                if (Debug) {
                    trace( x );
                }

        }

        return result;
    }

    public inline function get(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        return search(type, key, _Attribute, Get, attributes, follow);
    }

    public inline function set(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        return search(type, key, _Attribute, Set, attributes, follow);
    }

    public inline function has(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error> {
        return search(type, key, _Attribute, Has, attributes, follow);
    }

    public function remove(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        return search(type, key, _Attribute, Delete, attributes, follow);
    }

    public function listen(type:Type, event:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $event.'));
        return result;
    }

}

@:nullSafety(Strict)
class HtmlInfo {

    @:persistent public static var handlers:Array<HtmlHandler> = [new StdHandler()];

    @:noCompletion public static function enhance():Void {
        #if (eval || macro)
        haxe.macro.Compiler.patchTypes("html.patch");
        #else
            #if !debug
                #error "This method is only meant to be called from `.hxml` files."
            #end
        #end
    }

    public static function setAttribute(type:Type, name:String, attributes:DynamicAccess<String>, ?follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var results = [];

        for (handler in handlers) {
            switch handler.set(type, name, attributes, follow) {
                case Success(fields):
                    for (field in fields) results.push(field);

                case Failure(failure):
                    return Failure(failure);

            }
        }

        return Success(results);
    }

    public static function getAttribute(t:Type, name:String, attributes:DynamicAccess<String>, ?follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var results = [];

        for (handler in handlers) {
            switch handler.get(t, name, attributes, follow) {
                case Success(fields):
                    for (field in fields) results.push(field);

                case Failure(failure):
                    return Failure(failure);

            }
        }

        return Success(results);
    }

    /*public static function defaultValues(t:Type, ?follow:Bool = false):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Unable to find @$_Default on ${t.getID()}.'));

        switch t {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                var emptyDefaults = [];
                var defaults = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(_Default)) {
                        var meta = field.meta.extract(_Default)[0];

                        (meta.params.length == 0 ? emptyDefaults : defaults)
                        .push( field );

                    }
                }

                var array:Array<ClassField> = emptyDefaults.concat( defaults );

                if (follow && cls.superClass != null) switch defaultValues( TInst(cls.superClass.t, cls.superClass.params), follow ) {
                    case Success(v): array = array.concat( v );
                    case _:
                }

                if (array.length > 0) result = Success(array);

            case x:
                #if debug
                trace( x );
                #end
        }

        return result;
    }*/

}