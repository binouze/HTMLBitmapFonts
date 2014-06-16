Starling extension for using bitmap fonts with simplified html tags for styling texts

_sorry all asdoc and comments are in french, i will change it soon_ 
___

HTMLTextField
=============

<code>HTMLTextField</code> is a Starling TextField for using with <il>simplified html notation</il> (just for styling: no links, no images...).


ACCEPTED TAGS:
--------------


* **bold** : `<b></b>`;
* **italic** : `<i></i>`;
* **size**   : `<size="10"></size>` or `<s="10"></s>`;
* **colors** : _don't forget '0x' or '#' !_
 * **solid** : <br/>
 `<color="0xFF0000"></color>` or <br/>
 `<c="0xFF0000"></c>`;
 * **gradient up / down** : <br/>
 `<color="0xFF0000,0xFFFFFF"></color>` or <br/>
 `<c="0xFF00000xFFFFFF"></c>;`
 * **gradient up-left/up-right/down-left/down-right** : <br/>
 `<color="0xFF0000,0xFFFFFF,0x000000,0x0000FF"></color>` or <br/>
 `<c="0xFF0000,0xFFFFFF,0x000000,0x0000FF"></c>`


<i>HTMLTextField uses HTMLBitmapFonts instead of the tradtional BitmapFont.</i>

___

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
	
* <em>Only **one font name** can be used in the HTMLTextField, it can only change size, bold, italic, and color</em>
* <em>All font styles must be on the **same atlas** as the textField is drawed on a QuadBatch</em>
* <em>No scales are applied on the texts, when adapting the font size it just search within the available sizes</em>