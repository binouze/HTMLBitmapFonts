package starling.extensions.HTMLBitmapFonts.deviceFonts
{
	import starling.extensions.HTMLBitmapFonts.CharLocation;
	import starling.textures.Texture;

	public class DeviceFontCharLocation extends CharLocation
	{
		public var charID		:int;
		public var tex			:Texture;
		/*public var x			:Number;
		public var y			:Number;
		public var doTint		:Boolean = true;
		public var lineHeight	:Number;
		public var baseLine		:Number;
		public var isEmote		:Boolean;*/
		public var _xAdvance		:Number;
		//public var _yAdvance		:Number;
		public var _xOffset		:Number;
		public var _yOffset		:Number;
		public var _width		:Number;
		public var _height		:Number;
		public var inUse		:Boolean = false;
		public var size			:int;
		public var isBold		:Boolean = false;
		public var isItalic		:Boolean = false;
		public var name			:String;
		
		override public function get xAdvance():Number
		{
			return _xAdvance;
		}
		override public function get xOffset():Number
		{
			return _xOffset;
		}
		override public function get yOffset():Number
		{
			return _yOffset;
		}
		override public function get width():Number
		{
			return _width;
		}
		override public function get height():Number
		{
			return _height;
		}
		override public function get lineHeight():Number
		{
			return _lineHeight;
		}
		
		
		public function set xAdvance(value:Number):void
		{
			_xAdvance = value;
		}
		/*public function set yAdvance(value:Number):void
		{
			_yAdvance = value;
		}*/
		public function set xOffset(value:Number):void
		{
			_xOffset = value;
		}
		public function set yOffset(value:Number):void
		{
			_yOffset = value;
		}
		public function set width(value:Number):void
		{
			_width = value;
		}
		public function set height(value:Number):void
		{
			_height = value;
		}
		public function set lineHeight(value:Number):void
		{
			_lineHeight = value;
		}
		
		public function DeviceFontCharLocation( char:Texture )
		{
			this.tex = char;
			super(null);
		}
		
		public function dreset( char:Texture ):void
		{
			this.tex 	= char;
			inUse		= false;
			charID		= 0;
			x 			= 0;
			y 			= 0;
			doTint 		= true;
			lineHeight	= 0;
			baseLine	= 0;
			isEmote 	= false;
			xAdvance	= 0;
			//yAdvance	= 0;
			xOffset		= 0;
			yOffset		= 0;
			width		= 0;
			height		= 0;
			size 		= 0;
			isBold		= false;
			isItalic	= true;
		}
		
		public function dclone():DeviceFontCharLocation
		{
			var retour:DeviceFontCharLocation = new DeviceFontCharLocation(tex);
			retour.inUse		= inUse;
			retour.charID		= charID;
			retour.x 			= x;
			retour.y 			= y;
			retour.doTint 		= doTint;
			retour.lineHeight 	= lineHeight;
			retour.baseLine 	= baseLine;
			retour.isEmote 		= isEmote;
			retour.xAdvance		= xAdvance;
			//retour.yAdvance		= yAdvance;
			retour.xOffset		= xOffset;
			retour.yOffset		= yOffset;
			retour.width		= width;
			retour.height		= height;
			retour.size 		= size;
			retour.isBold		= isBold;
			retour.isItalic		= isItalic;
			retour.name 		= name;
			return retour;
		}
		
		// pooling
		
		private static var sInstancePool:Vector.<DeviceFontCharLocation> = new <DeviceFontCharLocation>[];
		private static var sVectorPool:Array = [];
		
		private static var sInstanceLoan:Vector.<DeviceFontCharLocation> = new <DeviceFontCharLocation>[];
		private static var sVectorLoan:Array = [];
		
		public static function instanceFromPool( char:Texture ):DeviceFontCharLocation
		{
			var instance:DeviceFontCharLocation = sInstancePool.length > 0 ? sInstancePool.pop() : new DeviceFontCharLocation(char);
			
			instance.dreset(char);
			sInstanceLoan[sInstanceLoan.length] = instance;
			
			return instance;
		}
		
		public static function vectorFromPool():Vector.<DeviceFontCharLocation>
		{
			var vector:Vector.<DeviceFontCharLocation> = sVectorPool.length > 0 ? sVectorPool.pop() : new <DeviceFontCharLocation>[];
			
			vector.length = 0;
			sVectorLoan[sVectorLoan.length] = vector;
			
			return vector;
		}
		
		public static function rechargePool():void
		{
			var instance	:DeviceFontCharLocation;
			var vector		:Vector.<DeviceFontCharLocation>;
			var instanceLen	:int = sInstancePool.length;
			var vectorLen	:int = sVectorPool.length;
			
			while( sInstanceLoan.length > 0 )
			{
				instance = sInstanceLoan.pop();
				instance.char = null;
				
				if( instanceLen < 300 )
					sInstancePool[instanceLen++] = instance;
			}
			
			while( sVectorLoan.length > 0 )
			{
				vector = sVectorLoan.pop();
				vector.length = 0;
				
				if( vectorLen < 300 )
					sVectorPool[vectorLen++] = vector;
			}
		}
		
		public static function resetPool():void
		{
			sInstanceLoan.length 	= 0;
			sVectorLoan.length 		= 0;
		}
		
		public static function cloneVector( toClone:Vector.<DeviceFontCharLocation> ):Vector.<DeviceFontCharLocation>
		{
			var len		:int = toClone.length;
			var retour	:Vector.<DeviceFontCharLocation> = new Vector.<DeviceFontCharLocation>(len, true);
			for( var i:int = 0; i<len; ++i )
			{
				retour[i] = toClone[i].dclone();
			}
			return retour;
		}
		public static function returnVector( retour:Vector.<DeviceFontCharLocation> ):void
		{
			retour.fixed = false;
			var instance	:DeviceFontCharLocation;
			var instanceLen	:int = sInstancePool.length;
			var vectorLen	:int = sVectorPool.length;
			
			while( retour.length > 0 )
			{
				instance 		= retour.pop();
				instance.char 	= null;
				
				if( instanceLen < 300 )
					sInstancePool[instanceLen++] = instance;
			}
			
			retour.length = 0;
			
			if( vectorLen < 300 )
				sVectorPool[vectorLen++] = retour;
		}
	}
}