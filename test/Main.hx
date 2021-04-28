package ;

class Main {

    public static function main() {
        var element:js.html.InputElement = cast js.Browser.document.getElementById('input-test');
        // Returns `element.value`, nothing special...
        trace( Macro.read(element, 'value') );
        // Returns `element.defaultValue`, which is the native property used to update the html `value` attribute.
        trace( Macro.write(element, 'value') = "hello haxe world" );
        // Just want to read the elements value, via any default property.
        trace( Macro.defaults(element) );
    }

}