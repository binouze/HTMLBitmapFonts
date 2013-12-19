HTMLBitmapFonts
===============

Starling extension for using bitmap fonts with simplified html for styling texts


HTMLTextField is a Starling TextField for using with simplified html notation (just for styling: no links, no images...).

accepted tags:
<ul>
	<li>&lt;b&gt;&lt;/b&gt; -> bold</li>
	<li>&lt;i&gt;&lt;/i&gt; -> italic</li>
	<li>&lt;size="10"&gt;&lt;/size&gt; or &lt;s="10"&gt;&lt;/s&gt; -> font size (10 in this exemple)</li>
	<li>&lt;color="0xFF0000"&gt;&lt;/color&gt; or &lt;c="0xFF0000"&gt;&lt;/c&gt; -> solid color (red in this exemple) <b>don't forget 0x or # !</b></li>
	<li>&lt;color="0xFF0000,0xFFFFFF"&gt;&lt;/color&gt; or &lt;c="0xFF00000xFFFFFF"&gt;&lt;/c&gt; -> up/down gradient (red / white in this exemple) <b>don't forget 0x or # !</b></li>
	<li>&lt;color="0xFF0000,0xFFFFFF,0x000000,0x0000FF"&gt;&lt;/color&gt; or &lt;c="0xFF0000,0xFFFFFF,0x000000,0x0000FF"&gt;&lt;/c&gt; -> custom gradient
(up left = red / up right = white / bottom left = black / bottom right = blue in this exemple) <b>don't forget 0x or # !</b></li>
</ul>

HTMLTextField uses HTMLBitmapFonts instead of the tradtional BitmapFont

to add a font for use with HTMLtextField you must add them to HTMLTextField with the static methods <code>HTMLTextField.registerBitmapFont</code>
this fonction accept as xml value the same XMLs as traditional BitmapFont.

They can be generated with tools like :
<ul>
	<li><a href="http://kvazars.com/littera/">Littera</a></li>
	<li><a href="http://www.angelcode.com/products/bmfont/">AngelCode - Bitmap Font Generator</a></li>
	<li><a href="http://glyphdesigner.71squared.com/">Glyph Designer</a></li>
</ul>

Personnaly i use AssetManager for loading fonts and i just modified it like this: <br/>
in loadQueue -> processXML :</br>

else if( rootNode == "font" )
{
	name 	= xml.info.&#64;face.toString();
	fileName 	= getName(xml.pages.page.&#64;file.toString());
	isBold 	= xml.info.&#64;bold == 1;
	isItalic 	= xml.info.&#64;italic == 1;
	
	log("Adding html bitmap font '" + name + "'" + " _bold: " + isBold + " _italic: " + isItalic );
	
	fontTexture = getTexture( fileName );
	HTMLTextField.registerBitmapFont( fontTexture, xml, xml.info.&#64;size, isBold, isItalic, name.toLowerCase() );
	removeTexture( fileName, false );
	
	mLoadedHTMLFonts.push( name.toLowerCase() );
}
