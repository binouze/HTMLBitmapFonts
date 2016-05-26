package com.lagoon.display.images
{
	import starling.display.BlendMode;
	import starling.display.Image;
	import starling.events.Event;
	import starling.textures.Texture;

	public class ImagePool
	{
		/** a object pool for the Image **/
		protected static var _pool			:Vector.<Image>;
		/** the number of objects in the pool **/
		protected static var _nbItems		:int;
		/** le nombre max d'items dans la pool **/
		protected static var _maxItems		:int;
		/** un image vide a renvoyer en cas de texture nulle **/
		protected static var _emptyTexture	:Texture;
		
		public function ImagePool()
		{
			
		}
		
		/** a static function to initialize the Image pool **/
		public static function init( maxItems:int = 40 ):void
		{
			if( !_pool )	
			{
				_maxItems		= maxItems;
				_pool 			= new Vector.<Image>();
				_nbItems 		= 0;
				_emptyTexture 	= Texture.empty(1,1);
				for( var i:int = 0; i<_maxItems; ++i )
				{
					_pool[_nbItems++] = new Image( _emptyTexture );
				}
			}
		}
		
		/** 
		 * The function to call to release the object and return it to the pool<br/>
		 * Utiliser comme ca :
		 * <b><listing>
// cette vérification n'est pas obligatoire mais tres conseillée
if( _monImage )			
{
	// release vers la poule
	ImagePool.release(_monImage);	
	
	// passer la référence à null pour être sur de pas repasser dans ce if 
	// et pas remettre l'image dans la poule un fois de plus.
	_monImage = null;		
}
		 * </listing>
		 * 
		 * <ul>
		 * 	<li>ne pas disposer l'image avant de la mettre dans la poule</li>
		 * 	<li>pas besoin de faire <code>removeFromParent()</code> c'est déja fait dans le release</li>
		 *  <li>pas besoin de faire <code>juggler.remove(_monImage)</code>, c'est déja fait dans le release</li>
		 *  <li>pas besoin de faire <code>_monImage.removeEventListeners()</code>, c'est déja fait dans le release</li>
		 *  <li>pas besoin de reset les propriété visible, scale, alpha, color, x, y, pivot, rotation, blendMode,
		 * touchable, c'est déja fait dans le release</li>
		 * </ul>
		 * </b>
		 **/
		[Inline]
		public static function release( image:Image ):void
		{
			// sécurité si on lui fait bouffer un null ca casse pas tout
			if( !image )	return;
			
			if( _pool.indexOf( image ) != -1 )
			{
				trace( '[ImagePool] -> ya deja cette image dans la poule' );
				return;
			}
			
			// make sure it don't have listeners
			image.removeEventListeners();
			// make sure it is not on display list anymore
			image.removeFromParent();
			// make sure there is no juggler associated
			if( image.hasEventListener(Event.REMOVE_FROM_JUGGLER) )		image.dispatchEventWith( Event.REMOVE_FROM_JUGGLER );
			
			// on a encore de la place dans la poule, on reset les propriété de l'image et on met dans la poule
			if( _nbItems < _maxItems )	
			{
				// reset base props
				image.visible = true;
				image.scaleX = image.scaleY = image.alpha = 1;
				image.pivotX = image.pivotY = image.x = image.y = image.rotation = image.skewX = image.skewY = 0;
				image.color = 0xFFFFFF;
				image.scale9Grid = null;
				image.blendMode = BlendMode.NORMAL;
				image.touchable = true;
				if( image.filter )	image.filter.dispose();
				image.filter = null;
				image.name = '';
				
				// on met dans la poule
				if( _pool )	_pool[_nbItems++] = image;
			}
			// sinon on dispose l'image
			else
			{
				image.dispose();
				return;
			}
		}
		
		/** récuperer une image dans la poule, si la texture est nulle, une image vide de 1x1 sera mise a la place **/
		[Inline]
		public static function get(texture:Texture):Image
		{
			if( !texture ) 	texture = _emptyTexture;
			
			var a	:Image;
			if( _nbItems > 0 )
			{
				a 			= _pool.pop();
				a.texture 	= texture;
				a.readjustSize();
				--_nbItems;
			}
			else
			{
				a = new Image( texture );
			}
			return a;
		}
		
		/** a static function to destroy Images and the pool **/
		public static function dispose():void
		{
			if( !_pool )	return;
			for( var i:int = 0; i<_nbItems; ++i )	_pool[i].removeFromParent(true);
			_pool.length = 0;
			_pool = null;
			_nbItems = 0;
		}
	}
}