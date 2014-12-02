package starling.extensions.HTMLBitmapFonts
{
	import starling.text.BitmapChar;
	
	public class CharLocation
	{
		public var char			:BitmapChar;
		public var scale		:Number;
		public var x			:Number;
		public var y			:Number;
		public var doTint		:Boolean = true;
		public var style		:int;
		public var _lineHeight	:Number;
		public var baseLine		:Number;
		public var isEmote		:Boolean;
		
		public function CharLocation( char:BitmapChar )
		{
			this.char = char;
		}
		
		public function reset(char:BitmapChar):void
		{
			this.char 	= char;
			scale 		= 1;
			x 			= 0;
			y 			= 0;
			doTint 		= true;
			isEmote 	= false;
		}
		
		public function clone():CharLocation
		{
			var retour:CharLocation = new CharLocation(char);
			retour.scale = scale;
			retour.x = x;
			retour.y = y;
			retour.doTint = doTint;
			retour.style = style;
			retour._lineHeight = _lineHeight;
			retour.baseLine = baseLine;
			retour.isEmote = isEmote;
			return retour;
		}
		
		public function get xAdvance():Number
		{
			return char.xAdvance*scale;
		}
		public function get xOffset():Number
		{
			return char.xOffset*scale;
		}
		public function get yOffset():Number
		{
			return (baseLine - ((baseLine-char.yOffset)/char.height)*(scale*char.height)) - baseLine;
		}
		public function get width():Number
		{
			return char.width*scale;
		}
		public function get height():Number
		{
			return char.height*scale;
		}
		
		public function get lineHeight():Number
		{
			return _lineHeight;
		}
		
		// pooling
		
		private static var sInstancePool:Vector.<CharLocation> = new <CharLocation>[];
		private static var sVectorPool:Array = [];
		
		private static var sInstanceLoan:Vector.<CharLocation> = new <CharLocation>[];
		private static var sVectorLoan:Array = [];
		
		public static function instanceFromPool(char:BitmapChar):CharLocation
		{
			var instance:CharLocation = sInstancePool.length > 0 ?
				sInstancePool.pop() : new CharLocation(char);
			
			instance.reset(char);
			sInstanceLoan[sInstanceLoan.length] = instance;
			
			return instance;
		}
		
		public static function vectorFromPool():Vector.<CharLocation>
		{
			var vector:Vector.<CharLocation> = sVectorPool.length > 0 ?
				sVectorPool.pop() : new <CharLocation>[];
			
			vector.length = 0;
			sVectorLoan[sVectorLoan.length] = vector;
			
			return vector;
		}
		
		public static function rechargePool():void
		{
			var instance:CharLocation;
			var vector:Vector.<CharLocation>;
			
			while (sInstanceLoan.length > 0)
			{
				instance = sInstanceLoan.pop();
				instance.char = null;
				sInstancePool[sInstancePool.length] = instance;
			}
			
			while (sVectorLoan.length > 0)
			{
				vector = sVectorLoan.pop();
				vector.length = 0;
				sVectorPool[sVectorPool.length] = vector;
			}
		}
		
		public static function resetPool():void
		{
			sInstanceLoan.length 	= 0;
			sVectorLoan.length 		= 0;
		}
		
		public static function cloneVector( toClone:Vector.<CharLocation> ):Vector.<CharLocation>
		{
			var len		:int = toClone.length;
			var retour	:Vector.<CharLocation> = new Vector.<CharLocation>(len, true);
			for( var i:int = 0; i<len; ++i )
			{
				retour[i] = toClone[i].clone();
			}
			return retour;
		}
		public static function returnVector( retour:Vector.<CharLocation> ):void
		{
			retour.fixed = false;
			var instance:CharLocation;
			while( retour.length > 0 )
			{
				instance 		= retour.pop();
				instance.char 	= null;
				sInstancePool[sInstancePool.length] = instance;
			}
			retour.length = 0;
			sVectorPool[sVectorPool.length] = retour;
		}
	}
}