package starling.extensions.HTMLBitmapFonts.deviceFonts
{
	import starling.display.Image;
	import starling.textures.Texture;
	
	public class DeviceFontImage extends Image
	{
		public function DeviceFontImage(texture:Texture)
		{
			super(texture);
		}
		
		override public function dispose():void
		{
			if( texture )	
			{
				if( texture.root )	texture.root.dispose();
				texture.dispose();
			}
			super.dispose();
		}
	}
}