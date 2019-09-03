package be.types;

import haxe.macro.Type;
import haxe.macro.Expr;

using tink.CoreApi;
using tink.MacroApi;

enum abstract HtmlMetadata(String) to String from String {
    var _Default = ':default';
    var _PairedAttribute = ':html.attr';
    var _HtmlAst = ':html.ast';

    @:to public inline function asParamLength() return switch this {
        case _PairedAttribute: 2;
        case _: 0;
    }

}

@:forward @:forwardStatics @:notNull abstract HtmlClassField(ClassField) to ClassField {

    public inline function new(v) this = v;

    //@:to public inline function asType():Type return this.a;
    //@:to public inline function asClassField():ClassField return this.b;

}

class Html {

    @:noCompletion public static function enhance():Void {
        #if (eval || macro)
        haxe.macro.Compiler.patchTypes("html.patch");
        #else
            #if !debug
                #error "This method is only meant to be called from `.hxml` files."
            #end
        #end
    }

    public static function setAttribute(t:Type, attribute:String, ?follow:Bool = false):Outcome<Array<HtmlClassField>, Error> {
        var result:Outcome<Array<HtmlClassField>, Error> = Failure(new Error('Failed to match against $attribute.'));

        switch t {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                var empty:Array<HtmlClassField> = [];
                var setter:Array<HtmlClassField> = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(_PairedAttribute)) {
                        var meta = field.meta.extract(_PairedAttribute)[0];

                        if (meta.params.length == 0) continue;

                        var value = meta.params[0].toString();
                        if (value == '"$attribute"' || value == '_') {
                            if (meta.params.length > 1 && meta.params[1].toString() == 'set') {
                                setter.push( new HtmlClassField(field) );
                                
                            } else if (meta.params.length == 1) {
                                empty.push( new HtmlClassField(field) );

                            }

                        }

                    }

                }

                var array:Array<HtmlClassField> = setter.concat( empty );

                if (follow && cls.superClass != null) switch setAttribute(TInst(cls.superClass.t, cls.superClass.params), attribute, follow) {
                    case Success(values): array = array.concat(values);
                    case _:
                }

                if (array.length > 0) result = Success(array);

            case x:
                #if debug
                trace( x );
                #end

        }

        return result;
    }

    public static function getAttribute(t:Type, attribute:String, ?follow:Bool = false):Outcome<Array<HtmlClassField>, Error> {
        var result:Outcome<Array<HtmlClassField>, Error> = Failure(new Error('Failed to match against $attribute.'));

        switch t {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                var empty:Array<HtmlClassField> = [];
                var setter:Array<HtmlClassField> = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(_PairedAttribute)) {
                        var meta = field.meta.extract(_PairedAttribute)[0];

                        if (meta.params.length == 0) continue;

                        var value = meta.params[0].toString();
                        if (value == '"$attribute"' || value == '_') {
                            if (meta.params.length > 1 && meta.params[1].toString() == 'get') {
                                setter.push( new HtmlClassField(field) );

                            } else if (meta.params.length == 1) {
                                empty.push( new HtmlClassField(field) );

                            }

                        }

                    }

                }

                var array:Array<HtmlClassField> = setter.concat( empty );

                if (follow && cls.superClass != null) switch getAttribute(TInst(cls.superClass.t, cls.superClass.params), attribute, follow) {
                    case Success(values): array = array.concat(values);
                    case _:
                }

                if (array.length > 0) result = Success(array);

            case x:
                #if debug
                trace( x );
                #end

        }

        return result;
    }

    public static function defaultValues(t:Type, ?follow:Bool = false):Outcome<Array<HtmlClassField>, Error> {
        var result:Outcome<Array<HtmlClassField>, Error> = Failure(new Error('Unable to find @$_Default on ${t.getID()}.'));

        switch t {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                var emptyDefaults = [];
                var defaults = [];

                for (field in cls.fields.get()) {
                    if (field.meta.has(_Default)) {
                        var meta = field.meta.extract(_Default)[0];

                        (meta.params.length == 0 ? emptyDefaults : defaults)
                        .push( new HtmlClassField(field) );

                    }
                }

                var array:Array<HtmlClassField> = emptyDefaults.concat( defaults );

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
    }

}