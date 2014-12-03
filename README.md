Starling extension for using bitmap fonts with simplified HTML tags for styling texts
___
HTMLTextField
=============

<code>HTMLTextField</code> is a Starling TextField for using with <il>simplified html notation</il>

<em>**HTMLTextField now supports font scaling to adapt font size, it will choose the nearest biggest font size you have registered. (or smaller if no bigger found)**</em>

___
ACCEPTED TAGS:
--------------

* **bold** : `<b></b>`;
* **italic** : `<i></i>`;
* **underlined** : `<u></u>`; <br/><em> you have to provide the underline texture with: <code>HTMLBitmapFonts.underlineTexture = yourTexture</code></em> for this to work.
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
* **links** : `<l="your-url.com">text to click</l>`; <br/><em>you can use <code>defaultLinkColor</code> var to auto colorize the links.</em>
* **dispatch Event** : `<f="string var to dispatch">text to click</f>`; <br/><em>you can use <code>defaultLinkColor</code> var to auto colorize the links.</em>

<i>HTMLTextField uses HTMLBitmapFonts instead of the tradtional BitmapFont.</i>

___
Usage:
-------------------------

To add a font for use with HTMLtextField you must add them to HTMLTextField with the static method <code>HTMLTextField.registerBitmapFont</code> this fonction accept as xml value the same XML as traditional BitmapFont.

They can be generated with tools like :
<ul>
	<li><a href="http://kvazars.com/littera/">Littera</a></li>
	<li><a href="http://www.angelcode.com/products/bmfont/">Bitmap Font Generator</a></li>
	<li><a href="http://glyphdesigner.71squared.com/">Glyph Designer</a></li>
</ul>

Personnaly i use AssetManager for loading fonts and i just modified it like this: <br/>
in loadQueue -> processXML :</br>

	// if I parse fontHTML -> load the font for HTMLTextFields
	else if( rootNode == "fontHTML" )
	{
		name 		= xml.info.@face.toString();
		fileName 	= getName(xml.pages.page.@file.toString());
		isBold 		= xml.info.@bold == 1;
		isItalic 	= xml.info.@italic == 1;
		
		log("Adding html bitmap font '" + name + "'" + " _bold: " + isBold + " _italic: " + isItalic );
		
		fontTexture = getTexture( fileName );
		HTMLTextField.registerBitmapFont( fontTexture, xml, xml.info.@size, isBold, isItalic, name.toLowerCase() );
		removeTexture( fileName, false );
		
		mLoadedHTMLFonts.push( name.toLowerCase() );
	}

___
Other things:
-------------------------

* You can add emotes to the text, just register the emotes shortcut and the texture associated.<br/>
<code>HTMLTextField.registerEmote( "{smiley}", mySmyleyTexture );</code><br/>
<em>you can configure offsets x and y, xAdvance, and margins for each emotes.</em>
* You can prevent auto carriage return by setting the <code>autoCR</code> var to <code>false</code>
* You can autorize the text to extend automaticaly if the text not fit by setting the <code>resizeField</code> var to <code>true</code>
* You can change the line spacing of the text by setting the <code>lineSpacing</code> var to something other than 0.
* Added left centered and right centered horizontal alignements rules, use <code>HTMLTextField.LEFT_CENTERED</code> and <code>HTMLTextField.RIGHT_CENTERED</code>.
* You can easily make shadows on the text by setting <code>shadowX</code>, <code>shadowY</code> and <code>shadowColor</code> vars.

___
Warnings:
-------------

* <em>Only **one font name** can be used in the HTMLTextField, it can only change size, bold, italic, and color</em>
* <em>All font styles must be on the **same atlas** as the textField is drawn on a QuadBatch</em>
* <em>All emotes registered must be on the **same atlas** as the textField is drawn on a QuadBatch</em>
* <em>The underline texture must be on the **same atlas** as the textField is drawn on a QuadBatch</em>
* <em>For better performance it's a must to start emote by **{** char</em>