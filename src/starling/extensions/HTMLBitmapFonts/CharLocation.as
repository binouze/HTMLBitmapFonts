package starling.extensions.HTMLBitmapFonts
{
	import starling.text.BitmapChar;
	
	public class CharLocation
	{
		public var char		:BitmapChar;
		public var scale	:Number;
		public var x		:Number;
		public var y		:Number;
		public var doTint	:Boolean = true;
		public var style	:int;
		public var size		:int;
		public var isEmote	:Boolean;
		
		public function CharLocation( char:BitmapChar )
		{
			this.char = char;
		}
		
		/*public function get x():Number	{ return _x; };
		public function set x(value:Number):void
		{
			_x = Math.round(value);
		}
		
		public function get y():Number	{ return _y; };
		public function set y(value:Number):void
		{
			_y = Math.round(value);
		}*/
		
		public function reset():void
		{
			char = null;
			scale = 1;
			x = 0;
			y = 0;
			doTint = true;
			isEmote = false;
		}
	}
}