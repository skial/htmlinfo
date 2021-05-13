package be.types;

import haxe.ds.ArraySort;
import haxe.ds.StringMap;
import haxe.DynamicAccess;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Defines;
import hx.strings.Strings;

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
enum abstract HtmlIDL(String) to String from String {

    public function matches(value:String):Int {
        if (Debug && DebugHtml) {
            trace( '<checking idl names...>' );
            trace( '⨽ self          : ' + this );
            trace( '⨽ value         : ' + value );
        }
        // If catch-all, return early.
        if (value == '_') return 0;
        //var cmp = Reflect.compare(this, value);
        var cmp = Strings.getLevenshteinDistance(this, value);

        if (Debug && DebugHtml) {
            trace( '⨽ diff          : ' + cmp );
        }
        // Perfect match, return early.
        /*if (cmp == 0) return cmp;
        var max = this.length >= value.length ? this.length : value.length;
        var min = this.length <= value.length ? this.length: value.length;

        if (Debug && DebugHtml) {
            trace( '⨽ max           : ' + max );
            trace( '⨽ min           : ' + min );
        }
        return max - min;*/
        return cmp;
    }

}

@:forward
@:forwardStatics
enum abstract HtmlMetadata(String) to String from String {
    // @:html.tag(string, ?attributes) $type
    var _Tag = ':html.tag';
    // @:html.attr(string, ?access, ?attributes) $type.$property
    var _Attribute = ':html.attr';
    // @:html.events(array<string>, ?attributes) $type
    var _Events = ':html.events';
    // @:html.category(value:Category, ?attributes) $type
    var _Category = ':html.category';
    // @:html.kind(value:ElementKind) $type
    var _Kind = ':html.kind';

    //

    public var max(get, never):Int;

    private inline function get_max():Int {
        return 5;
    }
    
    public var index(get, never):Int;

    private inline function get_index():Int {
        return switch this {
            case _Tag: 0;
            case _Attribute: 1;
            case _Events: 2;
            case _Category: 3;
            case _Kind: 4;
            case _: -1;
        }
    }

    public var ident(get, never):Int;

    private inline function get_ident():Int {
        return switch this {
            case _Tag, _Attribute, _Events, _Category, _Kind: 0;
            case _: -1;
        }
    }

    public var attr(get, never):Int;

    private inline function get_attr():Int {
        return switch this {
            //case _Tag: -1;
            case _Attribute: 2;
            case _Tag, _Events, _Category: 1;
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

    //

    /**
        Finds `self` in `entry` matching `ident` againsts `entry`. Returning its weight.
        Positive result is equal to `true`, negative result equal to `false`.
    **/
    public function matches(attributes:HtmlAttrs, entry:MetadataEntry, ident:HtmlIDL, type:Type, field:ClassField, action:Action = All):Int {
        // None of the metadata entries can be empty.
        if (entry.params.length == 0) return -1;

        var self:HtmlMetadata = this;
        //var expected = self.index;
        var actual = (entry.name:HtmlMetadata).index;

        // Not a `HtmlMetadata` value.
        if (actual == -1) return actual;

        var name = self.ident > -1 ? entry.params[self.ident].toString().replace('"', '') : '/Z/>z>/Z/';
        var fit = self.action > -1 ? entry.params[self.action].toString().replace('"', '') : '/Z/>z>/Z/';
        var attrs:HtmlAttrs = entry.touch(type, field.name);

        if (Debug && DebugHtml) {
            trace( '<checking information ...>' );
            trace( '⨽ on field      : ' + field.name );
        }

        var identWeight = ident.matches(name);
        var filterMax = attributes.max;
        var attrMax = attrs.max;
        var max = filterMax >= attrMax ? filterMax : attrMax;
        var min = filterMax <= attrMax ? filterMax : attrMax;
        var attrWeight = 0;
        
        for (key => value in attrs) {
            attrWeight += attributes.matches(key, value);
        }
        
        attrWeight *= max;

        // If somehow?! the value check againt Action isnt valid, -1
        // is returned, force to obscene positive value.
        // Dont use 0x7FFF,FFFF as the result would overflow on addition.
        var actionWeight = action.matches(fit);
        if (actionWeight == -1) return -1;
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

@:forward
@:forwardStatics
enum abstract Action(Int) to Int from Int {
    public var Get = 0x67;      // g.code | 103 | 0b0110,0111
    public var Set = 0x73;      // s.code | 115 | 0b0111,0011
    public var Has = 0x68;      // h.code | 104 | 0b0110,1000
    public var Delete = 0x64;   // d.code | 100 | 0b0110,0100
    public var All = 0x5F;      // _.code | 95  | 0b0101,1111
    public var Access = 0x21;   // !.code | 33  | 0b0010,0001

    @:from private static inline function fromString(value:String):Action {
        return switch value.toLowerCase() {
            case 'get': Get;
            case 'set': Set;
            case 'has': Has;
            case 'del': Delete;
            case '_': All;
            case '!': Access;
            case _: Access;
        }
    }

    public inline function toString():String {
        return switch this {
            case Get: 'get';
            case Set: 'set';
            case Has: 'has';
            case Delete: 'del';
            case All: '_';
            case Access: '{g/s}et';
            case _: '<null>';
        }
    }

    //

    public var max(get, never):Int;

    private inline function get_max():Int {
        return 6;
    }

    public var index(get, never):Int;
    
    private inline function get_index():Int {
        return switch this {
            case Get: 0;
            case Set: 1;
            case Has: 2;
            case Delete: 3;
            case All: 4;
            case Access: 5;
            case _: -1;
        }
    }

    public function matches(value:String):Int {
        var self:Action = this;
        var value:Action = value;
        // If catch-all, return early.
        /*if (self == All) return 0;
*/
        if (Debug && DebugHtml) {
            trace( '<action matches...>' );
            trace( '⨽ self          : ' + self );
            trace( '    ⨽ int       : ' + (self:Int) );
            trace( '⨽ value         : ' + value );
            trace( '    ⨽ int       : ' + (value:Int) );
        }
/*
        return if ((self:Int) > (All:Int)) {
            if (Debug && DebugHtml) {
                trace( '... exact match ... ${this == value ? 0 : -1}' );
            }
            this == value ? 0 : -1;

        } else {
            if (Debug && DebugHtml) {
                trace( '... {g/s}et match ... ${self & value == Access ? 0 : -1}' );
            }
            self & value == Access ? 0 : -1;
            
        }*/
        var lhs = self;
        var rhs = value;

        if (Debug && DebugHtml) {
            trace( 'lhs     : ' + (lhs:Int) );
            trace( 'rhs     : ' + (rhs:Int) );
        }

        if (lhs == All) return 0;
        if (rhs == All) return 0;

        if ((lhs:Int) < (rhs:Int)) {
            var tmp = lhs;
            lhs = rhs;
            rhs = tmp;
        }

        if ((lhs:Int) > (All:Int) && (rhs:Int) > (All:Int)) {
            return lhs == rhs ? 0 : -1;
        }

        if (Debug && DebugHtml) {
            trace( 'lhs     : ' + (lhs:Int) );
            trace( 'rhs     : ' + (rhs:Int) );
            trace( ' -      : ' + (((lhs:Int) & (rhs:Int)) ^ rhs ));
        }

        return (((lhs:Int) & (rhs:Int)) ^ rhs) == 0 ? 0 : -1;
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
            obj.set( field.field, field.expr.toString().replace('"', '') );
        }

        return obj;
    }

}

@:forward
@:forwardStatics
abstract HtmlAttrs(DynamicAccess<String>) from DynamicAccess<String> to DynamicAccess<String> {

    public var max(get, never):Int;

    private inline function get_max():Int {
        return this.keys().length * 2;
    }

    public function matches(key:String, value:String):Int {
        var result = 2;
        var diff = 0;

        if (Debug && DebugHtml) {
            trace( '<attr match...>' );
            trace( '⨽ key       : ' + key );
            trace( '    ⨽ exists: ' + this.exists(key) );
            trace( '⨽ value     : ' + value );
        }

        if (this.exists(key)) {
            result--;
            diff += Strings.getLevenshteinDistance(value, this.get(key) );

            if (Debug && DebugHtml) {
                trace( '    ⨽ ==    : ' + this.get(key) );
                trace( '    ⨽ diff : ' + Strings.getLevenshteinDistance(value, this.get(key) ) );
            }

            if (value == this.get(key)) {
                result--;
                

            } else {
                diff += result;

            }

        } else {
            diff += key.length;
            
        }

        return result + diff;
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

    public static function info(type:Type, ?attributes:HtmlAttrs) {
        if (attributes == null) attributes = {};
        var category = be.html.Category.Unknown;
        var kind = be.html.ElementKind.Normal;
        var name:be.html.ElementName = cast 'unknown';
        var attrs:HtmlAttrs = {};

        var entries = [];
        var metas = type.getMeta();

        for (meta in metas) {
            if (meta.has(_Tag)) {
                entries = meta.extract(_Tag);

                for (entry in entries) {
                    switch entry.params[_Tag.ident] {
                        case _.expr => EConst(CString(value, _)):
                            name = cast value;

                        case _:

                    }

                    if (entry.params[_Tag.attr] != null) {
                        attrs = entry.touch(type);
                    }
    
                }

            }
            
            if (meta.has(_Category)) {
                entries = meta.extract(_Category);

                // TODO sort categories based on category value. See category graph in spec.
                // TODO remove null check and handle attribute filter.
                for (entry in entries) if (entry.params[_Category.attr] == null) {
                   switch entry.params[_Category.ident] {
                       case _.expr => EConst(CIdent(id)):
                            switch id {
                                case 'Metadata': category = be.html.Category.Metadata;
                                case 'Flow': category = be.html.Category.Flow;
                                case 'Sectioning': category = be.html.Category.Sectioning;
                                case 'Heading': category = be.html.Category.Heading;
                                case 'Phrasing': category = be.html.Category.Phrasing;
                                case 'Embedded': category = be.html.Category.Embedded;
                                case 'Interactive': category = be.html.Category.Interactive;
                                case 'Palpable': category = be.html.Category.Palpable;
                                case 'Scripted': category = be.html.Category.Scripted;
                                case 'Root': category = be.html.Category.Root;
                                case _:
                            }
                        
                       case _:

                   }
    
                }

            }
            
            if (meta.has(_Kind)) {
                entries = meta.extract(_Kind);

                for (entry in entries) {
                    switch entry.params[_Kind.ident] {
                        case _.expr => EConst(CIdent(id)):
                            switch id {
                                case 'Empty': kind = be.html.ElementKind.Empty;
                                case 'Template': kind = be.html.ElementKind.Template;
                                case 'Raw': kind = be.html.ElementKind.Raw;
                                case 'Escapable': kind = be.html.ElementKind.Escapable;
                                case 'Foreign': kind = be.html.ElementKind.Foreign;
                                case _:
                            }

                        case _:

                    }
    
                }
                
            }

        }

        return { name: name, attributes: attrs, kind: kind, category: category };
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
                        var metas = field.meta.extract(metadata);
                        var weights = [];

                        for (meta in metas) {
                            var weight = 0;
                            // If ident is wildcard, then it matches the property name.
                            var metaWeight = metadata.matches(attributes, meta, (ident == All) ? field.name : ident, type, field, action);
                            if (metaWeight == -1) {
                                if (Debug && DebugHtml) {
                                    trace( '<skipping ${field.name}...>');
                                }
                                continue;
                            }

                            weight += metaWeight;
                            //var key = meta.cacheKey(type, field.name);

                            if (Debug && DebugHtml) {
                                trace( '<checking ...>' );
                                trace( '⨽ field     : ' + field.name );
                                trace( '<keep ...>' );
                                trace( '⨽ bool      : ' + metaWeight );
                            }

                            weights.push( new MPair(field, weight) );

                        }

                        if (Debug && DebugHtml) {
                            for (w in weights) trace( w.a.name + ' : ' + w.b );
                        }
                        
                        // Sort smallest...largest
                        ArraySort.sort(weights, (a, b) -> {
                            return a.b - b.b;
                        } );

                        if (Debug && DebugHtml) {
                            for (w in weights) trace( w.a.name + ' : ' + w.b );
                        }
                        
                        if (weights.length > 0) {
                            // Pick the smallest weighted pair.
                            array.push( weights[0] );
                        }

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
                    if (a.b == b.b) return 0;
                    if (a.b > b.b) return 1;
                    return -1;
                } );
                if (Debug && DebugHtml) {
                    for (pair in pairs) {
                        trace( pair.a.name + ' : ' + pair.b );
                    }
                }
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
        return sort( search(type, '_', _Attribute, Access, attributes, follow));
    }

}