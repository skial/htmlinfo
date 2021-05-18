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

    public static macro function has(element:Expr, field:String, ?obj:haxe.DynamicAccess<String>):ExprOf<Bool> {
        if (Debug && DebugHtml) trace( '<has attr ${field}...>' );
        var type = element.typeof().sure();
        var expr = element;

        var info = HtmlInfo.info( type );
        if (obj == null) obj = info.attributes;
        if (obj.keys().length == 0) obj = info.attributes;
        
        switch type.hasAttribute(field, obj, true) {
            case Success(fields):
                if (Debug && DebugHtml) {
                    trace( '<found fields ...>' );
                    trace( 'for attr    : ' + field );
                    for (field in fields) {
                        trace( '⨽ field     : ' + field.name );
                    }

                }

                var property = fields[0].name;
                expr = macro @:pos(element.pos) $e{element}.$property($v{field});

            case Failure(failure):
                trace( failure );
        }

        return expr;
    }

    public static macro function access(element:Expr, ?obj:haxe.DynamicAccess<String>):Expr {
        var type = element.typeof().sure();
        var expr = element;

        var info = HtmlInfo.info( type );
        if (obj == null) obj = info.attributes;
        if (obj.keys().length == 0) obj = info.attributes;

        switch type.defaultValues(obj, true) {
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

    public static macro function read(element:Expr, field:String, ?obj:haxe.DynamicAccess<String>):Expr {
        if (Debug && DebugHtml) trace( '<read attr ${field}...>' );
        var type = element.typeof().sure();
        var expr = element;

        var info = HtmlInfo.info( type );
        if (obj == null) obj = info.attributes;
        if (obj.keys().length == 0) obj = info.attributes;
        
        switch type.getAttribute(field, obj, true) {
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

    public static macro function write(element:Expr, field:String, ?obj:haxe.DynamicAccess<String>):Expr {
        if (Debug && DebugHtml) trace( '<write attr ${field}...>' );
        var type = element.typeof().sure();
        var expr = element;

        var info = HtmlInfo.info( type );
        if (obj == null) obj = info.attributes;
        if (obj.keys().length == 0) obj = info.attributes;
        
        switch type.setAttribute(field, obj, true) {
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

    public static macro function delete(element:Expr, field:String, ?obj:haxe.DynamicAccess<String>):ExprOf<Void> {
        if (Debug && DebugHtml) trace( '<delete attr ${field}...>' );
        var type = element.typeof().sure();
        var expr = element;

        var info = HtmlInfo.info( type );
        if (obj == null) obj = info.attributes;
        if (obj.keys().length == 0) obj = info.attributes;
        
        switch type.removeAttribute(field, obj, true) {
            case Success(fields):
                if (Debug && DebugHtml) {
                    trace( '<found fields ...>' );
                    trace( 'for attr    : ' + field );
                    for (field in fields) {
                        trace( '⨽ field     : ' + field.name );
                    }

                }

                var property = fields[0].name;
                expr = macro @:pos(element.pos) $e{element}.$property($v{field});

            case Failure(failure):
                trace( failure );
        }

        return expr;
    }

}