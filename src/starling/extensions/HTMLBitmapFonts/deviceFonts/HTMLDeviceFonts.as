package starling.extensions.HTMLBitmapFonts.deviceFonts
{
	import flash.display.BitmapData;
	import flash.display.StageQuality;
	import flash.geom.Matrix;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	import starling.core.Starling;
	import starling.display.Image;
	import starling.display.Sprite;
	import starling.extensions.HTMLBitmapFonts.BitmapFontStyle;
	import starling.extensions.HTMLBitmapFonts.HTMLBitmapFonts;
	import starling.extensions.HTMLBitmapFonts.HTMLTextField;
	import starling.textures.Texture;
	import starling.utils.HAlign;
	import starling.utils.VAlign;

	public class HTMLDeviceFonts extends HTMLBitmapFonts
	{
		/** the vector used for the lines **/
		protected static var dlines:Vector.< Vector.<DeviceFontCharLocation> >;
		
		public function set name(value:String):void{ mName = value; };
		
		public function HTMLDeviceFonts()
		{
			if( !dlines )		dlines = new <Vector.<DeviceFontCharLocation>>[];
			if( !_txt )			_txt = new TextField();
			if( !_txtFormat )	_txtFormat = new TextFormat();
			
			_txt.x = -1024;
			Starling.current.nativeStage.addChild( _txt );
			
			super('');
		}
		
		override protected function _init():void
		{
			
		}
		
		/** 
		 * Fill the QuadBatch with text, no reset will be call on the QuadBatch
		 * @param quadBatch the QuadBatch to fill
		 * @param width container width
		 * @param height container height
		 * @param text the text String
		 * @param fontSizes (default null->base size) the array containing the size by char. (if shorter than the text, the last value is used for the rest)
		 * @param styles (default null->base style) the array containing the style by char. (if shorter than the text, the last value is used for the rest)
		 * @param colors (default null->0xFFFFFF) the array containing the colors by char, no tint -> 0xFFFFFF (if shorter than the text, the last value is used for the rest) 
		 * @param hAlign (default center) horizontal align rule
		 * @param vAlign (default center) vertical align rule
		 * @param autoScale (default true) if true the text will be reduced for fiting the container size (if smaller font size are available)
		 * @param kerning (default true) true if you want to use kerning
		 * @param resizeQuad (default false) if true, the Quad can be bigger tahn width, height if the texte cannot fit. 
		 * @param keepDatas (default null) don't delete the Vector.<CharLocation> at the end if a subclass need it.
		 * @param autoCR (default true) do auto line break or not.
		 * @param maxWidth the max width if resizeQuad is true.
		 * @param hideEmote, if true the emote wont be displayed.
		 * @param minFontSize the minimum font size to reduce to. 
		 **/
		public function getSprite( width:Number, height:Number, text:String,
									  fontSizes:Array = null, styles:Array = null, colors:Array = null, underlines:Array = null,
									  hAlign:String="center", vAlign:String="center", autoScale:Boolean=true, 
									  kerning:Boolean=true, resizeQuad:Boolean = false, keepDatas:Object = null, 
									  autoCR:Boolean = true, maxWidth:int = 900, hideEmotes:Boolean = false, minFontSize:int = 10, 
									  isShadow:Boolean = false, colorizeEmotes:Boolean = false, ignoreEmotesForAlign:Boolean = false ):Sprite
		{
			var retour:Sprite = new Sprite();
			
			// découper le tableau de couleur pour ignorer les caracteres à remplacer par des emotes
			if( _emotesTxt )
			{
				var lenC:int, lenU:int;
				var txtlen:int = text.length-1;
				for( var i:int = txtlen; i>=0; --i )
				{
					var emlen:int = _emotesTxt.length;
					for( var e:int = 0; e<emlen; ++e )
					{
						lenC = lenU = _emotesTxt[e].length;
						if( text.charAt(i) == _emotesTxt[e].charAt(0) && text.substr(i,lenC) == _emotesTxt[e] )
						{
							if( lenC >= colors.length )	lenC = colors.length-1;
							colors.splice(i,lenC-1);
							
							if( lenU >= underlines.length )	lenU = underlines.length-1;
							underlines.splice(i,lenU-1);
							break;
						}
					}
				}
			}
			
			// générer le tableau de CharLocation
			var charLocations	:Vector.<DeviceFontCharLocation> 	= arrangeCharsDevice( width, height, text, fontSizes.concat(), styles.concat(), hAlign, vAlign, autoScale, kerning, resizeQuad, autoCR, maxWidth, minFontSize, ignoreEmotesForAlign );
			
			// cas foireux pour le texte qui apparait mots à mots
			if( keepDatas )			keepDatas.loc = DeviceFontCharLocation.cloneVector( charLocations );
			
			// récupérer le nombre de caractères à traiter
			var numChars		:int 					= charLocations.length;
			
			// si le tableau de couleur est vide ou null, on met du 0xFFFFFF par défaut (0xFFFFFF -> no modif)
			if( !colors || colors.length == 0 )	colors = [0xFFFFFF];
			
			// limitation du nombre d'images par QuadBatch 
			if( numChars > 8192 )	throw new ArgumentError("Bitmap Font text is limited to 8192 characters.");
			
			var img				:Image;
			
			var color			:*;
			var underline		:Boolean;
			var prevUnderline	:Boolean;
			var nextUnderLine	:Boolean;
			var margin			:int;
			var charLocation	:DeviceFontCharLocation;
			
			var wMax:int = 0;
			var hMax:int = 0;
			var minX:int = int.MAX_VALUE;
			var minY:int = int.MAX_VALUE;
			
			for( i=0; i<numChars; ++i )
			{
				if( !charLocations[i] || charLocations[i].isEmote )
				{
					continue;
				}
				
				// récupérer le CharLocation du caractère actuel
				charLocation = charLocations[i];
				
				if( charLocation.x + charLocation.width > wMax )	wMax = charLocation.x + charLocation.width;
				if( charLocation.y + charLocation.height > hMax )	hMax = charLocation.y + charLocation.height;
				if( charLocation.x < minX )							minX = charLocation.x;
				if( charLocation.y < minY )							minY = charLocation.y;
			}
			
			var ww:int = wMax-minX;
			var hh:int = hMax-minY;
			if( ww < 1 )	ww = 1;
			if( hh < 1 )	hh = 1;
			var bitmapData:BitmapData = new BitmapData( ww+5, hh+4, true, 0x0 );
			
			// parcourir les caractères pour les placer sur le QuadBatch
			for( i=0; i<numChars; ++i )
			{
				if( !charLocations[i] || hideEmotes && charLocations[i].isEmote )
				{
					continue;
				}
				
				// récupérer le CharLocation du caractère actuel
				charLocation = charLocations[i];
				
				// recup la couleur
				if( isShadow || !charLocations[i].isEmote || colorizeEmotes )
				{
					// récupérer la couleur du caractère et colorer l'image
					if( i < colors.length )
					{
						color = colors[i];
					}
					else
					{
						color = colors[colors.length-1];
					}
				}
				else
				{
					color = 0xFFFFFF;
				}
				
				// appliquer la texture du caractere à l'image
				if( !charLocation.isEmote )
				{
					addCharTexture( bitmapData, charLocation, color, minX, minY );
					continue;
					//img = new DeviceFontImage( getCharTexture(charLocation) );
				}
				else	img = new Image(charLocation.tex);
				
				// applique la couleur a l'image
				if( color is Array )
				{
					img.setVertexColor(0, color[0]);
					img.setVertexColor(1, color[1]);
					img.setVertexColor(2, color[2]);
					img.setVertexColor(3, color[3]);
				}
				else
				{
					img.color = color;
				}
				
				// placer l'image
				img.x = charLocation.x;
				img.y = charLocation.y;
				// ajouter l'image au QuadBatch
				retour.addChild( img );
				
				// creating underlines
				prevUnderline = underline;
				if( i < underlines.length )
				{
					underline = underlines[i];
					if( i+1 < underlines.length )	nextUnderLine = underlines[i+1];
					else							nextUnderLine = underline;
				}
				else	underline = nextUnderLine = underlines[underlines.length-1];
				
				if( underline )
				{
					margin = (i == 0 || i == numChars-1 || !prevUnderline || !nextUnderLine ) ? 1 : charLocation.width>>1;
					//add baseLine
					img = new Image(_underlineTexture);
					
					img.x = charLocation.x-margin;
					img.y = int(charLocation.y-charLocation.yOffset+2);
					img.width = charLocation.width+margin*2;
					retour.addChild(img);
				}
			}
			
			var tex:Texture = Texture.fromBitmapData( bitmapData, false );
			tex.root.onRestore = null;
			
			img = new DeviceFontImage(tex);
			img.x = minX;
			img.y = minY;
			retour.addChild( img );
			bitmapData.dispose();
			
			/*var q:Quad = new Quad(ww,hh);
			q.alpha = 0.5;
			q.x = minX;
			q.y = minY;
			retour.addChild(q);*/
			
			/*var qx:Quad = new Quad(2,hh, 0xFF0000);
			qx.alpha = 0.5;
			qx.x = minX;
			retour.addChild(qx);
			
			var qy:Quad = new Quad(ww,2, 0xFF0000);
			qy.alpha = 0.5;
			qy.y = minY;
			retour.addChild(qy);*/
			
			DeviceFontCharLocation.rechargePool();
			
			return retour;
		}
		
		protected static var mHelperText:TextField; 
		
		/** Arranges the characters of a text inside a rectangle, adhering to the given settings. 
		 *  Returns a Vector of CharLocations. */
		protected function arrangeCharsDevice( width:Number, height:Number, text:String, 
										 fontSizes:Array = null, styles:Array = null, 
										 hAlign:String="center", vAlign:String="center", 
										 autoScale:Boolean=true, kerning:Boolean=true, resizeQuad:Boolean = false, 
										 autoCR:Boolean = true, maxWidth:int = 900, minFontSize:int = 10, ignoreEmotesForAlign:Boolean = false ):Vector.<DeviceFontCharLocation>
		{
			// si pas de texte on renvoi un tableau vide
			if( text == null || text.length == 0 ) 		return DeviceFontCharLocation.vectorFromPool();
			
			// creer le textField a screenshoter
			if( !mHelperText )	mHelperText = new TextField();
			
			// aucun style définit, on force le style de base
			if( !styles || styles.length == 0 ) 		styles 		= [_baseStyle];
			
			// aucune taille définie, on force la taille de base
			if( !fontSizes || fontSizes.length == 0 )	fontSizes 	= [_baseSize];
			
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
			// le scale dont on va se servir
			var scaleActu			:Number = 1;
			
			
			while( !finished )
			{
				// init/reset le tableau de lignes
				dlines.length 		= 0;
				linesSizes.length 	= 0;
				//baselines.length 	= 0;
				
				// récuperer la hauteur du plus haut caractere savoir si il rentre dans la zone ou pas
				biggestLineHeight 	= Math.ceil( _getBiggestLineHeightDevice( fontSizes, styles, text ) );
				
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
					var currentMaxSize	:Number 	= 0;
					var currentMaxSizeS	:Number 	= 0;
					var realMaxSize		:Number 	= 0;
					var lineHeight		:Number;
					var baseLine		:Number;
					var currentMaxBase	:Number 	= 0;
					var currentMaxBaseS	:Number 	= 0;
					// le départ en y
					var baseY			:Number 	= 0;
					// reset reduced sizes
					_reducedSizes 		= null;
					
					numChars = text.length;
					for( i = 0; i<numChars; ++i )
					{
						// récupérer la taille actuelle
						if( i < fontSizes.length )		sizeActu 	= fontSizes[i];
						// récupérer le syle actuel
						if( i < styles.length )			styleActu 	= styles[i];
						
						// reset le isEmote
						var isEmote		:int 		= -1;
						// c'est une nouvelle ligne donc la ligne n'est surrement pas finie
						var lineFull	:Boolean 	= false;
						// récupérer le CharCode du caractère actuel
						var charID		:int 		= text.charCodeAt(i);
						
						scaleActu = 1;
						
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
							// ajouter le nombre de carateres pris par une emote 
							if( isEmote >= 0 )							
							{
								charLocation = renderEmote(isEmote);
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
								var isBold	:Boolean = styleActu == BitmapFontStyle.BOLD || styleActu == BitmapFontStyle.BOLD_ITALIC;
								var isItalic:Boolean = styleActu == BitmapFontStyle.ITALIC || styleActu == BitmapFontStyle.BOLD_ITALIC;
								var next:int = i<numChars-1 ? text.charCodeAt(i+1) : -1;
								charLocation = renderChar( charID, sizeActu, isBold, isItalic, next );
							}
							
							lineHeight 		= charLocation.lineHeight;
							baseLine 		= charLocation.baseLine;
							
							if( baseLine > currentMaxBase )					currentMaxBase 	= baseLine;
							if( baseLine*scaleActu > currentMaxBaseS )		currentMaxBaseS = baseLine*scaleActu;
							if( lineHeight > currentMaxSize )				currentMaxSize 	= lineHeight;
							if( lineHeight*scaleActu > currentMaxSizeS )	currentMaxSizeS = lineHeight*scaleActu;
							if( currentMaxSizeS > realMaxSize )				realMaxSize 	= currentMaxSizeS;
							
							// définir la position du caractère en x
							charLocation.x 			= currentX + charLocation.xOffset;
							// définir la position du caractère en y
							charLocation.y 			= currentY + charLocation.yOffset;
							
							// on ajoute le caractère au tableau
							currentLine.push( charLocation );
							
							// on met a jour la position x du prochain caractère si ce n'est pas le premier espace d'une ligne
							if( currentLine.length != 1 || charID != CHAR_SPACE )	
							{
								currentX += charLocation.xAdvance;
							}
							
							// on enregistre le CharCode du caractère
							lastCharID = charID;
							
							// fin de ligne car dépassement de la largeur du conteneur
							if( charLocation.x + charLocation.width > width )
							{
								// tenter voir si on peut mettre le texte a la ligne
								if( autoCR && (resizeQuad || currentY + 2*currentMaxSizeS + _lineSpacing <= height) )
								{
									// si autoscale est a true on ne doit pas couper le mot en 2
									if( autoScale && lastWhiteSpace < 0 )		
									{
										if( resizeQuad )	
										{
											if( width >= maxWidth )		goto ignore;
											else
											{
												width = charLocation.x + charLocation.width <= maxWidth ? charLocation.x + charLocation.width : maxWidth;
												break;
												//goto suite;
											}
										}
										else if( !_reduceSizes(fontSizes, minFontSize, text) )	
										{
											goto ignore;
										}
										break;
									}
									
									ignore:
									
									// si c'est un emote on retourne au debut de l'emote avant de couper
									if( isEmote != -1 )			i -= _emotesTxt[e].length-1;
									
									if( lastWhiteSpace >= 0 && lastWhiteSpaceL >= 0 )
									{
										// si on a eu un espace on va couper apres le dernier espace sinon on coupe à lindex actuel
										var numCharsToRemove	:int = currentLine.length - lastWhiteSpaceL+1; //i - lastWhiteSpace + 1;
										var removeIndex			:int = lastWhiteSpaceL + 1; //lastWhiteSpace+1;//currentLine.length - numCharsToRemove + 1;
										
										// couper la ligne
										var temp:Vector.<DeviceFontCharLocation> = DeviceFontCharLocation.vectorFromPool();
										var l:int = currentLine.length;
										
										for( var t:int = 0; t<l; ++t )
										{
											if( t < removeIndex || t >= removeIndex+numCharsToRemove )	temp.push( currentLine[t] );
										}
										
										// il faut baisser la taille de la font -> on arrete la
										if( temp.length == 0 )	
										{
											if( resizeQuad )	goto suite;
											_reduceSizes(fontSizes, minFontSize, text);
											break;
										}
										currentLine = temp;
										i = lastWhiteSpace;
									}
									
									lineFull = true;
									// si le prochain caractere est un saut de ligne, on l'ignore
									if( text.charCodeAt(i+1) == CHAR_CARRIAGE_RETURN || text.charCodeAt(i+1) == CHAR_NEWLINE )	
									{
										++i;
									}
								}
								else
								{
									_reduceSizes(fontSizes, minFontSize, text);
									break;
								}
							}
							
						}
						
						suite:
						
						// fin du texte
						if( i == numChars - 1 )
						{
							dlines.push( currentLine );
							linesSizes.push( currentMaxSize );
							finished = true;
						}
						// fin de ligne
						else if( lineFull )
						{
							currentLine.push(null);
							dlines.push( currentLine );
							linesSizes.push( currentMaxSizeS );
							
							// on a la place de mettre une nouvelle ligne
							if( resizeQuad || currentY + 2*currentMaxSizeS + _lineSpacing <= height )
							{
								if( currentY == 0 )		baseY = currentMaxBaseS;
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
								currentMaxSizeS = currentMaxBase = realMaxSize = 0;
								currentMaxBase = 0;
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
				
				// si l'autoscale est activé et que le texte ne rentre pas dans la zone spécifié, on réduit la taille de la police
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
						linesSizes.push( currentMaxSizeS );
					}
				}
			} // while (!finished)
			
			// le tableau de positionnement final des caractères
			var finalLocations	:Vector.<DeviceFontCharLocation> 	= DeviceFontCharLocation.vectorFromPool();
			// le nombre de lignes
			var numLines		:int 					= dlines.length;
			// le y max du texte
			var bottom			:Number 				= currentY + currentMaxSizeS;
			// l'offset y
			var yOffset			:int 					= 0;
			// la ligne à traiter
			var line			:Vector.<DeviceFontCharLocation>;
			// un j
			var j				:int;
			
			if( baseY == 0 )	baseY = currentMaxBaseS;
			
			if( vAlign == VAlign.TOP )      			yOffset 	= baseY;
			else if( vAlign == VAlign.BOTTOM )  		yOffset 	= baseY + (height-bottom);
			else if( vAlign == VAlign.CENTER ) 			yOffset 	= baseY + (height-bottom)/2;
			if( yOffset < 0 )							yOffset 	= 0;
			
			// la taille de la ligne la plus longue utile pour les LEFT_CENTERED et RIGHT_CENTERED
			var longestLineWidth:Number = 0;
			
			if( hAlign == HTMLTextField.RIGHT_CENTERED || hAlign == HTMLTextField.LEFT_CENTERED )
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
						if( !line[j] || line[j].charID == CHAR_SPACE )		continue;
						if( ignoreEmotesForAlign && lines[i][j].isEmote )	continue;
						
						if( line[j].x+line[j].width > longestLineWidth )	
							longestLineWidth = line[j].x + line[j].width;
						
						break;
					}
				}
			}
			
			var c:int, xOffset:int, right:Number, lastLocation:DeviceFontCharLocation;
			
			var xOffsetEmote:int = 0;
			if( ignoreEmotesForAlign )
			{
				for( var z:int = 0; z<numLines; ++z )
				{
					var xOffsetEmoteLine:int = 0;
					line = dlines[z];
					j = 1;
					lastLocation = null;//line[line.length-j];
					while( lastLocation == null && line.length-j >= 0)
					{
						lastLocation = line[line.length-j++];
						if( ignoreEmotesForAlign && lastLocation && lastLocation.isEmote ) 
						{
							xOffsetEmoteLine += lastLocation.width;
							lastLocation = null;
						}
					}
					
					if( xOffsetEmoteLine > xOffsetEmote )	xOffsetEmote = xOffsetEmoteLine;
				}
			}
			
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
				lastLocation = null;//line[line.length-j];
				while( lastLocation == null && line.length-j >= 0)
				{
					lastLocation = line[line.length-j++];
					if( ignoreEmotesForAlign && lastLocation && lastLocation.isEmote ) 
					{
						lastLocation = null;
					}
				}
				// le x max de la ligne
				right = lastLocation ? lastLocation.x - lastLocation.xOffset + lastLocation.xAdvance : 0;
				
				// calculer l'offset x en fonction de la règle d'alignement horizontal
				if( hAlign == HAlign.RIGHT )       					xOffset =  width - right;
				else if( hAlign == HAlign.CENTER ) 					xOffset = (width - right) / 2;
				else if( hAlign == HTMLTextField.RIGHT_CENTERED ) 	xOffset = longestLineWidth + (width - longestLineWidth) / 2 - right;
				else if( hAlign == HTMLTextField.LEFT_CENTERED ) 	xOffset = (width - longestLineWidth) / 2;
				
				xOffset -= xOffsetEmote>>1;
				
				// parcourir les caractères
				for( c=0; c<numChars; ++c )
				{
					// récupérer le CharLocation
					charLocation = line[c];
					if( charLocation )
					{
						// appliquer l'offset x et le _globalScale à la positon x du caractère
						charLocation.x = charLocation.x + xOffset;
						// appliquer l'offset y et le scale à la positon y du caractère
						charLocation.y = charLocation.y + yOffset;
						// aligner les emotes
						if( charLocation.isEmote )	
						{
							var id	:int = c;
							var prev:DeviceFontCharLocation;
							if( c > 0 )
							{
								do{ prev = line[--id]; }while( prev.isEmote || prev.charID == CHAR_SPACE && id >= 0 );
								
								if( prev.isEmote || prev.charID == CHAR_SPACE )
									charLocation.y -= (charLocation.height-linesSizes[lineID])>>1;
								else
									charLocation.y = prev.y + ((prev.height - charLocation.height)>>1)-2;
							}
							else if( numChars > 1 )
							{
								do{ prev = line[++id]; }while( prev.isEmote || prev.charID == CHAR_SPACE && id < numChars );
								
								if( prev.isEmote || prev.charID == CHAR_SPACE )
									charLocation.y -= (charLocation.height-linesSizes[lineID])>>1;
								else
									charLocation.y = prev.y + yOffset + ((prev.height - charLocation.height)>>1)-2;
							}
							else charLocation.y -= (charLocation.height-linesSizes[lineID])>>1;
						}
						
						// ajouter le caractere au tableau
						finalLocations.push(charLocation);
					}
				}
			}
			
			dlines.length 		= 0;
			linesSizes.length 	= 0;
			
			return finalLocations;
		}
		
		private static var _txt			:TextField;
		private static var _txtFormat	:TextFormat;
		private function renderChar( id:int, size:int, bold:Boolean = false, italic:Boolean = false, nextChar:int = -1 ):DeviceFontCharLocation
		{
			_txtFormat.size 		= size;
			_txtFormat.color 		= 0xFFFFFF;
			_txtFormat.bold			= bold;
			_txtFormat.italic		= italic;
			_txtFormat.kerning		= true;
			_txtFormat.font 		= mName;
			
			_txt.embedFonts			= true;
			_txt.defaultTextFormat 	= _txtFormat;
			_txt.text 				= String.fromCharCode(id);
			
			if (_txt.textWidth == 0.0 || _txt.textHeight == 0.0)
				_txt.embedFonts = false;
			
			/*var bitmapData:BitmapData = new BitmapData( _txt.textWidth+5, _txt.textHeight+4, true, 0x00000000 );
			
			var drawWithQualityFunc:Function = 
				"drawWithQuality" in bitmapData ? bitmapData["drawWithQuality"] : null;
			
			// Beginning with AIR 3.3, we can force a drawing quality. Since "LOW" produces
			// wrong output oftentimes, we force "MEDIUM" if possible.
			
			if (drawWithQualityFunc is Function)
				drawWithQualityFunc.call(bitmapData, _txt, null, 
					null, null, null, false, StageQuality.HIGH);
			else
				bitmapData.draw(_txt, null);*/
			
			var loc:DeviceFontCharLocation = DeviceFontCharLocation.instanceFromPool( null );
			
			if( nextChar != -1 )	
			{
				_txt.text += String.fromCharCode(nextChar);
				if( !_txt.getCharBoundaries(1) )	_txt.text = String.fromCharCode(id)+'a';
			}
			else					_txt.text += 'a';
			
			loc.charID 		= id;
			loc.lineHeight 	= _txt.getLineMetrics(0).height;
			loc.height 		= _txt.getCharBoundaries(0).height;
			loc.width 		= _txt.getCharBoundaries(0).width;
			loc.xAdvance	= _txt.getCharBoundaries(1).x - _txt.getCharBoundaries(0).x;
			//loc.yAdvance	= _txt.getLineMetrics(0).height;
			loc.xOffset		= -3;
			loc.yOffset		= -2;//_txt.getLineMetrics(0).ascent - _txt.getLineMetrics(0).descent - _txt.getLineMetrics(0).height;
			loc.baseLine	= _txt.getLineMetrics(0).ascent - _txt.getLineMetrics(0).height;
			loc.isBold		= bold;
			loc.isItalic	= italic;
			loc.size		= size;
			loc.name		= mName;
			
			_txt.text = "";
			
			return loc;
		}
		
		[Inline]
		public static function addCharTexture( bitmapData:BitmapData, char:DeviceFontCharLocation, color:*, offsetX:int, offsetY:int ):void
		{
			_txtFormat.size 		= char.size;
			_txtFormat.color 		= 0xFFFFFF;
			_txtFormat.bold			= char.isBold//bold;
			_txtFormat.italic		= char.isItalic;
			_txtFormat.font 		= char.name;
			if( color is int )		_txtFormat.color = color;
			
			_txt.embedFonts			= true;
			_txt.defaultTextFormat 	= _txtFormat;
			_txt.text 				= String.fromCharCode(char.charID);
			
			if (_txt.textWidth == 0.0 || _txt.textHeight == 0.0)
				_txt.embedFonts = false;
			
			//var bitmapData:BitmapData = new BitmapData( _txt.textWidth+5, _txt.textHeight+4, true, 0x0 );
			
			/*var drawWithQualityFunc:Function = 
			"drawWithQuality" in bitmapData ? bitmapData["drawWithQuality"] : null;
			
			// Beginning with AIR 3.3, we can force a drawing quality. Since "LOW" produces
			// wrong output oftentimes, we force "MEDIUM" if possible.
			
			if (drawWithQualityFunc is Function)
			drawWithQualityFunc.call(bitmapData, _txt, null, 
			null, null, null, true, StageQuality.HIGH);
			else*/
			var mat:Matrix = new Matrix();
			mat.translate( char.x-offsetX, char.y-offsetY );
			
			bitmapData.drawWithQuality(_txt, mat, null, null, null, true, StageQuality.HIGH);
			/*
			var tex:Texture = Texture.fromBitmapData(bitmapData,false);
			_txt.text = "";
			bitmapData.dispose();
			*/
			//return tex;
		}
		
		/*[Inline]
		public static function getCharTexture(char:DeviceFontCharLocation):Texture
		{
			_txtFormat.size 		= char.size;
			_txtFormat.color 		= 0xFFFFFF;
			_txtFormat.bold			= char.isBold//bold;
			_txtFormat.italic		= char.isItalic;
			_txtFormat.font 		= HTMLTextField.useDeviceFontName;
			
			_txt.embedFonts			= true;
			_txt.defaultTextFormat 	= _txtFormat;
			_txt.text 				= String.fromCharCode(char.charID);
			
			if (_txt.textWidth == 0.0 || _txt.textHeight == 0.0)
				_txt.embedFonts = false;
			
			var bitmapData:BitmapData = new BitmapData( _txt.textWidth+5, _txt.textHeight+4, true, 0x00000000 );
			
				bitmapData.drawWithQuality(_txt, null, null, null, null, true, StageQuality.HIGH);
			
			var tex:Texture = Texture.fromBitmapData(bitmapData,false);
			_txt.text = "";
			bitmapData.dispose();
			
			return tex;
		}*/
		
		private function renderEmote( id:int ):DeviceFontCharLocation
		{
			var loc:DeviceFontCharLocation = DeviceFontCharLocation.instanceFromPool( _emotesTextures[id].texture );
			
			loc.isEmote		= true;
			loc.lineHeight 	= _emotesTextures[id].height;
			loc.height 		= _emotesTextures[id].height;
			loc.width 		= _emotesTextures[id].width;
			loc.xAdvance	= _emotesTextures[id].xAdvance;
			//loc.yAdvance	= 0;//_emotesTextures[id].yAdvance;
			loc.xOffset		= _emotesTextures[id].xOffset;
			loc.yOffset		= _emotesTextures[id].yOffset;
			
			return loc;
		}
		
		/** return the biggest line height **/
		[Inline]
		protected final function _getBiggestLineHeightDevice( sizes:Array, styles:Array, text:String ):Number
		{
			// la valeur max à retourner
			var max			:Number = 0;
			// la taille de ligne pour le caractere actuel
			var lineActu	:Number;
			// la taille de font du caractere actuel
			var sizeActu	:int;
			// la style de font du caractere actuel
			var styleActu	:int;
			// le scale actuel
			var scaleActu	:Number;
			// l'index de size
			var sizeIndex	:int;
			
			mSizeIndexes.length = 0;
			mScales.length 		= 0;
			mLineHeights.length = 0;
			
			var isBold	:Boolean;
			var isItalic:Boolean;
			_txt.embedFonts	= true;
			
			for( var i:int = 0; i<text.length; ++i )
			{
				// récupérer la taille actuelle
				if( i < sizes.length )			sizeActu 	= sizes[i];
				// récupérer le syle actuel
				if( i < styles.length )			styleActu 	= styles[i];
				
				
				isBold 		= styleActu == BitmapFontStyle.BOLD || styleActu == BitmapFontStyle.BOLD_ITALIC;
				isItalic 	= styleActu == BitmapFontStyle.ITALIC || styleActu == BitmapFontStyle.BOLD_ITALIC;
				
				_txtFormat.size 		= sizeActu;
				_txtFormat.bold			= true;//isBold;
				_txtFormat.italic		= isItalic;
				_txtFormat.font 		= mName;
				
				_txt.defaultTextFormat 	= _txtFormat;
				_txt.text 				= text.charAt(i);
				
				if( _txt.textHeight <= 0 )	
					_txt.embedFonts = false;
				
				lineActu = _txt.getLineMetrics(0).height;
				
				// si la valeur est plus grande on met à jour max
				if( lineActu > max )	max = lineActu;
			}
			
			// retourner la valeur max
			return max;
		}
		
		/*private function renderText(scale:Number, resultTextBounds:Rectangle):BitmapData
		{
			var width:Number  = mHitArea.width  * scale;
			var height:Number = mHitArea.height * scale;
			var hAlign:String = mHAlign;
			var vAlign:String = mVAlign;
			
			if (isHorizontalAutoSize)
			{
				width = int.MAX_VALUE;
				hAlign = HAlign.LEFT;
			}
			if (isVerticalAutoSize)
			{
				height = int.MAX_VALUE;
				vAlign = VAlign.TOP;
			}
			
			var textFormat:TextFormat = new TextFormat(mFontName, 
				mFontSize * scale, mColor, mBold, mItalic, mUnderline, null, null, hAlign);
			textFormat.kerning = mKerning;
			
			sNativeTextField.defaultTextFormat = textFormat;
			sNativeTextField.width = width;
			sNativeTextField.height = height;
			sNativeTextField.antiAliasType = AntiAliasType.ADVANCED;
			sNativeTextField.selectable = false;            
			sNativeTextField.multiline = true;            
			sNativeTextField.wordWrap = true;         
			
			if (mIsHtmlText) sNativeTextField.htmlText = mText;
			else             sNativeTextField.text     = mText;
			
			sNativeTextField.embedFonts = true;
			sNativeTextField.filters = mNativeFilters;
			
			// we try embedded fonts first, non-embedded fonts are just a fallback
			if (sNativeTextField.textWidth == 0.0 || sNativeTextField.textHeight == 0.0)
				sNativeTextField.embedFonts = false;
			
			formatText(sNativeTextField, textFormat);
			
			if (mAutoScale)
				autoScaleNativeTextField(sNativeTextField);
			
			var textWidth:Number  = sNativeTextField.textWidth;
			var textHeight:Number = sNativeTextField.textHeight;
			
			if (isHorizontalAutoSize)
				sNativeTextField.width = width = Math.ceil(textWidth + 5);
			if (isVerticalAutoSize)
				sNativeTextField.height = height = Math.ceil(textHeight + 4);
			
			// avoid invalid texture size
			if (width  < 1) width  = 1.0;
			if (height < 1) height = 1.0;
			
			var textOffsetX:Number = 0.0;
			if (hAlign == HAlign.LEFT)        textOffsetX = 2; // flash adds a 2 pixel offset
			else if (hAlign == HAlign.CENTER) textOffsetX = (width - textWidth) / 2.0;
			else if (hAlign == HAlign.RIGHT)  textOffsetX =  width - textWidth - 2;
			
			var textOffsetY:Number = 0.0;
			if (vAlign == VAlign.TOP)         textOffsetY = 2; // flash adds a 2 pixel offset
			else if (vAlign == VAlign.CENTER) textOffsetY = (height - textHeight) / 2.0;
			else if (vAlign == VAlign.BOTTOM) textOffsetY =  height - textHeight - 2;
			
			// if 'nativeFilters' are in use, the text field might grow beyond its bounds
			var filterOffset:Point = calculateFilterOffset(sNativeTextField, hAlign, vAlign);
			
			// finally: draw text field to bitmap data
			var bitmapData:BitmapData = new BitmapData(width, height, true, 0x0);
			var drawMatrix:Matrix = new Matrix(1, 0, 0, 1,
				filterOffset.x, filterOffset.y + int(textOffsetY)-2);
			var drawWithQualityFunc:Function = 
				"drawWithQuality" in bitmapData ? bitmapData["drawWithQuality"] : null;
			
			// Beginning with AIR 3.3, we can force a drawing quality. Since "LOW" produces
			// wrong output oftentimes, we force "MEDIUM" if possible.
			
			if (drawWithQualityFunc is Function)
				drawWithQualityFunc.call(bitmapData, sNativeTextField, drawMatrix, 
					null, null, null, false, StageQuality.MEDIUM);
			else
				bitmapData.draw(sNativeTextField, drawMatrix);
			
			sNativeTextField.text = "";
			
			// update textBounds rectangle
			resultTextBounds.setTo((textOffsetX + filterOffset.x) / scale,
				(textOffsetY + filterOffset.y) / scale,
				textWidth / scale, textHeight / scale);
			
			return bitmapData;
		}*/
	}
}