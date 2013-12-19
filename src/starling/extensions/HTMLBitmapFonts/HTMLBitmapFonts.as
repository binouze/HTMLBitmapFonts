package starling.extensions.HTMLBitmapFonts
{
	import starling.display.Image;
	import starling.display.QuadBatch;
	import starling.display.Sprite;
	import starling.text.BitmapChar;
	import starling.textures.Texture;
	import starling.utils.HAlign;
	import starling.utils.VAlign;
	
	/** 
	 * Cette classe est utilisée par les HTMLTextField et permet de dessiner des textes avec des tailles, styles et couleurs differents dans un meme QuadBacth ou Sprite.
	 * <br/><br/>
	 * Les XML utilisées pour les methodes <code>add</code> et <code>addMultipleSizes</code>
	 * peuvent être générés par <a href="http://kvazars.com/littera/">Littera</a> ou 
	 * <a href="http://www.angelcode.com/products/bmfont/">AngelCode - Bitmap Font Generator</a>
	 * <br/><br/>
	 * Voila à quoi ressemble le fichier:
	 *
	 * <listing>
&lt;font&gt;
	&lt;info face="BranchingMouse" size="40" /&gt;
	&lt;common lineHeight="40" /&gt;
	&lt;pages&gt; &lt;!-- currently, only one page is supported --&gt;
		&lt;page id="0" file="texture.png" /&gt;
	&lt;/pages&gt;
	&lt;chars&gt;
		&lt;char id="32" x="60" y="29" width="1" height="1" xoffset="0" yoffset="27" xadvance="8" /&gt;
		&lt;char id="33" x="155" y="144" width="9" height="21" xoffset="0" yoffset="6" xadvance="9" /&gt;
	&lt;/chars&gt;
	&lt;kernings&gt; &lt;!-- Kerning is optional --&gt;
		&lt;kerning first="83" second="83" amount="-4"/&gt;
	&lt;/kernings&gt;
&lt;/font&gt;
	 * </listing>
	 * 
	 * Personnelement j'utilise l'AssetManager pour charger mes fonts et je l'ai modifié comme suit: <br/>
	 * dans loadQueue -> processXML :</br>
	 * <listing>
	 * 
else if( rootNode == "font" )
{
	name 	= xml.info.&#64;face.toString();
	fileName 	= getName(xml.pages.page.&#64;file.toString());
	isBold 	= xml.info.&#64;bold == 1;
	isItalic 	= xml.info.&#64;italic == 1;
	
	log("Adding html bitmap font '" + name + "'" + " _bold: " + isBold + " _italic: " + isItalic );
	
	fontTexture = getTexture( fileName );
	HTMLTextField.registerBitmapFont( fontTexture, xml, xml.info.&#64;size, isBold, isItalic, name.toLowerCase() );
	removeTexture( fileName, false );
	
	mLoadedHTMLFonts.push( name.toLowerCase() );
}
	 * </listing>
	 */ 
	public class HTMLBitmapFonts
	{
		/** le caractère espace **/
		private static const CHAR_SPACE				:int = 32;
		/** le caractère tab **/
		private static const CHAR_TAB				:int =  9;
		/** le caractère nouvelle ligne **/
		private static const CHAR_NEWLINE			:int = 10;
		/** le caractère retour chariot **/
		private static const CHAR_CARRIAGE_RETURN	:int = 13;
		
		/** le style de base pour cette police, le premier style ajouté **/
		private var _baseStyle						:int = -1;
		/** la taille de base pour cette police, la premiere taille ajoutée **/
		private var _baseSize						:int = -1;
		/** le globalScale pour les font afin qu'elles soient lisibles quel que soit le scale appliqué à Starling **/
		private static var _globalScale				:Number = 1;
		/** le scale actuel dépendent de si on a trouvé une taille de police proche de celle recherchée ou pas **/
		private var _currentScale					:Number = 1;
		
		/** les styles de font **/
		private var mFontStyles						:Vector.<BitmapFontStyle>;
		/** le nom de la police **/
		private var mName							:String;
		/** une image temporaire **/
		private var mHelperImage					:Image;
		/** une pool de CharLocation **/
		private static var mCharLocationPool		:Vector.<CharLocation>;
		
		/** 
		 * Créer un HTMLBitmapFont pour une famille de font
		 * @param name le nom à enregistrer pour la font.
		 **/
		public function HTMLBitmapFonts( name:String )
		{
			// créer la pool en statique si elle n'existe pas encore
			if( !mCharLocationPool )	mCharLocationPool = new <CharLocation>[];
			
			// définir le nom de la font
			mName 				= name;
			// créer le tableau contenant les style de fonts
			mFontStyles 		= new Vector.<BitmapFontStyle>( BitmapFontStyle.NUM_STYLES, true );
		}
		
		/** Définir un scale global qui sera appliqué à tous les textes et qui sera utilisé pour trouver une taille de texte équivalente sans scaler le texte **/
		public static function set globalScale( value:Number ):void
		{
			_globalScale = value;
		}
		
		/** définir la taille de base pour cette font **/
		public function set baseSize( value:Number ):void
		{
			_baseSize = value;
		}
		
		/** 
		 * définir le style de base pour cette font (le style doit être valide et exister sinon ne sera pas pris en compte) 
		 * @see com.lagoon.display.texte.BitmapFontStyle
		 * @see com.lagoon.display.texte.BitmapFontStyle#REGULAR
		 * @see com.lagoon.display.texte.BitmapFontStyle#BOLD
		 * @see com.lagoon.display.texte.BitmapFontStyle#ITALIC
		 * @see com.lagoon.display.texte.BitmapFontStyle#BOLD_ITALIC
		 **/
		public function set baseStyle( value:int ):void
		{
			if( value < BitmapFontStyle.NUM_STYLES && mFontStyles[value] != null )	_baseStyle = value;
		}
		
		/** 
		 * Ajouter plusieurs tailles de font pour un style
		 * @param textures un vecteur de Texture, une texture par taille de font
		 * @param fontsXML un vecteur de XML, un xml par taille de font
		 * @param sizes un vecteur de Number, définir les tailles des fonts, une taille par taille de font
		 * @param bold indiquer si cette font est bold
		 * @param italic indiquer si la police est italique
		 **/
		public function addMultipleSizes( textures:Vector.<Texture>, fontsXml:Vector.<XML>, sizes:Vector.<Number>, bold:Boolean = false, italic:Boolean = false ):void
		{
			// récuperer l'index du style actuel
			var index:int = BitmapFontStyle.REGULAR;
			if( bold && italic ) 	index = BitmapFontStyle.BOLD_ITALIC;	
			else if( bold )			index = BitmapFontStyle.BOLD;
			else if( italic )		index = BitmapFontStyle.ITALIC;
			
			// créer le BitmapFontStyle pour le style si il n'existe pas encore
			if( !mFontStyles[index] )	mFontStyles[index] = new BitmapFontStyle( index, textures, fontsXml, sizes );
			// ajouter les tailles de font au BitmapFontStyle
			else						mFontStyles[index].addMultipleSizes( textures, fontsXml, sizes );
			
			// si le helperImage n'existe pas encore on le crée
			if( !mHelperImage )			mHelperImage 	= new Image( textures[0] );
			// si eucune taille de base n'est définie on prend la premiere du tableau
			if( _baseSize == -1 )		_baseSize 		= sizes[0];
			// si le style de base n'est pas encore défini, on prend le style actuel
			if( _baseStyle == -1 )		_baseStyle 		= index;
		}
		
		/** 
		 * Ajouter une taille de font pour un style
		 * @param texture la texture pour la taille de font à ajouter
		 * @param xlm le xml à parser pour la taille de font à ajouter
		 * @param size la taille de la font à ajouter
		 * @param bold indiquer si la font à ajouter est bold
		 * @param italic indiquer si la font à ajouter est italique
		 **/
		public function add( texture:Texture, xml:XML, size:Number, bold:Boolean = false, italic:Boolean = false ):void
		{
			// récuperer l'index du style actuel
			var index:int = BitmapFontStyle.REGULAR;
			if( bold && italic ) 	index = BitmapFontStyle.BOLD_ITALIC;	
			else if( bold )			index = BitmapFontStyle.BOLD;
			else if( italic )		index = BitmapFontStyle.ITALIC;
			
			// créer le BitmapFontStyle pour le style si il n'existe pas encore
			if( !mFontStyles[index] )	mFontStyles[index] = new BitmapFontStyle( index, new <Texture>[texture], new <XML>[xml], new <Number>[size] );
			// ajouter la taille de font au BitmapFontStyle
			else						mFontStyles[index].add( texture, xml, size );
			
			// si le helperImage n'existe pas encore on le crée
			if( !mHelperImage )			mHelperImage 	= new Image( texture );
			// si eucune taille de base n'est définie on prend la taille actuelle
			if( _baseSize == -1 )		_baseSize 		= size;
			// si le style de base n'est pas encore défini, on prend le style actuel
			if( _baseStyle == -1 )		_baseStyle 		= index;
		}
		
		/** Dispose les BitmapFontStyle associés */
		public function dispose():void
		{
			for( var i:int = 0; i<BitmapFontStyle.NUM_STYLES; ++i )	
			{
				if( mFontStyles[i] ) mFontStyles[i].dispose();
			}
			mFontStyles.fixed 	= false;
			mFontStyles.length 	= 0;
			mFontStyles 		= null;
		}
		
		/** 
		 * Créer un Sprite contenant une image par caractère 
		 * @param width la largeur du conteneur du texte
		 * @param height la hauteur du conteneur du texte
		 * @param text le String du texte
		 * @param fontSizes (default null->taille de base) le tableau des tailles par caractère (si plus court que le texte, la derniere valeur sera utilisée pour la suite)
		 * @param styles (default null->style de base) le tableau des styles par caractère (si plus court que le texte, la derniere valeur sera utilisée pour la suite)
		 * @param colors (default null->0xFFFFFF) le tableau des couleurs par caractère, pour ne pas teinter -> 0xFFFFFF (si plus court que le texte, la derniere valeur sera utilisée pour la suite) 
		 * @param hAlign (default center) la règle d'alignement horizontal
		 * @param vAlign (default center) la règle d'alignement vertical
		 * @param autoScale (default true) si true le texte vera sa taille réduite (selon disponibilité des tailles de police) pour rentrer dans le conteneur
		 * @param kerning (default true) indique si le kerning doit être utilisé 
		 **/
		public function createSprite(width:Number, height:Number, text:String,
									 fontSizes:Array = null, styles:Array = null, colors:Array = null, 
									 hAlign:String="center", vAlign:String="center",      
									 autoScale:Boolean=true, 
									 kerning:Boolean=true):Sprite
		{
			// générer le tableau de CharLocation
			var charLocations	:Vector.<CharLocation> 	= arrangeChars( width, height, text, fontSizes, styles, hAlign, vAlign, autoScale, kerning );
			// récupérer le nombre de caractères à traiter
			var numChars		:int 					= charLocations.length;
			// créer le Sprite
			var sprite			:Sprite 				= new Sprite();
			
			// si le tableau de couleur est vide ou null, on met du 0xFFFFFF par défaut (0xFFFFFF -> no modif)
			if( !colors || colors.length == 0 )	colors = [0xFFFFFF];
			// la couleur pour le caractère actuel
			var colorActu:uint = 0xFFFFFF;
			
			// parcourir les caractères pour les placer sur le Sprite
			for( var i:int=0; i<numChars; ++i )
			{
				// récupérer la couleur du caractere
				if( i < colors.length )		colorActu = colors[i];
				
				// récupérer le CharLocation du caractère actuel
				var charLocation:CharLocation = charLocations[i];
				// générer l'image du caractère actuel
				var char:Image = charLocation.char.createImage();
				// positionner le caractère
				char.x = charLocation.x;
				char.y = charLocation.y;
				// scaler le caractère
				char.scaleX = char.scaleY = charLocation.scale;
				// colorer le caractère
				char.color = colorActu;
				// ajouter le caractère au Sprite
				sprite.addChild(char);
			}
			
			// retourner le Sprite
			return sprite;
		}
		
		/** 
		 * Remplir un QuadBatch avec le texte, le QuadBatch ne sera pas reset ici
		 * @param quadBatch le QuadBatch à remplir 
		 * @param width la largeur du conteneur du texte
		 * @param height la hauteur du conteneur du texte
		 * @param text le String du texte
		 * @param fontSizes (default null->taille de base) le tableau des tailles par caractère (si plus court que le texte, la derniere valeur sera utilisée pour la suite)
		 * @param styles (default null->style de base) le tableau des styles par caractère (si plus court que le texte, la derniere valeur sera utilisée pour la suite)
		 * @param colors (default null->0xFFFFFF) le tableau des couleurs par caractère, pour ne pas teinter -> 0xFFFFFF (si plus court que le texte, la derniere valeur sera utilisée pour la suite) 
		 * @param hAlign (default center) la règle d'alignement horizontal
		 * @param vAlign (default center) la règle d'alignement vertical
		 * @param autoScale (default true) si true le texte vera sa taille réduite (selon disponibilité des tailles de police) pour rentrer dans le conteneur
		 * @param kerning (default true) indique si le kerning doit être utilisé 
		 **/
		public function fillQuadBatch(quadBatch:QuadBatch, width:Number, height:Number, text:String,
									  fontSizes:Array = null, styles:Array = null, colors:Array = null, 
									  hAlign:String="center", vAlign:String="center",      
									  autoScale:Boolean=true, 
									  kerning:Boolean=true ):void
		{
			// générer le tableau de CharLocation
			var charLocations	:Vector.<CharLocation> 	= arrangeChars( width, height, text, fontSizes, styles, hAlign, vAlign, autoScale, kerning );
			// récupérer le nombre de caractères à traiter
			var numChars		:int 					= charLocations.length;
			
			// forcer le tint = true pour pouvoir avoir plusieurs couleur de texte
			mHelperImage.alpha = 0.9999;
			
			// si le tableau de couleur est vide ou null, on met du 0xFFFFFF par défaut (0xFFFFFF -> no modif)
			if( !colors || colors.length == 0 )	colors = [0xFFFFFF];
			// la couleur pour le caractère actuel
			//var colorActu:uint = 0xFFFFFF;
			
			// limitation du nombre d'images par QuadBatch 
			if( numChars > 8192 )	throw new ArgumentError("Bitmap Font text is limited to 8192 characters.");
			
			// parcourir les caractères pour les placer sur le QuadBatch
			for( var i:int=0; i<numChars; ++i )
			{
				// récupérer la couleur du caractère et colorer l'image
				if( i < colors.length )		
				{
					if( colors[i] is Array )
					{
						mHelperImage.setVertexColor(0, colors[i][0]);
						mHelperImage.setVertexColor(1, colors[i][1]);
						mHelperImage.setVertexColor(2, colors[i][2]);
						mHelperImage.setVertexColor(3, colors[i][3]);
					}
					else
					{
						mHelperImage.color = colors[i];
					}
				}
				
				// récupérer le CharLocation du caractère actuel
				var charLocation:CharLocation = charLocations[i];
				// appliquer la texture du caractere à l'image
				mHelperImage.texture = charLocation.char.texture;
				// réajuster al taille de l'image pour la nouvelle texture
				mHelperImage.readjustSize();
				// placer l'image
				mHelperImage.x = charLocation.x;
				mHelperImage.y = charLocation.y;
				// scaler l'image
				mHelperImage.scaleX = mHelperImage.scaleY = charLocation.scale;
				// ajouter l'image au QuadBatch
				quadBatch.addImage( mHelperImage );
			}
		}
		
		/** Arranges the characters of a text inside a rectangle, adhering to the given settings. 
		 *  Returns a Vector of CharLocations. */
		private function arrangeChars( width:Number, height:Number, text:String, fontSizes:Array = null, styles:Array = null, hAlign:String="center", vAlign:String="center", autoScale:Boolean=true, kerning:Boolean=true ):Vector.<CharLocation>
		{
			// si pas de texte on renvoi un tableau vide
			if( text == null || text.length == 0 ) 		return new <CharLocation>[];
			// aucun style définit, on force le style de base
			if( !styles || styles.length == 0 ) 		styles 		= [_baseStyle];
			// aucune taille définie, on force la taille de base
			if( !fontSizes || fontSizes.length == 0 )	fontSizes 	= [_baseSize];
			// trouver des tailles adaptées en fonction du scale global de l'application
			fontSizes = _getSizeForActualScale( fontSizes, styles );
			// tableaux des lignes
			var lines				:Vector.<Vector.<CharLocation>> = new <Vector.<CharLocation>>[];
			// passe a true une fois qu'on a fini de rendre le texte
			var finished			:Boolean = false;
			// une charLocation pour remplir le vecteur de lignes
			var charLocation		:CharLocation;
			// le nombre de caracteres à traiter
			var numChars			:int;
			// la hauteur de ligne pour le plus gros caractère
			var biggestLineHeight	:Number;
			// la taille de font du caractere actuel
			var sizeActu			:int;
			// la style de font du caractere actuel
			var styleActu			:int;
			// la largeur du conteneur
			var containerWidth		:Number = width / _currentScale;
			// la hauteur du conteneur
			var containerHeight		:Number = height / _currentScale;
			
			while( !finished )
			{
				// init/reset le tableau de lignes
				lines.length = 0;
				// récuperer la hauteur du plus haut caractere savoir si il rentre dans la zone ou pas
				biggestLineHeight 	= _getBiggestLineHeight( fontSizes, styles );
				// si le plus gros caractere rentre en hauteur dans la zone spécifiée
				if( biggestLineHeight <= containerHeight )
				{
					var lastWhiteSpace	:int 		= -1;
					var lastCharID		:int 		= -1;
					var currentX		:Number 	= 0;
					var currentY		:Number 	= 0;
					var currentLine		:Vector.<CharLocation> = new <CharLocation>[];
					
					numChars = text.length;
					for( var i:int=0; i<numChars; ++i )
					{
						// récupérer la taille actuelle
						if( i < fontSizes.length )		sizeActu 	= fontSizes[i];
						// récupérer le syle actuel
						if( i < styles.length )			styleActu 	= styles[i];
						// style erroné on prend le stle de base
						if( styleActu > BitmapFontStyle.NUM_STYLES || !mFontStyles[styleActu] )	styleActu = _baseStyle;
						
						// c'est une nouvelle ligne donc la ligne n'est surrement pas finie
						var lineFull	:Boolean 	= false;
						// récupérer le CharCode du caractère actuel
						var charID		:int 		= text.charCodeAt(i);
						// récupérer le BitmapChar du caractère actuel
						var char		:BitmapChar = mFontStyles[styleActu].getCharForSize( charID, sizeActu );
						// le caractère n'est pas disponible, on remplace par un espace
						if( char == null )
						{
							charID = CHAR_SPACE;
							char = mFontStyles[styleActu].getCharForSize( charID, sizeActu );
						}
						
						// retour à la ligne
						if( charID == CHAR_NEWLINE || charID == CHAR_CARRIAGE_RETURN )	lineFull = true;
						else
						{
							// on enregistre le placement du dernier espace
							if( charID == CHAR_SPACE || charID == CHAR_TAB )	lastWhiteSpace = i;
							// application du kerning si activé
							if( kerning ) 										currentX += char.getKerning(lastCharID);
							
							// créer un CharLocation ou le récupérer dans la pool
							charLocation = mCharLocationPool.length > 0 ? mCharLocationPool.pop() : new CharLocation(char);
							
							// définir le BitmapChar du CharLocation
							charLocation.char = char;
							// définir la position du caractère en x
							charLocation.x = currentX + char.xOffset;
							// définir la position du caractère en y, on y rajoute (la hauteur de ligne du plus grand caractere)-(la hauteur de ligne du caractere actuel)
							charLocation.y = currentY + char.yOffset + ( biggestLineHeight - mFontStyles[styleActu].getLineHeightForSize(sizeActu) );
							// on ajoute le caractàre au tableau
							currentLine.push( charLocation );
							
							// on met a jour la position x du prochain caractère
							currentX += char.xAdvance;
							// on enregistre le CharCode du caractère
							lastCharID = charID;
							
							// fin de ligne car dépassement de la largeur du conteneur
							if( charLocation.x + char.width > containerWidth )
							{
								// si on a eu un espace on va couper apres le dernier espace sinon on coupe à lindex actuel
								var numCharsToRemove	:int = lastWhiteSpace == -1 ? 1 : i - lastWhiteSpace;
								var removeIndex			:int = currentLine.length - numCharsToRemove;
								
								// couper la ligne
								currentLine.splice( removeIndex, numCharsToRemove );
								
								// il faut baisser la taille de la font -> on arrete la
								if( currentLine.length == 0 )	break;
								
								i -= numCharsToRemove;
								lineFull = true;
							}
						}
						
						// fin du texte
						if( i == numChars - 1 )
						{
							lines.push( currentLine );
							finished = true;
						}
						// fin de ligne
						else if( lineFull )
						{
							lines.push( currentLine );
							
							// le dernier caractere de la ligne est un espace
							//if( lastWhiteSpace == i )	currentLine.pop();
							
							// on a la place de mettre une nouvelle ligne
							if( currentY + 2*biggestLineHeight <= containerHeight )
							{
								// créer un tableau pour la nouvelle ligne
								currentLine = new <CharLocation>[];
								// remettre le x à 0
								currentX = 0;
								// mettre le y à la prochaine ligne
								currentY += biggestLineHeight;
								// reset lastWhiteSpace index
								lastWhiteSpace = -1;
								// reset lastCharID vu que le kerning ne va pas s'appliquer entre 2 lignes
								lastCharID = -1;
							}
							else
							{
								// il faut baisser la taille de la font -> on arrete la
								break;
							}
						}
					} // for each char
				} // if (mLineHeight <= containerHeight)
				
				// si l'autoscale est activé et que le texte ne rentre pas dans la zone spécifié, on réduit la taille de la police
				if( autoScale && !finished && _reduceSizes(fontSizes, styles) )
				{
					// on reset les lignes
					lines.length = 0;
				}
				else
				{
					// on peut rien y faire on y arrivera pas c'est fini
					finished = true; 
				}
				
			} // while (!finished)
			
			// le tableau de positionnement final des caractères
 			var finalLocations	:Vector.<CharLocation> 	= new <CharLocation>[];
			// le nombre de lignes
			var numLines		:int 					= lines.length;
			// le y max du texte
			var bottom			:Number 				= currentY + biggestLineHeight;
			// l'offset y
			var yOffset			:int 					= 0;
			
			// calculer l'offset y en fonction de la rêgle d'alignement vertical 
			if( vAlign == VAlign.BOTTOM )      	yOffset =  containerHeight - bottom;
			else if( vAlign == VAlign.CENTER ) 	yOffset = (containerHeight - bottom) / 2;
			
			// parcourir les lignes
			for( var lineID:int=0; lineID<numLines; ++lineID )
			{
				// récupérer la ligne actuelle
				var line	:Vector.<CharLocation> 	= lines[lineID];
				// récupérer le nombre de caractères sur la ligne
				numChars 							= line.length;
				
				// si ligne vide -> on passe à la suivante
				if( numChars == 0 ) continue;
				
				// l'offset x
				var xOffset			:int 			= 0;
				// la position du dernier caractère de la ligne
				var lastLocation	:CharLocation 	= line[line.length-1];
				// le x max de la ligne
				var right			:Number 		= lastLocation.x - lastLocation.char.xOffset + lastLocation.char.xAdvance;
				
				// calculer l'offset x en fonction de la règle d'alignement horizontal
				if( hAlign == HAlign.RIGHT )       	xOffset =  containerWidth - right;
				else if( hAlign == HAlign.CENTER ) 	xOffset = (containerWidth - right) / 2;
				
				// parcourir les caractères
				for( var c:int=0; c<numChars; ++c )
				{
					// récupérer le CharLocation
					charLocation 		= line[c];
					// appliquer l'offset x et le _globalScale à la positon x du caractère
					charLocation.x 		= _currentScale * (charLocation.x + xOffset);
					// appliquer l'offset y et le _globalScale à la positon y du caractère
					charLocation.y 		= _currentScale * (charLocation.y + yOffset);
					// appliquer le globalScale au scale du caractère
					charLocation.scale 	= _currentScale;
					
					/*if (charLocation.char.width > 0 && charLocation.char.height > 0)*/	// ca on le vire sinon le tableau de couleur se décale a chaque espace / tab
					finalLocations.push(charLocation);
					
					// return to pool for next call to "arrangeChars"
					mCharLocationPool.push(charLocation);
				}
			}
			
			return finalLocations;
		}
		
		/** retourne un tableau avec les nouvelle taille a appliquer en fonction du scale général de l'application **/
		private function _getSizeForActualScale( sizes:Array, styles:Array ):Array
		{
			// le scale actuel de starling
			var scale		:Number = 1/_globalScale;//CommonAssets.globalScale;
			// la valeur max à retourner
			var newSizes	:Array = [];
			// la taille de ligne pour le caractere actuel
			var lineActu	:Number;
			// la taille de font du caractere actuel
			var sizeActu	:int;
			// la style de font du caractere actuel
			var styleActu	:int;
			
			// récupérer la taille du plus grand des tableaux
			var len			:int = sizes.length;
			
			for( var i:int = 0; i<len; ++i )
			{
				// récupérer la taille actuelle
				sizeActu = sizes[i];
				// récupérer le syle actuel
				if( i < styles.length )			styleActu = styles[i];
				// style erroné on prend le stle de base
				if( styleActu > BitmapFontStyle.NUM_STYLES || !mFontStyles[styleActu] )	styleActu = _baseStyle;
				// récupérer la hauteur de ligne pour ce style et cette taille
				lineActu = mFontStyles[styleActu].getLineHeightForSize(sizeActu) * scale;
				// trouver une taille de font correspondante
				newSizes[i] = mFontStyles[styleActu].getSizeForLineHeight(lineActu);
				
				if( mFontStyles[styleActu].getLineHeightForSize(newSizes[i]) > lineActu )
				{
					_currentScale = 1;
					return sizes;
				}
			}
			
			// mettre à jour le scale global
			_currentScale = 1/scale;
			
			// retourner les nouvelles tailles et le nouveau scale
			return newSizes;
		}
		
		/** retourne la plus grande hauteur de ligne **/
		private function _getBiggestLineHeight( sizes:Array, styles:Array ):Number
		{
			// la valeur max à retourner
			var max			:Number = 0; 
			// la taille de ligne pour le caractere actuel
			var lineActu	:Number;
			// la taille de font du caractere actuel
			var sizeActu	:int;
			// la style de font du caractere actuel
			var styleActu	:int;
			
			// récupérer la taille du plus grand des tableaux
			var len			:int = sizes.length;
			if( styles.length > len )	len = styles.length;
			
			for( var i:int = 0; i<len; ++i )
			{
				// récupérer la taille actuelle
				if( i < sizes.length )			sizeActu 	= sizes[i];
				// récupérer le syle actuel
				if( i < styles.length )			styleActu 	= styles[i];
				
				// style erroné on prend le stle de base
				if( styleActu > BitmapFontStyle.NUM_STYLES || !mFontStyles[styleActu] )	styleActu = _baseStyle;
				
				// récupérer la hauteur de ligne pour ce style et cette taille
				lineActu = mFontStyles[styleActu].getLineHeightForSize(sizeActu);
				// si la valeur est plus grande on met à jour max
				if( lineActu > max )	max = lineActu;
			}
			
			// retourner la valeur max
			return max;
		}
		
		/** réduire la taille de tous les éléments du tableau **/
		private function _reduceSizes( sizes:Array, styles:Array ):Boolean
		{
			// la taille d'origine avant d'essayer de reduire
			var orig		:Number;
			// variable pour savoir si on a pu reduire ou pas des caracteres selon la disponibilité des fonts intégrés
			var reduced		:Boolean = false;
			// la style de font du caractere actuel
			var styleActu	:int;
			// récupérer la taille du tableau de tailles
			var len			:int = sizes.length;
			
			for( var i:int = 0; i<len; ++i )
			{
				// récupérer le syle actuel
				if( i < styles.length )			styleActu = styles[i];
				// style erroné on prend le stle de base
				if( styleActu > BitmapFontStyle.NUM_STYLES || !mFontStyles[styleActu] )	styleActu = _baseStyle;
				
				// enregistrer la valeur avant reduction pour pouvoir vérifier si une taille plus petite était disponible ou pas
				orig = sizes[i];
				// recuperer une taille en dessous ou la meme
				sizes[i] = mFontStyles[styleActu].getSmallerSize( sizes[i] );
				
				// passer reduced a true si on a pu réduire la taille de la font
				if( orig > sizes[i] )	reduced = true;
			}
			
			// retourner l'état de reduction de la font
			return reduced;
		}
		
		/** The name of the font as it was parsed from the font file. */
		public function get name():String { return mName; }
		
		/** The smoothing filter that is used for the texture. */ 
		public function get smoothing():String { return mHelperImage.smoothing; }
		public function set smoothing(value:String):void { mHelperImage.smoothing = value; } 
	}
}