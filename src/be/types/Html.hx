package be.types;

import haxe.DynamicAccess;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Defines;

using tink.CoreApi;
using tink.MacroApi;

@:forward
@:forwardStatics
@:using(be.types.Html.HtmlMetadataUsings)
enum abstract HtmlMetadata(String) to String from String {
    // @:html.tag(string, bool) $type
    var _Tag = ':html.tag';
    // @:html.attr(string, ?access, ?attributes) $property
    var _Attribute = ':html.attr';
    // @:html.events(array<string>, ?attributes) $type
    var _Events = ':html.events';

}

class HtmlMetadataUsings {
    
    public static function matches(self:HtmlMetadata, entry:MetadataEntry, ident:String, attributes:DynamicAccess<String>):Bool {
        return switch self {
            case _Attribute:
                true;

            case _Events:
                true;

            case _:
                false;
        }
    }

}

interface HtmlHandler {
    function get(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error>;
    function set(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error>;
    function has(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<{runtime:Array<ClassField>, comptime:Null<Bool>}, Error>;
    function remove(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error>;
    function listen(type:Type, event:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error>;
}

@:forward
@:forwardStatics
enum abstract Access(String) to String from String {
    public var Get = 'get';
    public var Set = 'set';
    public var All = '_';
}

class StdHandler implements HtmlHandler {

    public function search(type:Type, ident:String, metadata:HtmlMetadata, access:Access, filters:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $ident.'));

        switch type {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                var empty:Array<ClassField> = [];
                var getter:Array<ClassField> = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(metadata)) {
                        var meta = field.meta.extract(metadata)[0];

                        if (meta.params.length == 0) continue;

                        var value = meta.params[0].toString();
                        if (Debug) trace( ident, value );
                        if (value == '"$ident"' || value == '_') {
                            if (meta.params.length > 1 && meta.params[1].toString() == access) {
                                getter.push( field );

                            } else if (meta.params.length == 1) {
                                empty.push( field );

                            }

                        }

                    }

                }

                var array:Array<ClassField> = getter.concat( empty );

                if (follow && cls.superClass != null) {
                    switch get(TInst(cls.superClass.t, cls.superClass.params), key, attributes, follow) {
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

    public function get(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        
    }

    public function set(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $key.'));
        return result;
    }

    public function has(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<{runtime:Array<ClassField>, comptime:Null<Bool>}, Error> {
        var result:Outcome<{runtime:Array<ClassField>, comptime:Null<Bool>}, Error> = Failure(new Error('Failed to match against $key.'));
        return result;
    }

    public function remove(type:Type, key:String, attributes:DynamicAccess<String>, follow:Bool = true/*, persist:Bool = true*/):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $key.'));
        return result;
    }

    public function listen(type:Type, event:String, attributes:DynamicAccess<String>, follow:Bool = true):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $event.'));
        return result;
    }

}

class Html {

    @:persistent public static var handlers:Array<HtmlHandler> = [];

    @:noCompletion public static function enhance():Void {
        #if (eval || macro)
        haxe.macro.Compiler.patchTypes("html.patch");
        #else
            #if !debug
                #error "This method is only meant to be called from `.hxml` files."
            #end
        #end
    }

    public static function setAttribute(t:Type, attribute:String, ?follow:Bool = false):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $attribute.'));

        switch t {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                var empty:Array<ClassField> = [];
                var setter:Array<ClassField> = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(_Attribute)) {
                        var meta = field.meta.extract(_Attribute)[0];

                        if (meta.params.length == 0) continue;

                        var value = meta.params[0].toString();
                        if (value == '"$attribute"' || value == '_') {
                            if (meta.params.length > 1 && meta.params[1].toString() == 'set') {
                                setter.push( field );
                                
                            } else if (meta.params.length == 1) {
                                empty.push( field );

                            }

                        }

                    }

                }

                var array:Array<ClassField> = setter.concat( empty );

                if (follow && cls.superClass != null) switch setAttribute(TInst(cls.superClass.t, cls.superClass.params), attribute, follow) {
                    case Success(values): array = array.concat(values);
                    case _:
                }

                if (array.length > 0) result = Success(array);

            case x:
                if (Debug) {
                    trace( x );
                }

        }

        return result;
    }

    public static function getAttribute(t:Type, attribute:String, ?follow:Bool = false):Outcome<Array<ClassField>, Error> {
        var result:Outcome<Array<ClassField>, Error> = Failure(new Error('Failed to match against $attribute.'));

        switch t {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                var empty:Array<ClassField> = [];
                var setter:Array<ClassField> = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(_Attribute)) {
                        var meta = field.meta.extract(_Attribute)[0];

                        if (meta.params.length == 0) continue;

                        var value = meta.params[0].toString();
                        if (value == '"$attribute"' || value == '_') {
                            if (meta.params.length > 1 && meta.params[1].toString() == 'get') {
                                setter.push( field );

                            } else if (meta.params.length == 1) {
                                empty.push( field );

                            }

                        }

                    }

                }

                var array:Array<ClassField> = setter.concat( empty );

                if (follow && cls.superClass != null) switch getAttribute(TInst(cls.superClass.t, cls.superClass.params), attribute, follow) {
                    case Success(values): array = array.concat(values);
                    case _:
                }

                if (array.length > 0) result = Success(array);

            case x:
                if (Debug) {
                    trace( x );
                }

        }

        return result;
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