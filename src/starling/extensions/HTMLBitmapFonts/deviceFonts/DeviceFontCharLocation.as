package starling.extensions.HTMLBitmapFonts.deviceFonts
{
	import flash.display.DisplayObject;

	public class DeviceFontCharLocation
	{
		public var charIDs		:Vector.<int>;
		public var charID		:int;
		public var link         :DisplayObject;
		public var xAdvance	    :Number;
		public var xOffset		:Number;
		public var yOffset		:Number;
		public var width		:Number;
		public var height		:Number;
		public var lineHeight   :Number;
		public var size			:int;
		public var isBold		:Boolean = false;
		public var isItalic		:Boolean = false;
		public var name			:String;
		public var color        :*;
		public var underline    :Boolean = false;
		public var baseLine     :Number;
		public var isEmote      :Boolean;
		public var x            :Number;
		public var y            :Number;
		public var linkID       :int;
		
		public function DeviceFontCharLocation( link:DisplayObject )
		{
			this.link = link;
		}
		
		public function dreset( link:DisplayObject ):void
		{
			this.link 	= link;
			charIDs     = null;
			charID		= 0;
			x 			= 0;
			y 			= 0;
			lineHeight	= 0;
			baseLine	= 0;
			isEmote 	= false;
			xAdvance	= 0;
			xOffset		= 0;
			yOffset		= 0;
			width		= 0;
			height		= 0;
			size 		= 0;
			isBold		= false;
			isItalic	= true;
			color       = 0xFFFFFF;
			underline   = false;
			linkID      = -1;
		}
		
		public function dclone():DeviceFontCharLocation
		{
			var retour:DeviceFontCharLocation = new DeviceFontCharLocation(link);
			retour.charID		= charID;
			retour.x 			= x;
			retour.y 			= y;
			retour.lineHeight 	= lineHeight;
			retour.baseLine 	= baseLine;
			retour.isEmote 		= isEmote;
			retour.xAdvance		= xAdvance;
			retour.xOffset		= xOffset;
			retour.yOffset		= yOffset;
			retour.width		= width;
			retour.height		= height;
			retour.size 		= size;
			retour.isBold		= isBold;
			retour.isItalic		= isItalic;
			retour.name 		= name;
			retour.charIDs      = charIDs;
			retour.color        = color;
			retour.underline    = underline;
			retour.linkID       = linkID;

			return retour;
		}
		
		// pooling
		
		private static var sInstancePool:Vector.<DeviceFontCharLocation> = new <DeviceFontCharLocation>[];
		private static var sVectorPool:Array = [];
		
		private static var sInstanceLoan:Vector.<DeviceFontCharLocation> = new <DeviceFontCharLocation>[];
		private static var sVectorLoan:Array = [];
		
		public static function instanceFromPool( link:DisplayObject ):DeviceFontCharLocation
		{
			var instance:DeviceFontCharLocation = sInstancePool.length > 0 ? sInstancePool.pop() : new DeviceFontCharLocation(link);
			
			instance.dreset(link);
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
				
				if( instanceLen < 300 )
					sInstancePool[instanceLen++] = instance;
			}
			
			retour.length = 0;
			
			if( vectorLen < 300 )
				sVectorPool[vectorLen] = retour;
		}
	}
}