Starling extension for using bitmap fonts with simplified HTML tags for styling texts
___
HTMLTextField
=============

<code>HTMLTextField</code> is a Starling TextField for using with <il>simplified html notation</il>

<em>**This version supports only Device Fonts**</em>

___
ACCEPTED TAGS:
--------------

* **bold** : `<b></b>`;
* **italic** : `<i></i>`;
* **underlined** : `<u></u>`; <br/>
* **size**   : `<size="10"></size>` or `<s="10"></s>`;
* **colors** : _don't forget '0x' or '#' !_
 * **solid** : <br/>
 `<color="0xFF0000"></color>` or <br/>
 `<c="0xFF0000"></c>`;
 * **gradient up / down** : <br/>
 `<color="0xFF0000,0xFFFFFF"></color>` or <br/>
 `<c="0xFF0000,0xFFFFFF"></c>;`
 * **gradient up-left/up-right/down-left/down-right** : <br/>
 `<color="0xFF0000,0xFFFFFF,0x000000,0x0000FF"></color>` or <br/>
 `<c="0xFF0000,0xFFFFFF,0x000000,0x0000FF"></c>`
* **links** : `<l="your-url.com">text to click</l>`; <br/>
 * <em>you can use <code>defaultLinkColor</code> var to auto colorize the links.</em>
 * <em>you can define a function to navigate to url for just one textField with <code>myTextField.navigateToURLFunction = function(url:String):void{...}</code></em>
 * <em>you can define a function to navigate to url for all textFields with the static function <code>HTMLTextField.navigateToURLFunction = function(url:String):void{...}</code></em>
 * <em>by default the <code>navigateToURLFunction</code> function internaly uses the <code>flash.net.navigateToURL</code> function</em>
* **dispatch Event** : `<f="string var to dispatch">text to click</f>`; <br/>
 * <em>you can use <code>defaultLinkColor</code> var to auto colorize the links.</em>
* **shadow** : `<o="shadowX,shadowY">`;
 * <em>as you enable shadow, the whole TextField will have the shadow on it, the last shadow defined will be applied</em>
* **stroke** : `<a="size,color,strength">`;
 * <em>as you enable stroke, the whole TextField will have the stroke on it, the last stroke defined will be applied</em>

___
Usefull things:
-------------------------

* You can add emotes to the text, just register the emotes shortcut and the flash DisplayObject associated.<br/>
<code>HTMLDeviceFonts.registerEmote( "{smiley}", mySmyleyClip );</code><br/>
* You can prevent auto carriage return by setting the <code>autoCR</code> var to <code>false</code>
* You can autorize the text to extend automaticaly if the text not fit by setting the <code>resizeField</code> var to <code>true</code>
* You can change the line spacing of the text by setting the <code>lineSpacing</code> var to something other than 0.
* Added left centered and right centered horizontal alignements rules, use <code>HTMLTextField.LEFT_CENTERED</code> and <code>HTMLTextField.RIGHT_CENTERED</code>.
* You can easily make shadows on the text by setting <code>shadowX</code>, <code>shadowY</code> and <code>shadowColor</code> vars.
* You can limit the min font size when <code>autoScale</code> is <code>true</code> with the <code>minFontSize</code> var.

___
Usage:
-------------------------

You can see the DeviceFontSample to see how it works.