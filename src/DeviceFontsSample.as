package
{
	import flash.text.Font;
	import flash.utils.setTimeout;

	import starling.animation.Juggler;

	import starling.display.Sprite;
	import starling.extensions.HTMLBitmapFonts.HTMLTextField;

	public class DeviceFontsSample extends Sprite
	{
		public function DeviceFontsSample()
		{
		}

		public function init():void
		{
			// devices fonts
			var availFonts:Array = Font.enumerateFonts(true);
			var len:int = availFonts.length;
			for( var i:int = 0; i<len; ++i )
			{
				//trace( Font(availFonts[i]).fontName );
				addTF(i,Font(availFonts[i]).fontName);
			}

			setTimeout( clear, 5000, textShadow );
		}

		public function addTF( id:int, fontName:String ):void
		{
			var txt:HTMLTextField   = new HTMLTextField(200,20,fontName,fontName);
			txt.x                   = 50+ (200 * int(id/40));
			txt.y                   = 20 * (id%40);
			txt.color               = 0x000000;
			txt.contourColor        = 0xFFFFFF;
			txt.contourSize         = 3;
			txt.contourStrength     = 3;
			txt.fontSize            = 15;
			txt.shadowX = txt.shadowY = 2;
			txt.bold                = true;
			txt.autoScale           = true;
			txt.autoCR              = false;

			addChild(txt);
		}

		public function clear(after:Function):void
		{
			removeChildren(0,-1,true);
			if( after ) after();
		}

		/** HTML text Shadow **/
		public function textShadow():void
		{
			var txt:HTMLTextField   = new HTMLTextField(300,50);
			txt.x = txt.y = 50;
			txt.htmlText = '<s="32"><o="2">text with shadow';
			addChild(txt);

			setTimeout( clear, 3000, textGradient );
		}

		/** HTML text gradient **/
		public function textGradient():void
		{
			var txt:HTMLTextField = new HTMLTextField(300,50);
			txt.x = txt.y = 50;
			txt.htmlText = '<s="32">text with <c="0xFF0000,0xFFFF00"><b>gradient';
			addChild(txt);
			setTimeout( clear, 3000, textStyles );
		}

		/** HTML text styles **/
		public function textStyles():void
		{
			var txt:HTMLTextField = new HTMLTextField(300,50);
			txt.x = txt.y = 50;
			txt.htmlText = '<s="32"><b>text <i>with</b> different <u><s="45"><c="0xFF0000">styles';
			addChild(txt);

			setTimeout( clear, 3000, textStroke );
		}

		/** HTML text stroke **/
		public function textStroke():void
		{
			var txt:HTMLTextField = new HTMLTextField(300,50);
			txt.x = txt.y = 50;
			txt.htmlText = '<s="32"><a="5,0x0000FF,5">text with strokes';
			addChild(txt);
		}
	}
}
