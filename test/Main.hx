package ;

class Main {

    public static function main() {
        var element:js.html.InputElement = cast js.Browser.document.querySelectorAll('input[type="text"]')[0];
        trace( Macro.has(element, 'value') );
        // Returns `element.value`, nothing special...
        trace( Macro.read(element, 'value') );
        // Returns `element.defaultValue`, which is the native property used to update the html `value` attribute.
        trace( Macro.write(element, 'value') = "hello haxe world" );
        // Just want to read the elements value, via any default property.
        trace( Macro.access(element) );
        Macro.delete(element, 'value');

        // These three should generate the exact same fields as above, 
        // as {type:text} is the default type for all inputs.
        trace( Macro.has(element, 'value', {type:"text"}) );
        trace( Macro.read(element, 'value', {type:"text"}) );
        trace( Macro.write(element, 'value', {type:"text"}) = "hello haxe world" );
        trace( Macro.access(element, {type:"text"}) );
        Macro.delete(element, 'value', {type:"text"});

        element = cast js.Browser.document.querySelectorAll('input[type="checkbox"]')[0];
        trace( Macro.has(element, 'checked', {type:"checkbox"}) );
        trace( Macro.read(element, 'checked', {type:"checkbox"}) );
        trace( Macro.write(element, 'checked', {type:"checkbox"}) = true );
        trace( Macro.has(element, 'checked', {type:"checkbox"}) );
        trace( Macro.access(element, {type:"checkbox"}) );
        Macro.delete(element, 'checked', {type:"checkbox"});
        trace( Macro.has(element, 'checked', {type:"checkbox"}) );
        
    }

}