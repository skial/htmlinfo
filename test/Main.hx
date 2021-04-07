package ;

class Main {

    public static function main() {
        var element:js.html.InputElement = cast js.Browser.document.getElementById('input-test');
        // Returns `element.value`, nothing special...
        trace( Macro.read(element, 'value') );
        // Returns `element.defaultValue`, which is the native property field to use to update the html `value` attribute.
        trace( Macro.write(element, 'value') = "hello haxe world" );
    }

}