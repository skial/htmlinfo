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

@:forward
@:forwardStatics
enum abstract HtmlInfoDefines(Defines) from Defines to Defines {
    public var DebugHtml = 'debug_htmlinfo';
    @:to public inline function asBool():Bool {
		return haxe.macro.Context.defined(this);
	}
	@:op(A == B)
	@:commutative
	private static inline function equals(a:HtmlInfoDefines, b:Bool) {
		return a.asBool() == b;
	}
	@:op(!A)
	private static inline function negate(a:HtmlInfoDefines) {
		return !a.asBool();
	}
	@:op(A != B)
	@:commutative
	private static inline function not(a:HtmlInfoDefines, b:Bool) {
		return a.asBool() != b;
	}
	@:op(A && B)
	@:commutative
	private static inline function and(a:HtmlInfoDefines, b:Bool) {
		return a.asBool() && b;
	}
}

@:forward
@:forwardStatics
@:using(be.types.HtmlInfo.HtmlIDLUsings)
enum abstract HtmlIDL(String) to String from String {}

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

    public var max(get, never):Int;

    private inline function get_max():Int {
        return 3;
    }

    public var index(get, never):Int;

    private inline function get_index():Int {
        return switch this {
            case _Tag: 0;
            case _Attribute: 1;
            case _Events: 2;
            case _: -1;
        }
    }

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
@:using(be.types.HtmlInfo.HtmlActionUsings)
enum abstract Action(String) to String from String {
    public var Get = 'get';
    public var Set = 'set';
    public var Has = 'has';
    public var Delete = 'del';
    public var All = '_';

    //

    public var max(get, never):Int;

    private inline function get_max():Int {
        return 5;
    }

    public var index(get, never):Int;
    
    private inline function get_index():Int {
        return switch this {
            case Get: 0;
            case Set: 1;
            case Has: 2;
            case Delete: 3;
            case All: 4;
            case _: -1;
        }
    }

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

    public static function touch(entry:MetadataEntry, type:Type, fieldName:String = ''):DynamicAccess<String> {
        var index = (entry.name:HtmlMetadata).attr;
        var expr = entry.params[index];
        expr = expr == null ? macro null : expr;
        var key = entry.cacheKey(type, fieldName);
        return if (!CacheUtils.attributes.exists(key)) {
            var obj = switch expr {
                case _.expr => EObjectDecl(fields) if (fields.length > 0):
                    fields.asDynamicAccess();
    
                case _:
                    new DynamicAccess<String>();
            }
            CacheUtils.attributes.set(key, obj);
            obj;

        } else {
            CacheUtils.attributes.get(key);

        }
        
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
        Finds `self` in `entry` matching `ident` againsts `entry`. Returning its weight.
        Positive result is equal to `true`, negative result equal to `false`.
    **/
    public static function matches(self:HtmlMetadata, attributes:HtmlAttrs, entry:MetadataEntry, ident:HtmlIDL, type:Type, field:ClassField, action:Action = All):Int {
        // None of the metadata entries can be empty.
        if (entry.params.length == 0) return -1;

        var expected = self.index;
        var actual = (entry.name:HtmlMetadata).index;

        // Not a `HtmlMetadata` value.
        if (actual == -1) return actual;

        var name = self.ident > -1 ? entry.params[self.ident].toString().replace('"', '') : '/Z/>z>/Z/';
        var fit = self.action > -1 ? entry.params[self.action].toString().replace('"', '') : '/Z/>z>/Z/';
        var attrs:HtmlAttrs = entry.touch(type, field.name);

        if (Debug && DebugHtml) {
            trace( '<checking meta ...>' );
            trace( '⨽ action        : ' + action );
            trace( '    ⨽ ==        : ' + (action == fit) );
            trace( '⨽ on field      : ' + field.name );
            trace( '<ident matches ...>' );
            trace( '⨽ ident         : ' + ident );
            trace( '⨽ meta          : ' + name );
            trace( '    ⨽ ==        : ' + (name == ident || name == All) );
            trace( '    ⨽ cmp       : ' + Reflect.compare(ident, name) );
        }

        var identWeight = self.max;
        //identWeight = (expected - actual) + (Reflect.compare(ident, name));
        identWeight = ident.matches(name);

        var filterMax = attributes.max;
        var attrMax = attrs.max;
        var max = filterMax >= attrMax ? filterMax : attrMax;
        var min = filterMax <= attrMax ? filterMax : attrMax;
        var attrWeight = max - min;
        for (key => value in attrs) {
            attrWeight += attributes.matches(key, value);
        }

        // If somehow?! the value check againt Action isnt valid, -1
        // is returned, force to obscene positive value.
        // Dont use 0x7FFF,FFFF as the result would overflow on addition.
        var actionWeight = action.matches(fit) & 0x3FFFFFFF;
        var result = identWeight + attrWeight + actionWeight;

        if (Debug && DebugHtml) {
            trace( '<weights ...>' );
            trace( '⨽ ident         : ' + identWeight );
            trace( '⨽ attribute     : ' + attrWeight );
            trace( '⨽ action        : ' + actionWeight );
            trace( '⨽ total         : ' + result);

        }

        return result;
    }

}

@:nullSafety(Strict)
class HtmlIDLUsings {

    public static function matches(self:HtmlIDL, value:String):Int {
        if (Debug && DebugHtml) {
            trace( '<checking idl names...>' );
            trace( '⨽ self          : ' + self );
            trace( '⨽ value         : ' + value );
        }
        // If catch-all, return early.
        if (value == '_') return 0;
        var cmp = Reflect.compare(self, value);

        if (Debug && DebugHtml) {
            trace( '⨽ cmp           : ' + cmp );
        }
        // Perfect match, return early.
        if (cmp == 0) return cmp;
        var max = self.length >= value.length ? self.length : value.length;
        var min = self.length <= value.length ? self.length: value.length;

        if (Debug && DebugHtml) {
            trace( '⨽ max           : ' + max );
            trace( '⨽ min           : ' + min );
        }
        return max - min;
    }

}

@:nullSafety(Strict)
class HtmlActionUsings {

    public static function matches(self:Action, value:String):Int {
        // If catch-all, return early.
        if (self == All) return 0;

        var expected = self.index;
        var actual = (value:Action).index;

        if (Debug && DebugHtml) {
            trace( '<action matches...>' );
            trace( '⨽ self          : ' + self );
            trace( '⨽ value         : ' + value );
            trace( '⨽ expected      : ' + expected );
            trace( '⨽ actual        : ' + actual );
            trace( '⨽ returned      : ' + ((actual == -1) ? -1 : expected - actual) );
        }

        if (actual == -1) return actual;

        return expected - actual;
    }

}

@:forward
@:forwardStatics
@:using(be.types.HtmlInfo.HtmlAttrsUsing)
abstract HtmlAttrs(DynamicAccess<String>) from DynamicAccess<String> to DynamicAccess<String> {

    public var max(get, never):Int;

    private inline function get_max():Int {
        return this.keys().length * 2;
    }

}

@:nullSafety(Strict)
class HtmlAttrsUsing {

    public static function matches(self:HtmlAttrs, key:String, value:String):Int {
        var result = 2;

        if (Debug && DebugHtml) {
            trace( '<attr match...>' );
            trace( '⨽ key       : ' + key );
            trace( '    ⨽ exists: ' + self.exists(key) );
            trace( '⨽ value     : ' + value );
        }

        if (self.exists(key)) {
            result--;
            result += Reflect.compare(  value, self.get(key) );

            if (Debug && DebugHtml) {
                trace( '    ⨽ ==    : ' + self.get(key) );
                trace( '    ⨽ cmp   : ' + Reflect.compare( value, self.get(key) ) );
            }

            if (value == self.get(key)) {
                result--;

            }

        }

        return result;
    }

}

@:nullSafety(Strict)
class HtmlInfo {

    @:noCompletion public static function enhance():Void {
        #if (eval || macro)
        haxe.macro.Compiler.patchTypes("html.patch");
        #else
            #if !debug
                #error "This method is only meant to be called from `.hxml` files."
            #end
        #end
    }

    public static function search(type:Type, ident:String, metadata:HtmlMetadata, action:Action, attributes:HtmlAttrs, follow:Bool = true):Outcome<Array<MPair<ClassField, Int>>, Error> {
        var result:Outcome<Array<MPair<ClassField, Int>>, Error> = Failure(new Error('Failed to match against $ident.'));

        switch type {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                if (Debug && DebugHtml) {
                    trace( '<checking type ...>' );
                    trace( '⨽ type      : ' + cls.name );
                    trace( '<for ...>' );
                    trace( '⨽ ident     : ' + ident );
                    trace( '⨽ action    : ' + action );
                    trace( '⨽ attrs     : ' + attributes );

                }
                var array:Array<MPair<ClassField, Int>> = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(metadata)) {
                        var weight = 0;
                        var meta = field.meta.extract(metadata)[0];
                        // If ident is wildcard, then it matches the property name.
                        var metaWeight = metadata.matches(attributes, meta, (ident == All) ? field.name : ident, type, field, action);
                        if (metaWeight == -1) continue;

                        weight += metaWeight;
                        var key = meta.cacheKey(type, field.name);

                        if (Debug && DebugHtml) {
                            trace( '<checking ...>' );
                            trace( '⨽ field     : ' + field.name );
                            trace( '<keep ...>' );
                            trace( '⨽ bool      : ' + metaWeight );
                        }

                        array.push( new MPair(field, weight) );

                    }

                }

                if (follow && cls.superClass != null) {
                    if (Debug && DebugHtml) {
                        trace( '<checking parent ...>' );
                        trace( '⨽ name      : ' + cls.superClass.t.get().name );
                    }
                    switch search(TInst(cls.superClass.t, cls.superClass.params), ident, metadata, action, attributes, follow) {
                        case Success(values): for (value in values) {
                            value.b++;
                            array.push( value );
                        }
                        case _:
                    }

                }

                if (array.length > 0) result = Success(array);

            case x:
                if (Debug && DebugHtml) {
                    trace( x );
                }

        }

        return result;
    }

    public static function sort(outcome:Outcome<Array<MPair<ClassField, Int>>, Error>):Outcome<Array<ClassField>, Error> {
        return switch outcome {
            case Success(pairs):
                haxe.ds.ArraySort.sort( pairs, function(a, b) {
                    //return b.b - a.b;
                    if (a.b == b.b) return 0;
                    if (a.b > b.b) return 1;
                    return -1;
                } );
                Success(pairs.map( p -> p.a ));

            case Failure(failure):
                Failure(failure);
        }
    }

    public static inline function get(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        return sort( search(type, key, _Attribute, Get, attributes, follow) );
    }

    public static inline function set(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        return sort( search(type, key, _Attribute, Set, attributes, follow) );
    }

    public static inline function has(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error> {
        return sort( search(type, key, _Attribute, Has, attributes, follow) );
    }

    public static function remove(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        return sort( search(type, key, _Attribute, Delete, attributes, follow) );
    }

    public static function listen(type:Type, event:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $event.'));
        return result;
    }

    public static function setAttribute(type:Type, name:String, attributes:DynamicAccess<String>, ?follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var results = [];

        switch set(type, name, attributes, follow) {
            case Success(fields):
                for (field in fields) results.push(field);

            case Failure(failure):
                return Failure(failure);

        }

        return Success(results);
    }

    public static function getAttribute(type:Type, name:String, attributes:DynamicAccess<String>, ?follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var results = [];

        switch get(type, name, attributes, follow) {
            case Success(fields):
                for (field in fields) results.push(field);

            case Failure(failure):
                return Failure(failure);

        }

        return Success(results);
    }

    public static inline function defaultValues(type:Type, attributes:DynamicAccess<String>, ?follow:Bool = true):Outcome<Array<ClassField>, Error> {
        return sort( search(type, '_', _Attribute, All, attributes, follow));
    }

}