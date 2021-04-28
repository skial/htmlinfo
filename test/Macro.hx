package ;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Defines;
import be.types.HtmlInfo.HtmlInfoDefines;

using tink.MacroApi;
using be.types.HtmlInfo;
#end

class Macro {

    public static macro function defaults(element:Expr):Expr {
        var type = element.typeof().sure();
        var expr = element;

        switch type.defaultValues({}, true) {
            case Success(fields): 
                if (Debug && DebugHtml) {
                    for (field in fields) {
                        trace(field.name);
                    }
                }

                var property = fields[0].name;
                expr = macro @:pos(element.pos) $e{element}.$property;

            case Failure(failure):
                trace( failure );

        }

        return expr;
    }

    public static macro function read(element:Expr, field:String, ?expected:Type):Expr {
        if (Debug && DebugHtml) trace( '<read attr ${field}...>' );
        var type = element.typeof().sure();
        var expr = element;
        
        switch type.getAttribute(field, {}, true) {
            case Success(fields):
                if (Debug && DebugHtml) {
                    trace( '<found fields ...>' );
                    trace( 'for attr    : ' + field );
                    for (field in fields) {
                        trace( '⨽ field     : ' + field.name );
                    }

                }

                var property = fields[0].name;
                expr = macro @:pos(element.pos) $e{element}.$property;

            case Failure(failure):
                trace( failure );
        }

        return expr;
    }

    public static macro function write(element:Expr, field:String, ?expected:Type):Expr {
        if (Debug && DebugHtml) trace( '<write attr ${field}...>' );
        var type = element.typeof().sure();
        var expr = element;
        
        switch type.setAttribute(field, {}, true) {
            case Success(fields):
                if (Debug && DebugHtml) {
                    trace( '<found fields ...>' );
                    trace( 'for attr    : ' + field );
                    for (field in fields) {
                        trace( '⨽ field     : ' + field.name );
                    }

                }

                var property = fields[0].name;
                expr = macro @:pos(element.pos) $e{element}.$property;

            case Failure(failure):
                trace( failure );
        }

        return expr;
    }

}