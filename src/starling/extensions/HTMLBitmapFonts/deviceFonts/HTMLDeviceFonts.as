package starling.extensions.HTMLBitmapFonts.deviceFonts
{
	import com.lagoon.display.images.ImagePool;
	import com.lagoon.utils.Colors;

	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.GradientType;
	import flash.display.Graphics;
	import flash.display.MovieClip;
	import flash.display.PixelSnapping;
	import flash.display.Shape;
	import flash.display.StageQuality;
	import flash.filters.GlowFilter;
	import flash.geom.ColorTransform;
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.text.AntiAliasType;
	import flash.text.GridFitType;
	import flash.text.TextField;
	import flash.text.TextFieldAutoSize;
	import flash.text.TextFormat;
	import flash.text.TextLineMetrics;

	import starling.core.Starling;
	import starling.display.Image;
	import starling.extensions.HTMLBitmapFonts.BitmapFontStyle;
	import starling.extensions.HTMLBitmapFonts.HTMLTextField;
	import starling.textures.Texture;
	import starling.utils.Align;

	public class HTMLDeviceFonts
	{
		private static var _canEmbed                    :Boolean = true;
		public static var availableSymbols				:String = ' !"#%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`´abcdefghijklmnopqrstuvwxyz{|}~©®«»°±¿ÀÁÂÃÄÅÆÇÈÉÊËÌÍÎÏÐÑÒÓÔÕÖ×ØÙÚÛÜÝÞßàáâãäåæçèéêëìíîïðñòóôõö÷øùúûüýþÿ•€$£абвгдеёжзийклмнопрстуфхцчшщъыьэюяАБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯąćęłńóśżźĄĆĘŁŃÓŚŻŹ\\n\\r';
		public static function isAllAvailable(str:String):Boolean
		{
			var reg:RegExp = new RegExp( '[^'+availableSymbols+']' );
			var grr:Array = str.match( reg );
			return !grr || grr.length == 0;
		}

		/** true par défaut, groupe les caracteres par mot / changement d'état pour optimiser le temps de rendu **/
		public static var enableGroupping   :Boolean = true;
		/** le scale global appliqué aux textes */
		public static var globalScale       :Number = 1;
		/** le filtre utilisé pour les contours **/
		private static var contourFilter    :GlowFilter;

		// -- you can register emotes here --//

		protected static var _emotesTxt				:Vector.<String>;
		protected static var _emotesLinkages		:Vector.<DisplayObject>;

		/**
		 * Register emote shortcut and the texture associated
		 * @param shortcut the shortcut of the emote
		 * @param linkage le displayObject de l'emote
		 **/
		public static function registerEmote( shortcut:String, linkage:DisplayObject ):void
		{
			if( !linkage )	return;

			linkage.scaleX = linkage.scaleY = globalScale;

			if( !_emotesTxt )
			{
				_emotesTxt 		= new Vector.<String>();
				_emotesLinkages = new <DisplayObject>[];
			}

			var id:int = _emotesTxt.indexOf( shortcut );
			if( id == -1 )
			{
				_emotesTxt.push( shortcut );
				_emotesLinkages.push( linkage );
			}
			else
			{
				_emotesTxt[id] 		= shortcut;
				_emotesLinkages[id] = linkage;
			}
		}

		/** space char **/
		protected static const CHAR_SPACE			:int = 32;
		/** tab char **/
		protected static const CHAR_TAB				:int =  9;
		/** new line char **/
		protected static const CHAR_NEWLINE			:int = 10;
		/** cariage return char **/
		protected static const CHAR_CARRIAGE_RETURN	:int = 13;
		/** char slash (for urls) **/
		protected static const CHAR_SLASH			:int = 47;

		/** the base style for the font: the first added style **/
		protected var _baseStyle					:int = 0;
		/** the base size for the font: the fisrt size added **/
		protected var _baseSize						:int = 12;

		/** the vector for the line sizes **/
		protected static var linesSizes				:Vector.<Number>;
		/** the vector for the baselines **/
		protected static var baselines				:Vector.<Number>;
		/** the vector used for the lines **/
		protected static var dlines                 :Vector.< Vector.<DeviceFontCharLocation> >;

		/** font name **/
		protected var mName:String;
		/** font name **/
		public function set name(value:String):void         { mName = value; }

		/** le lineSpacing **/
		protected var _lineSpacing:int = 0;
		/** le lineSpacing **/
		public function set lineSpacing( value:int ):void   { _lineSpacing = value; }

		public function HTMLDeviceFonts()
		{
			// créer les tableaux statiques si ils n'existent pas encore
			if( !linesSizes )			linesSizes			= new <Number>[];
			if( !baselines )			baselines			= new <Number>[];
			if( !mSizeIndexes )			mSizeIndexes		= new <int>[];
			if( !mScales )				mScales				= new <Number>[];
			if( !mLineHeights )			mLineHeights		= new <Number>[];
			if( !dlines )		        dlines              = new <Vector.<DeviceFontCharLocation>>[];
			if( !_txt )			        _txt                = new TextField();
			if( !_txtFormat )	        _txtFormat          = new TextFormat();
			if( !_gradBoxM )
			{
				_gradBoxM         = new MovieClip();
				_gradBoxMGraphics = _gradBoxM.graphics;
			}
			if( !_gradBox )
			{
				_gradBox            = new Shape();
				_gradBoxGraphics    = _gradBox.graphics;
			}

			_txt.x = -1024;
			Starling.current.nativeStage.addChild( _txt );
		}

		private var mMatrix:Matrix = new Matrix();

		/**
		 * Fill the QuadBatch with text, no reset will be call on the QuadBatch
		 * @param parent the HTMLTextField container
		 * @param width container width
		 * @param height container height
		 * @param text the text String
		 * @param retour
		 * @param fontSizes (default null->base size) the array containing the size by char. (if shorter than the text,
		 *     the last value is used for the rest)
		 * @param styles (default null->base style) the array containing the style by char. (if shorter than the text,
		 *     the last value is used for the rest)
		 * @param colors (default null->0xFFFFFF) the array containing the colors by char, no tint -> 0xFFFFFF (if
		 *     shorter than the text, the last value is used for the rest)
		 * @param underlines
		 * @param links
		 * @param hAlign (default center) horizontal align rule
		 * @param vAlign (default center) vertical align rule
		 * @param autoScale (default true) if true the text will be reduced for fiting the container size (if smaller
		 *     font size are available)
		 * @param resizeQuad (default false) if true, the Quad can be bigger tahn width, height if the texte cannot
		 *     fit.
		 * @param autoCR (default true) do auto line break or not.
		 * @param maxWidth the max width if resizeQuad is true.
		 * @param minFontSize the minimum font size to reduce to.
		 * @param contourColor
		 * @param contourSize
		 * @param contourStrength
		 * @param shadowX
		 * @param shadowY
		 * @param shadowColor
		 **/
		public function getImage(    parent:HTMLTextField, width:Number, height:Number, text:String, retour:Image,
									  fontSizes:Array = null, styles:Array = null, colors:Array = null, underlines:Array = null, links:Array = null,
									  hAlign:String="center", vAlign:String="center", autoScale:Boolean=true, resizeQuad:Boolean = false,
									  autoCR:Boolean = true, maxWidth:int = 900, minFontSize:int = 10,
									  contourColor:uint = 0, contourSize:uint = 0, contourStrength:uint = 0,
									  shadowX:int = 0, shadowY:int = 0, shadowColor:uint = 0x0 ):Image
		{
			width *= globalScale;
			height *= globalScale;
			maxWidth *= globalScale;
			shadowX *= globalScale;
			shadowY *= globalScale;
			contourSize *= globalScale;
			contourStrength *= globalScale;

			if( enableGroupping )   _canEmbed = isAllAvailable(text);

			// on vide le sprite conteneur
			//retour.removeChildren(0,-1,true);

			// si on a des liens on clone le tabelau de lein et on vide l'actuel pour pouvoir el mettre a jour
			var linksIds:Array;
			if( links )
			{
				linksIds = links.concat();
				links.length = 0;
			}

			// un i c'est toujours utile !
			var i               :int;
			// générer le tableau de CharLocation
			var charLocations	:Vector.<DeviceFontCharLocation> = arrangeCharsDevice( width, height, text, fontSizes.concat(), styles.concat(), colors.concat(), underlines.concat(), linksIds, hAlign, autoScale, resizeQuad, autoCR, maxWidth, minFontSize );
			// récupérer le nombre de caractères à traiter
			var numChars		:int = charLocations.length;

			// la variable pour contenir la couleur du (groupe de) caractere actuellement traité
			var color			:*;
			// la variable pour contenir le groupe de caracteres actuellement traités
			var charLocation	:DeviceFontCharLocation;
			// la largeur max
			var wMax            :int = 0;
			// la hauteur max
			var hMax            :int = 0;
			// la position x minimale
			var minX            :int = int.MAX_VALUE;
			// la position y minimale
			var minY            :int = int.MAX_VALUE;

			// on parcours une premiere fois les caratcres pour récuperer les bounds
			// afin de pouvoir creer le bitmapData
			for( i=0; i<numChars; ++i )
			{
				if( !charLocations[i] ) continue;
				
				// récupérer le CharLocation du caractère actuel
				charLocation = charLocations[i];

				//wMax dépassé on enregistre le nouveau
				if( charLocation.x + charLocation.width > wMax )
					wMax = charLocation.x + charLocation.width;

				//hMax dépassé on enregistre le nouveau
				if( charLocation.y + charLocation.height + charLocation.baseLine > hMax )
					hMax = charLocation.y + charLocation.height + charLocation.baseLine;

				//minX dépassé on enregistre le nouveau
				if( charLocation.x < minX )
					minX = charLocation.x;

				//minY dépassé on enregistre le nouveau
				if( charLocation.y < minY )
					minY = charLocation.y;
			}

			// une petite marge de 2px + contour ca fait pas de mal
			hMax += contourSize + 2;
			wMax += contourSize + 2;
			minX -= contourSize + 2;
			minY -= contourSize + 2;

			// calculer la largeur du bitmapData a générer
			var ww:int = wMax-minX;
			var hh:int = hMax-minY;
			// BitmapData invalide on met 1px mini
			if( ww < 1 )	ww = 1;
			if( hh < 1 )	hh = 1;

			var bd          :BitmapData;
			var bitmapData  :BitmapData = new BitmapData(ww,hh,true,0x0);

			// parcourir les caractères pour les placer sur le QuadBatch
			for( i=0; i<numChars; ++i )
			{
				if( !charLocations[i] )
				{
					continue;
				}
				
				// récupérer le CharLocation du caractère actuel
				charLocation = charLocations[i];

				// recup la couleur
				if( !charLocation.isEmote ) color = charLocation.color;
				else                        color = 0xFFFFFF;

				// creating underlines
				if( charLocation.underline )
					addUnderlineTexture( bitmapData, charLocation, color, minX, minY );

				// creating char(s)
				if( !charLocation.isEmote ) // appliquer la texture du caractere à l'image
					addCharTexture( bitmapData, charLocation, color, minX, minY );
				else                        // appliquer la texture de l'emote à l'image
					addEmoteTexture( bitmapData, charLocation, 0xFFFFFF, minX, minY );

				// gestion des liens
				if( links && charLocation.linkID != -1 )
					links.push( [charLocation.linkID, charLocation.x-minX, charLocation.y-minY, charLocation.width, charLocation.height] );
			}

			// si on a un contour
			if( contourSize > 0 && contourStrength > 0 )
			{
				// on créé le filtre contour
				if( !contourFilter )    contourFilter = new GlowFilter();
				contourFilter.blurX     = contourSize;
				contourFilter.blurY     = contourSize;
				contourFilter.strength  = contourStrength;
				contourFilter.quality   = 1;
				contourFilter.color     = contourColor;

				// on applique le filtre au bitmapData
				bitmapData.applyFilter( bitmapData, bitmapData.rect, new Point(), contourFilter );
			}

			// si ya un shadow
			if( shadowX != 0 || shadowY != 0 )
			{
				// on creer un bitmapData plus grand de shadowX * shadowY
				ww = bitmapData.width + shadowX;
				hh = bitmapData.height + shadowY;
				bd = new BitmapData(ww,hh,true,0x0);

				// on creer une matrice déplacement de shadowX * shadowY
				mMatrix.identity();
				mMatrix.translate(shadowX, shadowY);

				// on créé une transfroamtion de couleur pour colorer le shadow
				var trans:ColorTransform = new ColorTransform();
				trans.color = shadowColor;

				// on redessine le shadow
				bd.drawWithQuality(bitmapData, mMatrix, trans, null, null, false, StageQuality.BEST);
				// on redessine la couleur
				bd.drawWithQuality(bitmapData, null, null, null, null, false, StageQuality.BEST);

				// on dispose l'ancien BitmapData
				bitmapData.dispose();
				// on met a jour el bitmapData avec le nouveau
				bitmapData = bd;
			}

			// Crop BitmapData

			// no récupere les bounds non transparents de l'image
			var bounds:Rectangle = bitmapData.getColorBoundsRect(0xFFFFFFFF, 0x000000, false);
			if( bounds.width < 1 )  bounds.width = 1;
			if( bounds.height < 1 ) bounds.height = 1;
			// on crée un nouveau bitmapData
			bd = new BitmapData(bounds.width, bounds.height, true, 0x0);
			// on crée la matric de translation
			mMatrix.identity();
			mMatrix.translate(-bounds.x, -bounds.y);
			// on draw la partie visible
			bd.drawWithQuality(bitmapData, mMatrix, null, null, null, false, StageQuality.BEST);
			// on dispose l'ancien BitmapData
			bitmapData.dispose();
			// on met a jour el bitmapData avec le nouveau
			bitmapData = bd;
			// reset bounds x et y
			bounds.x = bounds.y = 0;

			// générer la texture
			var tex:Texture = Texture.fromBitmapData( bitmapData, false );
			tex.root.onRestore = function():void{
				parent.forceRedraw();
			};

			// Aligner

			ww = width;
			if( resizeQuad && bitmapData.width > ww )   ww = bitmapData.width;

			hh = height;
			if( resizeQuad && bitmapData.height > hh )  hh = bitmapData.height;

			//var bounds:Rectangle = bitmapData.getColorBoundsRect(0xFFFFFFFF, 0x000000, false);

			var yOffset:int = 0;
			switch(vAlign)
			{
				case Align.TOP:
					yOffset = -bounds.y;
					break;

				case Align.BOTTOM:
					yOffset = hh-bounds.height-bounds.y;
					break;

				case Align.CENTER:
					yOffset = ((hh-bounds.height)>>1)-bounds.y;
					break;
			}

			var xOffset:int = 0;
			switch(hAlign)
			{
				case Align.LEFT:
					xOffset = -bounds.x;
					break;

				case Align.RIGHT:
					xOffset = ww-bounds.width-bounds.x;
					break;

				case Align.CENTER:
				case HTMLTextField.LEFT_CENTERED:
				case HTMLTextField.RIGHT_CENTERED:
					xOffset = ((ww-bounds.width)>>1)-bounds.x;
					break;
			}

			if( retour )
			{
				retour.texture = tex;
				retour.readjustSize();
			}
			else
			{
				retour = ImagePool.get(tex);
			}
			retour.x       = xOffset/globalScale;
			retour.y       = yOffset/globalScale;
			retour.scale   = 1/globalScale;

			bitmapData.dispose();
			bitmapData = null;

			DeviceFontCharLocation.rechargePool();

			// on ajoute l'offset et le scale à la fin
			if( links )  links.push( xOffset, yOffset, 1/globalScale );

			return retour;
		}
		
		protected static var mHelperText:TextField; 
		
		/** Arranges the characters of a text inside a rectangle, adhering to the given settings. 
		 *  Returns a Vector of CharLocations. */
		protected function arrangeCharsDevice( width:Number, height:Number, text:String, 
										 fontSizes:Array = null, styles:Array = null, colors:Array = null, underlines:Array = null, links:Array = null,
										 hAlign:String="center", autoScale:Boolean=true, resizeQuad:Boolean = false,
										 autoCR:Boolean = true, maxWidth:int = 900, minFontSize:int = 10 ):Vector.<DeviceFontCharLocation>
		{
			// si pas de texte on renvoi un tableau vide
			if( text == null || text.length == 0 ) 		return DeviceFontCharLocation.vectorFromPool();
			
			// creer le textField a screenshoter
			if( !mHelperText )	mHelperText = new TextField();
			
			// aucun style définit, on force le style de base
			if( !styles || styles.length == 0 ) 		    styles 		= [_baseStyle];
			// aucune taille définie, on force la taille de base
			if( !fontSizes || fontSizes.length == 0 )	    fontSizes 	= [_baseSize];
			// aucune couleur définie, on force la couleur de base
			if( !colors || colors.length == 0 )             colors      = [0x0];
			// aucune underline définie, on en met pas
			if( !underlines || underlines.length == 0 )     underlines  = [false];
			// aucun link défini, on en met pas
			if( !links || links.length == 0 )               links  = [-1];

			var i:int;
			// passe a true une fois qu'on a fini de rendre le texte
			var finished			:Boolean = false;
			// une charLocation pour remplir le vecteur de lignes
			var charLocation		:DeviceFontCharLocation;
			// le nombre de caracteres à traiter
			var numChars			:int;
			// la hauteur de ligne pour le plus gros caractère
			var biggestLineHeight	:int;
			// la taille de font du caractere actuel
			var sizeActu			:int;
			// la style de font du caractere actuel
			var styleActu			:int;
			// l'id du link actuel
			var linkActu			:int = -1;
			// la couleur actuelle
			var colorActu           :*;
			// la underline actuelle
			var underlineActu       :Boolean;
			// le groupe actuel
			var group               :Vector.<int> = new <int>[];

			while( !finished )
			{
				// init/reset le tableau de lignes
				dlines.length 		= 0;
				linesSizes.length 	= 0;
				baselines.length 	= 0;
				
				// récuperer la hauteur du plus haut caractere savoir si il rentre dans la zone ou pas
				biggestLineHeight 	= Math.ceil( _getBiggestLineHeightDevice( fontSizes ) );
				
				// si le plus gros caractere rentre en hauteur dans la zone spécifiée
				if( resizeQuad || biggestLineHeight <= height )
				{
					var lineStart		:int		= 0;
					var emoteInLine		:int 		= 0;
					var lastWhiteSpace	:int 		= -1;
					var lastWhiteSpaceL	:int 		= -1;
					var lastCharID		:int 		= -1;
					var currentX		:Number 	= 0;
					var currentY		:Number 	= 0;
					var currentLine		:Vector.<DeviceFontCharLocation> = DeviceFontCharLocation.vectorFromPool();
					var currentBaseline	:Number 	= 0;
					var realMaxSize		:Number 	= 0;
					var lineHeight		:Number;
					var baseLine		:Number;

					// reset reduced sizes
					_reducedSizes 		= null;
					
					numChars = text.length;
					for( i = 0; i<numChars; ++i )
					{
						// récupérer la taille actuelle
						if( i < fontSizes.length )		    sizeActu 	    = fontSizes[i];
						// récupérer le syle actuel
						if( i < styles.length )			    styleActu 	    = styles[i];
						// récupérer la couleur actuelle
						if( i < colors.length )             colorActu       = colors[i];
						// récupérer la couleur actuelle
						if( i < underlines.length )         underlineActu   = underlines[i];
						// récupérer le lien
						if( i < links.length )              linkActu        = links[i];

						// reset le isEmote
						var isEmote		:int 		= -1;
						// c'est une nouvelle ligne donc la ligne n'est surrement pas finie
						var lineFull	:Boolean 	= false;
						// récupérer le CharCode du caractère actuel
						var charID		:int 		= text.charCodeAt(i);

						// retour à la ligne
						if( charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN )		lineFull = true;
						else
						{
							// on enregistre le placement du dernier espace
							if( charID == CHAR_SPACE /*|| charID == CHAR_TAB*/ || charID == CHAR_SLASH )	
							{
								lastWhiteSpace = i;
								lastWhiteSpaceL = i-lineStart-emoteInLine;
							}
							
							if( _emotesTxt )
							{
								for( var e:int = 0; e<_emotesTxt.length; ++e )
								{
									if( text.charAt(i) == _emotesTxt[e].charAt(0) && text.substr(i,_emotesTxt[e].length) == _emotesTxt[e] )
									{
										isEmote = e;//char = _emotesTextures[e];
										i += _emotesTxt[e].length-1;
										break;
									}
								}
							}

							var isBold	:Boolean    = styleActu == BitmapFontStyle.BOLD || styleActu == BitmapFontStyle.BOLD_ITALIC;
							var isItalic:Boolean    = styleActu == BitmapFontStyle.ITALIC || styleActu == BitmapFontStyle.BOLD_ITALIC;
							var nextChar:int        = text.length > i + 1 ? text.charCodeAt( i + 1 ) : -1;

							// ajouter le nombre de carateres pris par une emote 
							if( isEmote >= 0 )							
							{
								if( enableGroupping )
								{
									if( group && group.length > 0 )
									{
										renderChars( group, sizeActu, isBold, isItalic, colorActu, underlineActu, linkActu, nextChar );
										group = new <int>[];
									}
								}

								charLocation = renderEmote(isEmote, colorActu, underlineActu);
								emoteInLine += _emotesTxt[e].length-1;
								
								if( isEmote && charLocation.height > realMaxSize )
								{
									// si l'emote est plus grand on descend tous les caracteres de la ligne
									var dif:int = ( (charLocation.height - realMaxSize) >> 1 )+2;
									currentY += dif;
									for( var a:int = 0; a<currentLine.length; ++a )
									{
										currentLine[a].y += dif;
									}
									realMaxSize = charLocation.height;
								}
							}
							else
							{
								if( enableGroupping && charID != CHAR_SPACE )
								{
									group.push( charID );

									var nextStyle       :int        = styles.length > i + 1     ? styles[i + 1]     : styles[styles.length - 1];
									var nextColor       :*          = colors.length > i + 1     ? colors[i + 1]     : colors[colors.length - 1];
									var nextSize        :int        = fontSizes.length > i + 1  ? fontSizes[i + 1]  : fontSizes[fontSizes.length - 1];
									var nextUnderline   :Boolean    = underlines.length > i + 1 ? underlines[i+1]   : underlines[underlines.length-1];
									var nextLink        :int        = links.length > i + 1      ? links[i+1]        : links[links.length-1];

									if( styleActu != nextStyle || String(colorActu) != String(nextColor) || sizeActu != nextSize || underlineActu != nextUnderline || linkActu != nextLink ||
										nextChar == -1 || nextChar == CHAR_SPACE || nextChar == CHAR_TAB || nextChar == CHAR_NEWLINE || nextChar == CHAR_NEWLINE || nextChar == CHAR_SLASH )
									{
										charLocation = renderChars( group, sizeActu, isBold, isItalic, colorActu, underlineActu, linkActu, nextChar );
										group = new <int>[];
									}
									else
									{
										continue;
									}
								}
								else
								{
									charLocation = renderChar( charID, sizeActu, isBold, isItalic, colorActu, underlineActu, linkActu );
								}
							}

							lineHeight 		= charLocation.lineHeight;
							baseLine 		= charLocation.baseLine;

							//if( lineHeight > currentMaxSize )				        currentMaxSize 	= lineHeight;
							if( baseLine > currentBaseline )	                    currentBaseline = baseLine;
							if( lineHeight > realMaxSize )	                        realMaxSize 	= lineHeight;

							// définir la position du caractère en x
							charLocation.x 			= currentX + charLocation.xOffset;
							// définir la position du caractère en y
							charLocation.y 			= currentY + charLocation.yOffset;

							// on ajoute le caractère au tableau
							currentLine.push( charLocation );

							if( enableGroupping && (charID == CHAR_SPACE || charID == CHAR_SLASH) )
							{
								lastWhiteSpace = i-1;
								lastWhiteSpaceL = currentLine.length-1;
							}

							// on met a jour la position x du prochain caractère si ce n'est pas le premier espace
							// d'une ligne
							if( currentLine.length != 1 || charID != CHAR_SPACE )	
							{
								currentX += charLocation.xAdvance;
							}
							
							// on enregistre le CharCode du caractère
							lastCharID = charID;
							
							// fin de ligne car dépassement de la largeur du conteneur
							if( (resizeQuad && charLocation.x + charLocation.xAdvance > maxWidth) || (!resizeQuad && charLocation.x + charLocation.xAdvance > width) )
							{
								// tenter voir si on peut mettre le texte a la ligne
								if( autoCR && (resizeQuad || currentY + 2*realMaxSize + _lineSpacing <= height) )
								{
									// si autoscale est a true on ne doit pas couper le mot en 2
									if( autoScale && lastWhiteSpace < 0 )		
									{
										if( resizeQuad )	
										{
											if( width < maxWidth )
											{
												width = charLocation.x + charLocation.xAdvance <= maxWidth ? charLocation.x + charLocation.xAdvance : maxWidth;
												break;
												//goto suite;
											}
										}
										else if( _reduceSizes(fontSizes, minFontSize, text) )
										{
											break;
										}

									}
									
									// si c'est un emote on retourne au debut de l'emote avant de couper
									if( isEmote != -1 )			i -= _emotesTxt[e].length-1;

									var skip:Boolean = false;
									if( lastWhiteSpace >= 0 && lastWhiteSpaceL >= 0 )
									{
										// si on a eu un espace on va couper apres le dernier espace sinon on coupe à
										// lindex actuel
										var numCharsToRemove:int = currentLine.length - lastWhiteSpaceL + 1; //i -
																											 // lastWhiteSpace
																											 // + 1;
										var removeIndex:int = lastWhiteSpaceL + 1; //lastWhiteSpace+1;//currentLine.length
																				   // - numCharsToRemove + 1;

										// couper la ligne
										var temp:Vector.<DeviceFontCharLocation> = DeviceFontCharLocation.vectorFromPool();
										var l:int                                = currentLine.length;

										for( var t:int = 0; t < l; ++t )
										{
											if( t < removeIndex || t >= removeIndex + numCharsToRemove )    temp.push( currentLine[t] );
										}

										// il faut baisser la taille de la font -> on arrete la
										if( temp.length == 0 )
										{
											if( resizeQuad )    skip = true;
											else
											{
												_reduceSizes( fontSizes, minFontSize, text );
												break;
											}

										}
										if( !skip )
										{
											currentLine = temp;
											i           = lastWhiteSpace;
										}
									}

									if( !skip )
									{
										lineFull = true;
										// si le prochain caractere est un saut de ligne, on l'ignore
										if( text.charCodeAt( i + 1 ) == CHAR_CARRIAGE_RETURN || text.charCodeAt( i + 1 ) == CHAR_NEWLINE )
										{
											++i;
										}
									}
								}
								else
								{
									_reduceSizes(fontSizes, minFontSize, text);
									break;
								}
							}
							
						}
						
						// fin du texte
						if( i == numChars - 1 )
						{
							dlines.push( currentLine );
							linesSizes.push( realMaxSize );
							baselines.push( currentBaseline );
							finished = true;
						}
						// fin de ligne
						else if( lineFull )
						{
							currentLine.push(null);
							dlines.push( currentLine );
							linesSizes.push( realMaxSize );
							baselines.push( currentBaseline );
							
							// on a la place de mettre une nouvelle ligne
							if( resizeQuad || currentY + 2*realMaxSize + _lineSpacing <= height )
							{
								// créer un tableau pour la nouvelle ligne
								currentLine = DeviceFontCharLocation.vectorFromPool();
								// remettre le x à 0
								currentX = 0;
								// mettre le y à la prochaine ligne
								currentY += realMaxSize+_lineSpacing;
								// reset lastWhiteSpace index
								lastWhiteSpace = -1;
								lastWhiteSpaceL = -1;
								emoteInLine = 0;
								lineStart = i+1;
								// reset lastCharID vu que le kerning ne va pas s'appliquer entre 2 lignes
								lastCharID = -1;
								// reset la taille max pour la ligne
								currentBaseline = realMaxSize = 0;//currentMaxBase =
								//currentMaxBase = 0;
							}
							else
							{
								// il faut baisser la taille de la font -> on arrete la
								_reduceSizes(fontSizes, minFontSize, text);
								break;
							}
						}
					} // for each char
				} // if( resizeQuad || biggestLineHeight <= containerHeight )
				else
				{
					_reduceSizes(fontSizes, minFontSize, text);
				}
				
				// si l'autoscale est activé et que le texte ne rentre pas dans la zone spécifié, on réduit la taille
				// de la police
				if( (autoScale || (resizeQuad && width >= maxWidth)) && !finished && _reducedSizes )
				{
					fontSizes 		= _reducedSizes;
					_reducedSizes 	= null;
				}
				else if( !finished && (!resizeQuad || width >= maxWidth) )
				{
					// on peut rien y faire on y arrivera pas c'est fini
					finished = true; 
					if( currentLine )
					{
						// supprimer le dernier caractere vu que si on est ici c'est qu'il passait pas 
						currentLine.pop();
						dlines.push( currentLine );
						linesSizes.push( realMaxSize );
						baselines.push( currentBaseline );
					}
				}
			} // while (!finished)
			
			// le tableau de positionnement final des caractères
			var finalLocations	:Vector.<DeviceFontCharLocation> 	= DeviceFontCharLocation.vectorFromPool();
			// le nombre de lignes
			var numLines		:int 					= dlines.length;
			// le y max du texte
			//var bottom			:Number 				= currentY + currentMaxSizeS + (currentMaxBaseS>>1);
			// l'offset y
			//var yOffset			:int 					= 0;
			// la ligne à traiter
			var line			:Vector.<DeviceFontCharLocation>;
			// un j
			var j				:int;
			// la largeur du texte au cas ou on ait du l'agrandir
			var ww              :int = width;
			/*var hh              :int = height;

			if( bottom > hh )   hh = bottom;*/

			//baseY = 0;

			/*if( vAlign == VAlign.TOP )      			yOffset 	= baseY;
			else if( vAlign == VAlign.BOTTOM )  		yOffset 	= baseY + (hh-bottom);
			else if( vAlign == VAlign.CENTER ) 			yOffset 	= baseY + (hh-bottom)/2;

			if( yOffset < 0 )							yOffset 	= 0;*/
			
			// la taille de la ligne la plus longue utile pour les LEFT_CENTERED et RIGHT_CENTERED
			var longestLineWidth:Number = 0;
			
			if( resizeQuad || hAlign == HTMLTextField.RIGHT_CENTERED || hAlign == HTMLTextField.LEFT_CENTERED )
			{
				for( i=0; i<numLines; ++i )
				{
					// récupérer la ligne actuelle
					line 		= dlines[i];
					// récupérer le nombre de caractères sur la ligne
					numChars 	= line.length;
					// si ligne vide -> on passe à la suivante
					if( numChars == 0 ) 	continue;
					
					for( j = numChars-1;j>=0; --j )
					{
						if( !line[j] || (line[j].charIDs == null && line[j].charID == CHAR_SPACE) )		continue;

						if( line[j].x + line[j].xAdvance > longestLineWidth )
							longestLineWidth = line[j].x + line[j].xAdvance;
					}
				}
			}

			if( longestLineWidth > ww ) ww = longestLineWidth;

			var c:int, xOffset:int, right:Number, lastLocation:DeviceFontCharLocation;

			// parcourir les lignes
			for( var lineID:int=0; lineID<numLines; ++lineID )
			{
				// récupérer la ligne actuelle
				line 		= dlines[lineID];
				// récupérer le nombre de caractères sur la ligne
				numChars 	= line.length;
				
				// si ligne vide -> on passe à la suivante
				if( numChars == 0 ) continue;

				// l'offset x
				xOffset	= 0;
				// la position du dernier caractère de la ligne
				j = 1;
				lastLocation = null;
				while( lastLocation == null && line.length-j >= 0 )
				{
					lastLocation = line[line.length-j++];
					if( lastLocation && lastLocation.charIDs == null && lastLocation.charID == CHAR_SPACE )
					{
						lastLocation = null;
					}
				}
				// le x max de la ligne
				right = lastLocation ? lastLocation.x + lastLocation.xAdvance : 0;

				// calculer l'offset x en fonction de la règle d'alignement horizontal
				if( hAlign == Align.CENTER ) 	                    xOffset = (ww - right) / 2;
				else if( hAlign == HTMLTextField.RIGHT_CENTERED ) 	xOffset = longestLineWidth + (ww - longestLineWidth) / 2 - right;
				else if( hAlign == HTMLTextField.LEFT_CENTERED ) 	xOffset = (ww - longestLineWidth) / 2;

				if( xOffset < 0 ) xOffset = 0;

				// parcourir les caractères
				for( c=0; c<numChars; ++c )
				{
					// récupérer le CharLocation
					charLocation = line[c];
					if( charLocation )
					{
						// appliquer l'offset x et le _globalScale à la positon x du caractère
						charLocation.x = charLocation.x + xOffset;
						// aligner les emotes
						if( charLocation.isEmote )
							charLocation.y -= (linesSizes[lineID] - (linesSizes[lineID]-baselines[lineID])*2)>>1;

						// ajouter le caractere au tableau
						finalLocations.push(charLocation);
					}
				}
			}
			
			dlines.length 		= 0;
			linesSizes.length 	= 0;
			
			return finalLocations;
		}

		private static var _gradBoxM    :MovieClip;
		private static var _gradBox     :Shape;
		private static var _txt			:TextField;
		private static var _txtFormat	:TextFormat;
		private function renderChar( id:int, size:int, bold:Boolean = false, italic:Boolean = false, color:* = 0xFFFFFF, underline:Boolean = false, link:int = -1 ):DeviceFontCharLocation
		{
			_txtFormat.size 		= size*globalScale;
			_txtFormat.color 		= 0xFFFFFF;
			_txtFormat.bold			= bold;
			_txtFormat.italic		= italic;
			_txtFormat.kerning		= true;
			_txtFormat.font 		= mName;
			_txt.embedFonts			= true;

			_txt.defaultTextFormat 	= _txtFormat;
			_txt.text 				= String.fromCharCode(id);

			_txt.antiAliasType = AntiAliasType.NORMAL;
			_txt.sharpness = -20;
			_txt.thickness = 50;
			_txt.gridFitType = GridFitType.PIXEL;

			if (_txt.textWidth == 0.0 || _txt.textHeight == 0.0)
				_txt.embedFonts = false;

			var loc:DeviceFontCharLocation = DeviceFontCharLocation.instanceFromPool( null );

			/*if( nextChar != -1 )
			{
				_txt.text += String.fromCharCode(nextChar);
				if( !_txt.getCharBoundaries(1) )	_txt.text = String.fromCharCode(id)+'a';
			}
			else					_txt.text += 'a';*/

			var metrics:TextLineMetrics = _txt.getLineMetrics(0);
			var bounds:Rectangle = _txt.getCharBoundaries(0);

			loc.charID 		= id;
			loc.lineHeight 	= metrics.height;
			loc.height 		= bounds.height;
			loc.width 		= bounds.width+(bounds.width>>1);
			loc.xAdvance	= bounds.width;
			loc.xOffset		= 0;
			loc.yOffset		= -metrics.ascent-1;//-(metrics.descent+metrics.leading);
			loc.baseLine	= metrics.ascent;//metrics.ascent - metrics.height;
			loc.isBold		= bold;
			loc.isItalic	= italic;
			loc.size		= size*globalScale;
			loc.name		= mName;
			loc.color       = color;
			loc.underline   = underline;
			loc.linkID      = link;

			_txt.text = "";
			
			return loc;
		}

		private function renderChars( ids:Vector.<int>, size:int, bold:Boolean = false, italic:Boolean = false, color:* = 0xFFFFFF, underline:Boolean = false, link:int = -1, nextChar:int = -1 ):DeviceFontCharLocation
		{
			_txtFormat.size 		= size*globalScale;
			_txtFormat.color 		= 0xFFFFFF;
			_txtFormat.bold			= bold;
			_txtFormat.italic		= italic;
			_txtFormat.kerning		= true;
			_txtFormat.font 		= mName;
			_txt.embedFonts			= true;

			_txt.defaultTextFormat 	= _txtFormat;

			var len:int = ids.length;
			var txt:String = '';
			for( var i:int = 0; i<len; ++i )
			{
				txt += String.fromCharCode(ids[i])
			}
			_txt.text = txt;
			_txt.antiAliasType = AntiAliasType.NORMAL;
			_txt.sharpness = -20;
			_txt.thickness = 50;
			_txt.gridFitType = GridFitType.PIXEL;

			if (!_canEmbed || _txt.textWidth == 0.0 || _txt.textHeight == 0.0)
				_txt.embedFonts = false;

			var loc:DeviceFontCharLocation = DeviceFontCharLocation.instanceFromPool( null );

			if( nextChar != -1 )
			{
				_txt.text += String.fromCharCode(nextChar);
				//if( !_txt.getCharBoundaries(1) )	_txt.text = String.fromCharCode(id)+'a';
			}
			else					_txt.text += 'a';

			var metrics:TextLineMetrics = _txt.getLineMetrics(0);
			var bounds0:Rectangle = _txt.getCharBoundaries(0);
			var bounds1:Rectangle = _txt.getCharBoundaries(len-1);
			var union:Rectangle = bounds0.union(bounds1);

			loc.charID      = nextChar;
			loc.charIDs 	= ids;
			loc.lineHeight 	= metrics.height;
			loc.height 		= union.height;
			loc.width 		= union.width+(bounds1.width>>1);
			loc.xAdvance	= union.width;
			loc.xOffset		= 0;
			loc.yOffset		= -metrics.ascent-1;
			loc.baseLine	= metrics.ascent;//metrics.ascent - metrics.height;
			loc.isBold		= bold;
			loc.isItalic	= italic;
			loc.size		= size*globalScale;
			loc.name		= mName;
			loc.color       = color;
			loc.underline   = underline;
			loc.linkID      = link;

			_txt.text = "";

			return loc;
		}

		private static function renderEmote( id:int, color:* = 0xFFFFFF, underline:Boolean = false ):DeviceFontCharLocation
		{
			var loc :DeviceFontCharLocation = DeviceFontCharLocation.instanceFromPool( _emotesLinkages[id] );

			loc.isEmote		= true;
			loc.lineHeight 	= _emotesLinkages[id].height;
			loc.height 		= _emotesLinkages[id].height;
			loc.width 		= _emotesLinkages[id].width;
			loc.xAdvance	= _emotesLinkages[id].width + 15;//_emotesTextures[id].xAdvance;
			loc.xOffset		= 10;//_emotesTextures[id].xOffset;
			loc.yOffset		= -_emotesLinkages[id].height>>1;//(_emotesLinkages[id].height>>1)-1;//_emotesLinkages[id].height>>1;//_emotesTextures[id].yOffset;
			loc.baseLine    = 0;//-_emotesLinkages[id].height;
			loc.color       = color;
			loc.underline   = underline;
			return loc;
		}

		/** le multiplicateur d'élargissement pour faire l'antialiasing sur les textes non embed **/
		private static const AA_ENLARGE :Number = 2.0;
		/** le tbealu des alpha de dégradés **/
		private static const ALPHAS     :Array  = [1,1];
		/** le tableau des ratios de dégradés **/
		private static const RATIOS     :Array  = [0x00, 0xFF];
		/** la matrice utilisée pour les dégradés de couleur **/
		private static const GRAD_MAT   :Matrix = new Matrix();

		private static var _gradBoxGraphics:Graphics;
		private static var _gradBoxMGraphics:Graphics;

		[Inline]
		public static function addCharTexture( bitmapData:BitmapData, charLoc:DeviceFontCharLocation, color:*, offsetX:int, offsetY:int ):void
		{
			_txtFormat.size 		= charLoc.size;
			_txtFormat.color 		= 0xFFFFFF;
			_txtFormat.bold			= charLoc.isBold;
			_txtFormat.italic		= charLoc.isItalic;
			_txtFormat.font 		= charLoc.name;
			// si on a un dégradé on va forcer la couleur du texte en noir pour pouvoir appliquer le texte en masque
			_txtFormat.color        = color is int ? color : 0x0;

			_txt.embedFonts			= true;
			_txt.defaultTextFormat 	= _txtFormat;

			var str :String = '';
			if( charLoc.charIDs )
			{
				var len:int = charLoc.charIDs.length;
				for( var i:int = 0; i < len; ++i )
				{
					str += String.fromCharCode( charLoc.charIDs[i] );
				}
			}
			else
			{
				str = String.fromCharCode( charLoc.charID );
			}
			_txt.text 				= str;

			_txt.antiAliasType      = AntiAliasType.NORMAL;
			_txt.sharpness          = -20;
			_txt.thickness          = 50;
			_txt.gridFitType        = GridFitType.PIXEL;
			_txt.autoSize           = TextFieldAutoSize.LEFT;

			// de base on met a 1 pour pas appliquer le fake antialias (pas besoin sur les embed fonts)
			var aa_enlarge:Number   = 1;

			if( !_canEmbed || _txt.textWidth == 0.0 || _txt.textHeight == 0.0 )
			{
				// on peut pas embed on va généré la font en x2 pour réduire afin de faire un fake antialias
				aa_enlarge              = charLoc.size > 12 ? AA_ENLARGE : 1;

				_txtFormat.size         = charLoc.size * aa_enlarge;
				_txt.defaultTextFormat 	= _txtFormat;
				_txt.text 				= str;
				_txt.embedFonts         = false;
			}

			/*var bdtmp:BitmapData = new BitmapData(char.width*2*aa_enlarge, char.height*2*aa_enlarge, true, 0xFFFFFF);
			bdtmp.drawWithQuality(_txt, null, null, null, null, true, StageQuality.BEST);*/

			var mat:Matrix = new Matrix(1/aa_enlarge,0,0,1/aa_enlarge);
			mat.translate( charLoc.x-offsetX, charLoc.y-offsetY );

			if( color is int )
			{
				//bitmapData.drawWithQuality(bdtmp, mat, null, null, null, true, StageQuality.BEST);
				bitmapData.drawWithQuality(_txt, mat, null, null, null, true, StageQuality.BEST);
			}
			else
			{
				var bdtmp:BitmapData = new BitmapData(charLoc.width*2*aa_enlarge, charLoc.height*2*aa_enlarge, true, 0xFFFFFF);
				bdtmp.drawWithQuality(_txt, null, null, null, null, true, StageQuality.BEST);

				GRAD_MAT.createGradientBox(charLoc.width*aa_enlarge, charLoc.height*aa_enlarge, Math.PI/2, 0, 0);

				var btemp:Bitmap = new Bitmap(bdtmp,PixelSnapping.ALWAYS,true);
				btemp.cacheAsBitmap = true;

				_gradBoxMGraphics.clear();
				_gradBoxMGraphics.beginGradientFill(GradientType.LINEAR, [color[0], color[2]], ALPHAS, RATIOS, GRAD_MAT);
				_gradBoxMGraphics.drawRect(0, 0, bdtmp.width, bdtmp.height);
				_gradBoxMGraphics.endFill();
				_gradBoxM.addChild( btemp );
				_gradBoxM.mask = btemp;
				_gradBoxM.cacheAsBitmap = true;

				bitmapData.drawWithQuality(_gradBoxM, mat, null, null, null, true, StageQuality.BEST);

				_gradBoxM.removeChild(btemp);
				_gradBoxM.mask = null;

				bdtmp.dispose();
			}
			//bdtmp.dispose();
		}

		private static function addUnderlineTexture( bitmapData:BitmapData, charLoc:DeviceFontCharLocation, color:*, offsetX:int, offsetY:int ):void
		{
			if( color is Array )    color = color[2];

			var ww:int = charLoc.xAdvance + 2;
			var hh:int = int(charLoc.lineHeight/18);
			if( hh < 1 )    hh = 1;

			var xx:int = charLoc.x - offsetX + 2;
			var yy:int = Math.ceil(charLoc.y - offsetY + charLoc.baseLine + hh+ (2*globalScale) );

			_gradBoxGraphics.clear();
			_gradBoxGraphics.beginFill(color);
			_gradBoxGraphics.drawRect(xx, yy, ww, hh);
			_gradBoxGraphics.endFill();

			bitmapData.drawWithQuality(_gradBox, null, null, null, null, false, StageQuality.BEST);
		}

		private static function addEmoteTexture( bitmapData:BitmapData, charLoc:DeviceFontCharLocation, color:*, offsetX:int, offsetY:int ):void
		{
			var mat:Matrix = new Matrix();
			mat.translate( charLoc.x-offsetX, charLoc.y-offsetY );

			if( color is int )
			{
				var t:ColorTransform = new ColorTransform();
				t.blueMultiplier = Colors.extractBlue(color) / 255;
				t.greenMultiplier = Colors.extractGreen(color) / 255;
				t.redMultiplier = Colors.extractRed(color) / 255;

				bitmapData.drawWithQuality(charLoc.link, mat, t, null, null, false, StageQuality.BEST);
			}
			else
			{
				GRAD_MAT.createGradientBox(charLoc.width, charLoc.height, Math.PI/2, 0, 0);

				charLoc.link.cacheAsBitmap = true;

				_gradBoxGraphics.clear();
				_gradBoxGraphics.beginGradientFill(GradientType.LINEAR, [color[0], color[2]], ALPHAS, RATIOS, GRAD_MAT);
				_gradBoxGraphics.drawRect(0, 0, charLoc.width*2, charLoc.height*2);
				_gradBoxGraphics.endFill();
				_gradBox.mask = charLoc.link;

				bitmapData.drawWithQuality(_gradBox, mat, null, null, null, false, StageQuality.BEST);

				charLoc.link.cacheAsBitmap = false;
				_gradBox.mask = null;
			}
		}


		protected static var mSizeIndexes			:Vector.<int>;
		protected static var mScales				:Vector.<Number>;
		protected static var mLineHeights			:Vector.<Number>;

		/** return the biggest line height **/
		[Inline]
		protected final function _getBiggestLineHeightDevice( sizes:Array ):Number
		{
			// la valeur max à retourner
			var max			:Number = 0;

			if( sizes && sizes.length > 0 )
			{
				var len:int = sizes.length;
				for( var i:int = 0; i<len; ++i )
				{
					if( sizes[i] > max )    max = sizes[i];
				}
			}

			return max;
		}

		/** les tailles réduites **/
		protected var _reducedSizes	:Array;
		/** reduce the size of all items in the array **/
		[Inline]
		protected final function _reduceSizes( sizes:Array, minFontSize:int, text:String ):Boolean
		{
			CONFIG::DEBUG{ trace('HTMLDeviceFont::reduceSize', text, sizes); }
			// récupérer la taille du tableau de tailles
			var len			:int = sizes.length;
			var limite		:int = 0;
			var target		:int;
			_reducedSizes 	= [];
			for( var i:int = 0; i<len; ++i )
			{
				target = sizes[i]-1;
				if( target < minFontSize )
				{
					target = minFontSize;
					++limite;
				}
				_reducedSizes[i] = target;
			}
			if( limite >= len )
			{
				_reducedSizes = null;
				return false;
			}
			return true;
		}
	}
}