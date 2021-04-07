package ;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;

using tink.MacroApi;
using be.types.Html;
#end

class Macro {

    public static macro function read(element:Expr, ?field:String, ?expected:Type):Expr {
        var type = element.typeof().sure();
        var expr = element;
        
        // Look for default argument to read from.
        if (field == null && expected != null) {

        } else if (field != null) {
            switch type.getAttribute(field, {}, true) {
                case Success(fields):
                    for (field in fields) {
                        trace( field.name );
                    }

                    var property = fields[0].name;
                    expr = macro @:pos(element.pos) $e{element}.$property;

                case Failure(failure):
                    trace( failure );
            }

        }

        return expr;
    }

    public static macro function write(element:Expr, ?field:String, ?expected:Type):Expr {
        var type = element.typeof().sure();
        var expr = element;
        
        // Look for default argument to read from.
        if (field == null && expected != null) {

        } else if (field != null) {
            switch type.setAttribute(field, {}, true) {
                case Success(fields):
                    for (field in fields) {
                        trace( field.name );
                    }

                    var property = fields[0].name;
                    expr = macro @:pos(element.pos) $e{element}.$property;

                case Failure(failure):
                    trace( failure );
            }

        }

        return expr;
    }

}