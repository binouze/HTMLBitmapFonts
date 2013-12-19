package starling.extensions.HTMLBitmapFonts
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import starling.text.BitmapChar;
	import starling.textures.Texture;

	/** 
	 * BitmapFontStyle sert à rassembler toutes les tailles de font pour un meme style.<br/>
	 * Cette classe est utilisée par HTMLBitmapFonts et n'est pas faite pour être utilisée toute seule.
	 * 
	 * @see starling.extensions.HTMLBitmapFonts.HTMLBitmapFonts
	 **/
	public class BitmapFontStyle
	{
		/** la taille a utiliser par défaut en cas de taille invalide durant le parsing **/
		public static const DEFAULT_SIZE	:int = 12;
		
		/** le style régular (=0) **/
		public static const REGULAR		:int = 0;
		/** le style bold (=1) **/
		public static const BOLD		:int = 1;
		/** le style italic (=2) **/
		public static const ITALIC		:int = 2;
		/** le style bold italic (=3) **/
		public static const BOLD_ITALIC	:int = 3;
		
		/** le nombre de styles **/
		public static const NUM_STYLES	:int = 4;
		
		/** le style du BitmapFont **/
		private var mStyle				:int;
		/** les textures de la police par taille **/
		private var mTextures			:Vector.<Texture>;
		/** les caracteres de la police par taille **/
		private var mChars				:Vector.<Dictionary>;
		/** le nom de la police **/
		private var mName				:String;
		/** les tailles de base pour la font **/
		private var mSizes				:Vector.<Number>;
		/** la hauteur de ligne par taille de font **/
		private var mLineHeights		:Vector.<Number>;
		
		/** 
		 * Créer un BitmapFontStyle avec plusieurs tailles de fonts.
		 * @param name le nom à enregistrer pour la font. si aucun nom n'est donné ('') alors le nom du premier xml sera gardé.
		 * @param textures le tableau des textures par taille de font.
		 * @param fontXml le tableau des xml de positionnement des caracteres par taille de font.
		 * @param sizes le tableau des tailles native de polices. Si null les infos des xml seront gardées.
		 **/
		public function BitmapFontStyle( style:int, textures:Vector.<Texture>, fontsXml:Vector.<XML>, sizes:Vector.<Number> = null )
		{
			mStyle = style;
			
			// créer / récupérer les tableaux
			mTextures 			= textures;
			
			mChars 				= new Vector.<Dictionary>( textures.length, true );
			mLineHeights		= new Vector.<Number>( textures.length, true );
			mSizes				= sizes ? sizes : new Vector.<Number>( textures.length, true );
			
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
			
			// vider le tableau de hauteurs de lignes
			mLineHeights.fixed 	= false;
			mLineHeights.length = 0;
			mLineHeights 		= null;
		}
		
		/** ajouter plusieurs tailles de font **/
		public function addMultipleSizes( textures:Vector.<Texture>, fontsXml:Vector.<XML>, sizes:Vector.<Number> ):void
		{
			// défixer les tailles des tableaux qui vont etre modifiés
			mTextures.fixed 	= false;
			mSizes.fixed 		= false;
			mLineHeights.fixed 	= false;
			mChars.fixed 		= false;
			
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
		}
		
		/** ajouter une taille de font **/
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
			parseFontXml( xml, mTextures.length-1 );
		}
		
		/** parcourir les tableaux et définir les variables de classes utiles **/
		private function _processXMLs( xmls:Vector.<XML> ):void
		{
			for( var i:int = 0; i<xmls.length; ++i )	parseFontXml(xmls[i], i);
		}
		
		/** parser une taille de font **/
		private function parseFontXml( fontXml:XML, i:int ):void
		{
			var scale	:Number 	= mTextures[i].scale;
			var frame	:Rectangle 	= mTextures[i].frame;
			
			// si on a pas encore de nom pour la font on récupere celui du xml
			if( mName == '' )	mName = fontXml.info.attribute("face");
			
			// récupérer la taille de la font si on ne l'a pas fournie
			if( !mSizes[i] )	mSizes[i] = parseFloat( fontXml.info.attribute("size") ) / scale;
			// récupérer la hauteur de ligne de la font
			mLineHeights[i] = parseFloat( fontXml.common.attribute("lineHeight") ) / scale;
			
			// on gere les tailles invalides
			if( mSizes[i] <= 0 )	mSizes[i] = DEFAULT_SIZE;
			
			// créer le caractère en fonctin du xml
			for each( var charElement:XML in fontXml.chars.char )
			{
				var id			:int 		= parseInt( charElement.attribute("id") );
				var xOffset		:Number 	= parseFloat( charElement.attribute("xoffset") ) / scale;
				var yOffset		:Number 	= parseFloat( charElement.attribute("yoffset") ) / scale;
				var xAdvance	:Number 	= parseFloat( charElement.attribute("xadvance") ) / scale;
				
				var region		:Rectangle 	= new Rectangle();
				region.x 					= parseFloat( charElement.attribute("x") ) / scale + frame.x;
				region.y 					= parseFloat( charElement.attribute("y") ) / scale + frame.y;
				region.width  				= parseFloat( charElement.attribute("width") ) / scale;
				region.height 				= parseFloat( charElement.attribute("height") ) / scale;
				
				var texture		:Texture 	= Texture.fromTexture( mTextures[i], region );
				var bitmapChar	:BitmapChar = new BitmapChar( id, texture, xOffset, yOffset, xAdvance ); 
				
				addChar( i, id, bitmapChar );
			}
			
			// ajouter le kerning
			for each( var kerningElement:XML in fontXml.kernings.kerning )
			{
				var first	:int = parseInt( kerningElement.attribute("first") );
				var second	:int = parseInt( kerningElement.attribute("second") );
				var amount	:Number = parseFloat( kerningElement.attribute("amount") ) / scale;
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
		
		/** réduire la taille de tous les éléments du tableau **/
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
		
		/** retourne la taille disponible en dessous de la taille value **/
		public function getSmallerSize( value:Number ):Number
		{
			var smaller:Number = -1;
			
			for( var i:int = 0; i<mSizes.length; ++i )
			{
				if( mSizes[i] < value && mSizes[i] > smaller )	smaller = mSizes[i];
			}
			return smaller > 0 ? smaller : value;
		}
		
		/** retourne la taille disponible en dessous de la taille value **/
		public function getBiggerOrEqualSize( value:Number ):Number
		{
			var bigger:Number = int.MAX_VALUE;
			
			for( var i:int = 0; i<mSizes.length; ++i )
			{
				if( mSizes[i] >= value && mSizes[i] < bigger )	bigger = mSizes[i];
			}
			
			return bigger;
		}
		
		/** retourne la taille disponible en dessous de la taille value **/
		public function getBiggerOrEqualSizeIndex( value:Number ):Number
		{
			var bigger:Number = getBiggerOrEqualSize(value);
			
			for( var i:int = 0; i<mSizes.length; ++i )
			{
				if( mSizes[i] == bigger )	return i;
			}
			
			return -1;
		}
		
		/** retourner la plus grande taille à générer **/
		public function getBiggestSize( value:Array ):Number
		{
			var biggestSize	:Number = 0;
			for( var i:int = 0; i<value.length; ++i )	if( biggestSize < value[i] )	biggestSize = value[i];
			return biggestSize;
		}
		
		/** retourner l'index de la plus grande taille à générer **/
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
		
		/** retourne la hauteur de ligne pour la taille de police passée en argument **/
		public function getLineHeightForSize(size:Number):Number
		{
			return mLineHeights[getBiggerOrEqualSizeIndex(size)];
		}
		
		/** retourne une taille de police avec une hauteur de ligne au plus proche de celle souhaitée **/
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
			
			return mSizes[idActu];
		}
	}
}