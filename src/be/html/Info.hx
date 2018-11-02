package be.html;

import haxe.macro.Type;
import haxe.macro.Expr;

using tink.MacroApi;

enum abstract HtmlFieldMetadata(String) to String from String {
    var _Default = ':default';
    var _PairedAttribute = ':html.attr';
}

class Info {

    public static function attributeAccess(t:Type, attribute:String, ?follow:Bool = false):Null<ClassField> {
        var result = null;

        switch t {
            case TInst(_.get() => cls, _) if (cls.isExtern):
                for (field in cls.fields.get()) {
                    if (field.meta.has(_PairedAttribute)) {
                        var meta = field.meta.extract(_PairedAttribute);
                        if (meta[0].params.map(p->p.toString()).indexOf('"$attribute"') > -1) {    
                            result = field;
                            break;
                        }

                    }

                }

            case x:
                #if debug
                trace( x );
                #end

        }

        return result;
    }

    public static function defaultValues(t:Type, ?follow:Bool = false):Null<Array<ClassField>> {
        var result = null;

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

                result = emptyDefaults.concat( defaults );

                if (follow && cls.superClass != null) {
                    result = result.concat( defaultValues( TInst(cls.superClass.t, cls.superClass.params), follow ) );
                }

            case x:
                #if debug
                trace( x );
                #end
        }

        return result;
    }

}