package starling.extensions.HTMLBitmapFonts
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import starling.text.BitmapChar;
	import starling.textures.Texture;
	
	/** 
	 * BitmapFontStyle is used to keep all sizes for one font style.<br/>
	 * This class is used by HTMLBitmapFonts and shouldn't be used as is.
	 * 
	 * @see starling.extensions.HTMLBitmapFonts.HTMLBitmapFonts
	 **/
	public class BitmapFontStyle
	{
		/** style regular (=0) **/
		public static const REGULAR		:int = 0;
		/** style bold (=1) **/
		public static const BOLD		:int = 1;
		/** style italic (=2) **/
		public static const ITALIC		:int = 2;
		/** style bold italic (=3) **/
		public static const BOLD_ITALIC	:int = 3;
		
		/** the number of styles availables **/
		public static const NUM_STYLES	:int = 4;
		
		/** the style of this BitmapFontStyle **/
		private var mStyle				:int;
		/** the textures of the font by sizes **/
		private var mTextures			:Vector.<Texture>;
		/** the characters of the font by sizes **/
		private var mChars				:Vector.<Dictionary>;
		/** the name of the font **/
		private var mName				:String;
		/** the sizes available for the font **/
		private var mSizes				:Vector.<Number>;
		/** the baselines for the font **/
		private var mBases				:Vector.<Number>;
		/** the lines heights by sizes **/
		private var mLineHeights		:Vector.<Number>;
		
		/** 
		 * Create a BitmapFontStyle for a font.
		 * @param name the name of the font for registering. if '' is passed, it will be replaced by the first name found during the xml parsing.
		 * @param textures the array of textures by sizes.
		 * @param fontXml the xml with font data by sizes.
		 * @param sizes the array of the sizes, if null the data from the xml will be used.
		 **/
		public function BitmapFontStyle( style:int, textures:Vector.<Texture>, fontsXml:Vector.<XML>, sizes:Vector.<Number> = null )
		{
			mStyle = style;
			
			// créer / récupérer les tableaux
			mTextures 			= textures;
			
			mChars 				= new Vector.<Dictionary>( textures.length, true );
			mLineHeights		= new Vector.<Number>( textures.length, true );
			mSizes				= sizes ? sizes : new Vector.<Number>( textures.length, true );
			mBases				= new Vector.<Number>( textures.length, true );
			
			// parser les XMLs
			_processXMLs( fontsXml );
			
			// fixes les tailles de tableaux
			mTextures.fixed 	= true;
			mSizes.fixed 		= true;
			mLineHeights.fixed 	= true;
			mChars.fixed 		= true;
		}
		
		/** dispose all **/
		public function dispose():void
		{
			// dispose textures et chars
			var len:int = mTextures.length;
			for( var i:int = 0; i<len; ++i )
			{
				// dispose texture
				mTextures[i].dispose();
				// delete char
				for( var key:Object in mChars[i] )		
				{
					// dispose char texture
					BitmapChar( mChars[i][key] ).texture.dispose();
					delete mChars[i][key];
				}
			}
			
			// vider le tableau de textures
			mTextures.fixed 	= false;
			mTextures.length 	= 0;
			mTextures 			= null;
			
			// vider le tableau de caracteres
			mChars.fixed 		= false;
			mChars.length 		= 0;
			mChars 				= null;
			
			// vider le tableau de tailles
			mSizes.fixed 		= false;
			mSizes.length 		= 0;
			mSizes 				= null;
			
			// vider le tableau de tailles
			mBases.fixed 		= false;
			mBases.length 		= 0;
			mBases 				= null;
			
			// vider le tableau de hauteurs de lignes
			mLineHeights.fixed 	= false;
			mLineHeights.length = 0;
			mLineHeights 		= null;
		}
		
		/** add multiple sizes of font **/
		public function addMultipleSizes( textures:Vector.<Texture>, fontsXml:Vector.<XML>, sizes:Vector.<Number> ):void
		{
			// défixer les tailles des tableaux qui vont etre modifiés
			mTextures.fixed 	= false;
			mSizes.fixed 		= false;
			mLineHeights.fixed 	= false;
			mChars.fixed 		= false;
			mBases.fixed 		= false;
			
			var len:int = textures.length;
			for( var i:int = 0; i<len; ++i )
			{
				// ajouter la texture
				mTextures.push( textures[i] );
				// ajouter la taille
				mSizes.push( sizes[i] );
				// creer une nouvelle entrée pour la hauteur de ligne qui sera remplie par parseFontXml
				mLineHeights.push( 0 );
				// creer une nouvelle entrée pour les caracteres qui sera remplie par parseFontXml
				mChars.push( new Dictionary() );
				// parser le xml
				parseFontXml( fontsXml[i], mTextures.length-1 );
			}
			
			// refixer la taille des tableaux
			mTextures.fixed 	= true;
			mSizes.fixed 		= true;
			mLineHeights.fixed 	= true;
			mChars.fixed 		= true;
			mBases.fixed		= true;
		}
		
		/** add one size of font **/
		public function add( texture:Texture, xml:XML, size:Number ):void
		{
			// ajouter la texture
			mTextures.fixed = false;
			mTextures.push( texture );
			mTextures.fixed = true;
			
			// ajouter la taille
			mSizes.fixed = false;
			mSizes.push( size );
			mSizes.fixed = true;
			
			// creer une nouvelle entrée pour la hauteur de ligne qui sera remplie par parseFontXml
			mLineHeights.fixed = false;
			mLineHeights.push( 0 );
			mLineHeights.fixed = true;
			
			// creer une nouvelle entrée pour les caracteres qui sera remplie par parseFontXml
			mChars.fixed = false;
			mChars.push( new Dictionary() );
			mChars.fixed = true;
			
			// parser le xml
			mBases.fixed = false;
			parseFontXml( xml, mTextures.length-1 );
			mBases.fixed = true;
		}
		
		/** parse multiple xmls **/
		private function _processXMLs( xmls:Vector.<XML> ):void
		{
			for( var i:int = 0; i<xmls.length; ++i )	parseFontXml(xmls[i], i);
		}
		
		/** parse a xml font **/
		private function parseFontXml( fontXml:XML, i:int ):void
		{
			var scale	:Number 	= mTextures[i].scale;
			var frame	:Rectangle 	= mTextures[i].frame;
			var frameX	:Number 	= frame ? frame.x : 0;
			var frameY	:Number 	= frame ? frame.y : 0;
			/*
			// si on a pas encore de nom pour la font on récupere celui du xml
			if( mName == '' )	mName = String('_'+fontXml.info.attribute("face")).substr(1);
			// récupérer la taille de la font si on ne l'a pas fournie
			if( !mSizes[i] )	mSizes[i] = parseFloat( fontXml.info.attribute("size") ) / scale;
			// récupérer la hauteur de ligne de la font
			mLineHeights[i] = parseFloat( fontXml.common.attribute("lineHeight") ) / scale;
			*/
			// si on a pas encore de nom pour la font on récupere celui du xml
			if( mName == '' )	mName = String('_'+fontXml.info.@face).substr(1);
			// récupérer la taille de la font si on ne l'a pas fournie
			if( !mSizes[i] )	mSizes[i] = parseFloat( fontXml.info.@size ) / scale;
			// récupérer la hauteur de ligne de la font
			mLineHeights[i] = parseFloat( fontXml.common.@lineHeight ) / scale;
			// récuperer le baseline de la font
			mBases[i] 		= parseFloat(fontXml.common.@base) / scale;
			
			// on gere les tailles invalides
			if( mSizes[i] <= 0 )
			{
				//Log.logAll( this, true, "Warning: invalid font size in '" + mName + "' font." );
				mSizes[i] = 16;
			}
			
			var maxHeight:Number = 0;
			
			// créer les caractères en fonction du xml
			var chars:XMLList = fontXml.chars.char
			for each( var charElement:XML in chars )
			{
				/*var id			:int 		= parseInt( charElement.attribute("id") );
				var xOffset		:Number 	= parseFloat( charElement.attribute("xoffset") ) / scale;
				var yOffset		:Number 	= parseFloat( charElement.attribute("yoffset") ) / scale;
				var xAdvance	:Number 	= parseFloat( charElement.attribute("xadvance") ) / scale;
				
				var region		:Rectangle 	= new Rectangle();
				region.x 					= parseFloat( charElement.attribute("x") ) / scale + frameX;
				region.y 					= parseFloat( charElement.attribute("y") ) / scale + frameY;
				region.width  				= parseFloat( charElement.attribute("width") ) / scale;
				region.height 				= parseFloat( charElement.attribute("height") ) / scale;*/
				
				var id			:int 		= parseInt( charElement.@id );
				var xOffset		:Number 	= parseFloat( charElement.@xoffset ) / scale;
				var yOffset		:Number 	= parseFloat( charElement.@yoffset ) / scale;
				var xAdvance	:Number 	= parseFloat( charElement.@xadvance ) / scale;
				
				var region		:Rectangle 	= new Rectangle();
				region.x 					= parseFloat( charElement.@x ) / scale + frameX;
				region.y 					= parseFloat( charElement.@y ) / scale + frameY;
				region.width  				= parseFloat( charElement.@width ) / scale;
				region.height 				= parseFloat( charElement.@height ) / scale;
				
				if( region.width > 0 && region.height > 0 )
				{
					if( region.x > 0 )	
					{
						region.x -= 1;
						region.width += 2;
						xOffset-=1;
					}
					else
					{
						region.width += 1;
					}
				
					if( region.y > 0 )	
					{
						region.y -= 1;
						region.height += 2;
						yOffset-=1;
					}
					else
					{
						region.height += 1;
					}
				}
				
				var texture		:Texture 	= Texture.fromTexture( mTextures[i], region );
				var bitmapChar	:BitmapChar = new BitmapChar( id, texture, xOffset, yOffset, xAdvance ); 
				
				addChar( i, id, bitmapChar );
				
				if( yOffset+region.height > maxHeight )		maxHeight = yOffset+region.height;
			}
			
			if( maxHeight > mLineHeights[i] ) 				mLineHeights[i] = maxHeight;
			
			// ajouter le kerning
			for each( var kerningElement:XML in fontXml.kernings.kerning )
			{
				/*var first	:int = parseInt( kerningElement.attribute("first") );
				var second	:int = parseInt( kerningElement.attribute("second") );
				var amount	:Number = parseFloat( kerningElement.attribute("amount") ) / scale;*/
				var first	:int = parseInt( kerningElement.@first );
				var second	:int = parseInt( kerningElement.@second );
				var amount	:Number = parseFloat( kerningElement.@amount ) / scale;
				if( second in mChars ) getChar(second, i).addKerning(first, amount);
			}
		}
		
		/** Returns a single bitmap char with a certain character ID. */
		public function getCharForSize(charID:int, size:Number):BitmapChar
		{
			return mChars[getBiggerOrEqualSizeIndex(size)][charID];
		}
		
		/** Returns a single bitmap char with a certain character ID. */
		public function getChar(charID:int, sizeIndex:int):BitmapChar
		{
			return mChars[sizeIndex][charID];   
		}
		
		/** Adds a bitmap char with a certain character ID. */
		public function addChar( sizeIndex:int, charID:int, bitmapChar:BitmapChar ):void
		{
			if( !mChars[sizeIndex] )	mChars[sizeIndex] = new Dictionary();
			mChars[sizeIndex][charID] = bitmapChar;
		}
		
		//-- utils --//
		
		/** 
		 * reduce the size of all sizes in the array, the passed array will be updated with the nexts smallers sizes for each elements 
		 * @ return true if the sizes has been reduced. Or false if no smaller size could be found. 
		 **/
		public function reduceSizes( value:Array ):Boolean
		{
			var orig:Number;
			var reduced:Boolean = false;
			for( var i:int = 0; i<value.length; ++i )
			{
				orig = value[i];
				value[i] = getSmallerSize( value[i] );
				
				if( orig > value[i] )	reduced = true;
			}
			
			return reduced;
		}
		
		/** return the next smaller value for the value **/
		public function getSmallerSize( value:Number ):Number
		{
			var smaller:Number = -1;
			
			for( var i:int = 0; i<mSizes.length; ++i )
			{
				if( mSizes[i] < value && mSizes[i] > smaller )	smaller = mSizes[i];
			}
			return smaller > 0 ? smaller : value;
		}
		
		/** return the available size bigger or equal to the desired value **/
		[Inline]
		public final function getBiggerOrEqualSize( value:Number ):Number
		{
			var bigger:Number = int.MAX_VALUE;
			var biggestDispo:int = 0;
			var len:int = mSizes.length;
			
			for( var i:int = 0; i<len; ++i )
			{
				if( mSizes[i] > biggestDispo )					biggestDispo = mSizes[i];
				if( mSizes[i] >= value && mSizes[i] < bigger )	bigger = mSizes[i];
			}
			
			if( bigger > biggestDispo )		bigger = biggestDispo; 
			return bigger;
		}
		
		/** return the index of the available size bigger or equal to the desired value **/
		[Inline]
		public final function getBiggerOrEqualSizeIndex( value:Number ):Number
		{
			var bigger:Number = getBiggerOrEqualSize(value);
			return mSizes.indexOf(bigger);
		}
		
		/** return the biggest size in the array **/
		public function getBiggestSize( value:Array ):Number
		{
			var biggestSize	:Number = 0;
			for( var i:int = 0; i<value.length; ++i )	if( biggestSize < value[i] )	biggestSize = value[i];
			return biggestSize;
		}
		
		/** return the index of the biggest available size in the array **/
		public function getBiggestSizeIndex( value:Array ):int
		{
			var biggestSize	:Number = getBiggestSize(value);
			var bigSize		:Number = getBiggerOrEqualSize(biggestSize);
			
			for( var i:int = 0; i<mSizes.length; ++i )	
			{
				if( bigSize == mSizes[i] )	return i;
			}
			
			return 0;
		}
		
		/** return the line height for the size **/
		public function getLineHeightForSize(size:Number):Number
		{
			var i:int = getBiggerOrEqualSizeIndex(size);
			return mLineHeights[i];
		}
		
		/** return the line height for the size index **/
		public function getLineHeightForSizeIndex(sizeIndex:int):Number
		{
			return mLineHeights[sizeIndex];
		}
		
		/** return the closer available font size for the line height **/
		public function getSizeForLineHeight( lineHeight:Number ):Number
		{
			var idActu		:int = 0;
			var delta		:Number = int.MAX_VALUE;
			var deltaActu	:Number;
			
			for( var i:int = 0; i<mLineHeights.length; ++i )	
			{
				deltaActu = lineHeight - mLineHeights[i];
				if( deltaActu >= 0 && deltaActu < delta )	
				{
					delta 	= deltaActu;
					idActu 	= i;
				}
			}
			
			if( mLineHeights[idActu]<lineHeight && mLineHeights.length > idActu+2 )	++idActu;
			
			return mSizes[idActu];
		}
		
		public function getSizeAtIndex(index:int):Number
		{
			return mSizes[index];
		}
		
		/** returns available sizes **/
		public function get availableSizes():Vector.<Number>
		{
			return mSizes;
		}
		
		public function getBaseLine(index:int):Number
		{
			return mBases[index];
		}
	}
}