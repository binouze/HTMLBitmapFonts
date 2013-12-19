package starling.extensions.HTMLBitmapFonts
{
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Quad;
	import starling.display.QuadBatch;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.utils.HAlign;
	import starling.utils.VAlign;
	
	/** 
	 * Un TextField capable d'afficher du texte formaté html simplifié avec des HTMLBitmapFonts uniquement
	 */
	public class HTMLTextField extends DisplayObjectContainer
	{
		/** le dico des polices disponibles (contien des HTMLBitmapFont) **/
		public static var htmlBitmapFonts		:Dictionary;
		
		/** evenement lorsque le texte se met a jour **/
		public static const UPDATE				:String				= 'textUpdated';
		
		/** true lorsque quelque chose change et qu'un redraw est nécéssaire **/
		private var mRequiresRedraw				:Boolean;
		
		//-- variables pour le texte standard --//
		
		/** la taille par défaut du texte **/
		private var mSize			:Number;
		/** la couleur par défaut du texte **/
		private var mColor			:uint;
		/** le style par défaut du texte **/
		private var mStyle			:uint;
		/** le texte sans le formatage html **/
		private var mText			:String;
		/** le nom de la police **/
		private var mFontName		:String;
		/** la regle d'alignement horizontale **/
		private var mHAlign			:String;
		/** la regle d'alignement verticale **/
		private var mVAlign			:String;
		/** la propriété bold par défaut **/
		private var mBold			:Boolean;
		/** la propriété bold par défaut **/
		private var mItalic			:Boolean;
		/** si true le texte sera réduit (selon tailles disponibles) pour rentrer dans la zone **/
		private var mAutoScale		:Boolean;
		/** indique si on doit utiliser le kerning **/
		private var mKerning		:Boolean;
		
		//-- variables utiles pour le texte html --//
		
		/** true si le texte est actuellement du texte formaté html **/
		private var mIsHTML			:Boolean;
		/** le texte html avec les balises et tout et tout **/
		private var mTextHTML		:String;
		/** la liste des tailles par caracteres **/
		private var mSizes			:Array;
		/** la liste des styles par caractere **/
		private var mStyles			:Array;
		/** la liste des couleurs par caractere **/
		private var mColors			:Array;
		
		/** la zone du texte **/
		private var mTextBounds		:Rectangle;
		/** la zone clicable **/
		private var mHitArea		:DisplayObject;
		
		/** le QuadBatch à afficher dans le textField **/
		private var mQuadBatch		:QuadBatch;
		/** un quadBatch a exporter pour choisir une autre methode de rendu de texte **/
		private var mExportedQuad	:QuadBatch;
		
		/** Create a new text field with the given properties. */
		public function HTMLTextField( width:int, height:int, text:*, fontName:String="verdana", fontSize:int = 12, color:uint = 0xFFFFFF, bold:Boolean = false, italic:Boolean = false, isHtml:Boolean = false )
		{
			// creer le dico des bitmapFont si il n'est pas déja créé
			if( !htmlBitmapFonts ) 	htmlBitmapFonts = new Dictionary();
			
			// définir la police du textField
			this.fontName = fontName.toLowerCase();
			
			// définir les valeurs par défaut pour le textField
			mSize 		= fontSize;
			mColor 		= color;
			mHAlign 	= HAlign.CENTER;
			mVAlign 	= VAlign.CENTER;
			mKerning 	= true;
			mBold 		= bold;
			mItalic		= italic;
			mIsHTML		= false;
			
			// définir le style de base pour le textfield
			mStyle = BitmapFontStyle.REGULAR;
			if( mBold && mItalic ) 		mStyle = BitmapFontStyle.BOLD_ITALIC;	
			else if( mBold )			mStyle = BitmapFontStyle.BOLD;
			else if( mItalic )			mStyle = BitmapFontStyle.ITALIC;
			
			mAutoScale = true;
			
			mHitArea 	= new Quad(width, height);
			mHitArea.alpha = 0.0;
			addChild(mHitArea);
			
			if( !isHtml )	this.text 		= text ? text : "";
			else			this.htmlText 	= text ? text : "";
			
			addEventListener( Event.FLATTEN, onFlatten );
		}
		
		/** Disposer les données de textures. */
		public override function dispose():void
		{
			removeEventListener(Event.FLATTEN, onFlatten);
			
			// disposer le QuadBatch du texte
			if( mQuadBatch )		mQuadBatch.dispose();
			// disposer le QuadBatch exporté
			if( mExportedQuad )		mExportedQuad.dispose();
			
			super.dispose();
		}
		
		/** lancer un redraw lors du flatten si nécéssaire **/
		private function onFlatten():void
		{
			if( mRequiresRedraw ) 	redrawContents();
		}
		
		/** @inheritDoc */
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			if (mRequiresRedraw) redrawContents();
			super.render(support, parentAlpha);
		}
		
		/** lancer un redraw **/
		private function redrawContents():void
		{
			// créer ou reset le quad batch
			if( mQuadBatch == null ) 
			{ 
				mQuadBatch = new QuadBatch(); 
				mQuadBatch.touchable = false;
				addChild( mQuadBatch ); 
			}
			else
				mQuadBatch.reset();
			
			// Récupérer le HTMLBitmapFont
			var bitmapFont:HTMLBitmapFonts = htmlBitmapFonts[mFontName];
			if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);
			
			// si html text on applique les tableaux de taille style et couleurs
			var sizes	:Array = mSizes && mSizes.length > 0 	? mSizes 	: [mSize];
			var styles	:Array = mStyles && mStyles.length > 0 	? mStyles 	: [mStyle];
			var colors	:Array = mColors && mColors.length > 0 	? mColors 	: [mColor];
			
			// sinon on met les valeurs de base
			if( !mIsHTML )
			{
				sizes 	= [mSize];
				styles 	= [mStyle];
				colors 	= [mColor];
			}
			
			// on fait draw le texte en fonction des parametres
			bitmapFont.fillQuadBatch( mQuadBatch, mHitArea.width, mHitArea.height, mText, sizes, styles, colors, mHAlign, mVAlign, mAutoScale, mKerning );
			
			// sera recréé à la demande
			mTextBounds 		= null; 	
			// on vien de refaire un redraw c'est plus à faire
			mRequiresRedraw 	= false;	
		}
		
		/** Returns the bounds of the text within the text field. */
		public function get textBounds():Rectangle
		{
			if( mRequiresRedraw ) 		redrawContents();
			if( mTextBounds == null ) 	mTextBounds = mQuadBatch.getBounds( mQuadBatch );
			return mTextBounds.clone();
		}
		
		/** @inheritDoc */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			return mHitArea.getBounds(targetSpace, resultRect);
		}
		
		/** @inheritDoc */
		public override function set width(value:Number):void
		{
			mHitArea.width 	= value;
			mRequiresRedraw = true;
		}
		public override function get width():Number
		{
			return mHitArea.width;
		}
		
		/** @inheritDoc */
		public override function set height(value:Number):void
		{
			mHitArea.height = value;
			mRequiresRedraw = true;
		}
		public override function get height():Number
		{
			return mHitArea.height;
		}
		
		/** 
		 * Le texte à afficher utiliser htmlText pour fournir du texte formaté HTML simplifié 
		 **/
		public function get text():String 				{ return mText; }
		public function set text(value:String):void
		{
			mIsHTML 		= false;
			mText 			= value;
			mRequiresRedraw = true;
		}
		
		/** 
		 * Le texte à afficher en html pour fournir du texte formaté HTML simplifié.<br/>
		 * Balises acceptées:
		 * <ul>
		 * 	<li>&lt;b&gt;&lt;/b&gt; -> bold</li>
		 * 	<li>&lt;i&gt;&lt;/i&gt; -> italic</li>
		 * 	<li>&lt;size="10"&gt;&lt;/size&gt; or &lt;s="10"&gt;&lt;/s&gt; -> font size (10 pour cet exemple)</li>
		 * 	<li>&lt;color="0xFF0000"&gt;&lt;/color&gt; or &lt;c="0xFF0000"&gt;&lt;/c&gt; -> couleur unie (rouge pour cet exemple) <b>ne pas oublier le 0x ou # !</b></li>
		 * 	<li>&lt;color="0xFF0000,0xFFFFFF"&gt;&lt;/color&gt; or &lt;c="0xFF00000xFFFFFF"&gt;&lt;/c&gt; -> couleur dégradé haut/bas (rouge / balnc pour cet exemple) <b>ne pas oublier les 0x ou # !</b></li>
		 * 	<li>&lt;color="0xFF0000,0xFFFFFF,0x000000,0x0000FF"&gt;&lt;/color&gt; or &lt;c="0xFF0000,0xFFFFFF,0x000000,0x0000FF"&gt;&lt;/c&gt; -> couleur dégradé custom 
		 * (haut gauche = rouge / haut droite = blanc / bas gauche = noir / bas droite = bleu pour cet exemple) <b>ne pas oublier les 0x ou # !</b></li>
		 * </ul>
		 **/
		public function get htmlText():String 			{ return mTextHTML; }
		public function set htmlText(value:String):void
		{
			mIsHTML 		= true;
			mTextHTML 		= value;
			_parseTextHTML();
			mRequiresRedraw = true;
		}
		
		/** 
		 * Parser le formatage HTML afin de retrouver les balises 
		 **/
		private function _parseTextHTML():void
		{
			mText = '';
			
			// reset arrays
			mSizes 	= [];
			mStyles = [];
			mColors = [];
			
			var sizeActu	:int 	= mSize;
			var colorActu	:* 		= mColor; // solid or gradient
			var styleActu	:int 	= mStyle;
			
			var prevSizes	:Array = [mSize];
			var prevColors	:Array = [mColor];
			var prevStyles	:Array = [mStyle];
			
			var isBold		:Boolean = mBold;
			var isItalic	:Boolean = mItalic;
			
			var colorStr	:String;
			var sizeStr		:String;
			
			var char		:String;
			
			var len:int = mTextHTML.length;
			for( var i:int = 0; i<len; ++i )
			{
				char = mTextHTML.charAt(i);
				// si ouverture de balise on doit faire des truc
				if( char == '<' )
				{
					switch( mTextHTML.charAt( i+1 ).toLowerCase() )
					{
						case 'b':
							isBold = true;
							break;
						case 'i':
							isItalic = true;
							break;
						case 'c':
							colorStr = mTextHTML.slice( mTextHTML.indexOf('"', i)+1, mTextHTML.indexOf('"', mTextHTML.indexOf('"', i)+1) );
							
							// gerer le dégradé de couleurs
							var colors:Array = colorStr.split(',');
							if( colors.length>1 )
							{
								// dégradé top / bottom 2 couleurs
								if( colors.length == 2 )
								{
									if( colors[0].charAt(0) == '#' )	colorActu = [uint( "0x" + colors[0].substr(1) ), uint( "0x" + colors[0].substr(1) ), uint( "0x" + colors[1].substr(1) ), uint( "0x" + colors[1].substr(1) )];
									else								colorActu = [uint( colors[0] ), uint( colors[0] ), uint( colors[1] ), uint( colors[1] )];
								}
								// dégradé custom (par lettres)
								else if( colors.length == 4 )
								{
									if( colors[0].charAt(0) == '#' )	colorActu = [uint( "0x" + colors[0].substr(1) ), uint( "0x" + colors[1].substr(1) ), uint( "0x" + colors[2].substr(1) ), uint( "0x" + colors[3].substr(1) )];
									else								colorActu = [uint( colors[0] ), uint( colors[1] ), uint( colors[2] ), uint( colors[3] )];
								}
								// dégradé invalide -> solid
								else
								{
									colorStr = colors[0];
									if( colorStr.charAt(0) == '#' )	colorActu = uint( "0x" + colorStr.substr(1) );
									else							colorActu = uint( colorStr );
								}
							}
							// couleur unie
							else
							{
								if( colorStr.charAt(0) == '#' )	colorActu = uint( "0x" + colorStr.substr(1) );
								else							colorActu = uint( colorStr );
							}
							prevColors.push( colorActu );
							break;
						case 's':
							sizeStr = mTextHTML.slice( mTextHTML.indexOf('"', i)+1, mTextHTML.indexOf('"', mTextHTML.indexOf('"', i)+1) );
							
							sizeActu = int( sizeStr );
							
							prevSizes.push( sizeActu );
							break;
						case '/':
							switch( mTextHTML.charAt( i+2 ).toLowerCase() )
							{
								case 'b':
									isBold = false;
									break;
								case 'i':
									isItalic = false;
									break;
								case 'c':
									if( prevColors.length > 1 )	prevColors.pop();
									colorActu = prevColors[prevColors.length-1];
									break;
								case 's':
									if( prevSizes.length > 1 )	prevSizes.pop();
									sizeActu = prevSizes[prevSizes.length-1];
									break;
							}
							break;
					}
					
					// placer le chariot a la fin de la balise
					i = mTextHTML.indexOf( '>', i );
					
					// mise à jour du style
					styleActu = BitmapFontStyle.REGULAR;
					if( isBold && isItalic ) 	styleActu = BitmapFontStyle.BOLD_ITALIC;	
					else if( isBold )			styleActu = BitmapFontStyle.BOLD;
					else if( isItalic )			styleActu = BitmapFontStyle.ITALIC;
				}
				else
				{
					// sinon on ajoute tel quel le caractere
					mText += char;
					// on ajoute la couleur actuelle
					mColors.push( colorActu );
					// on ajoute la taille actuelle
					mSizes.push( sizeActu );
					// on ajoute le style actuel
					mStyles.push( styleActu );
				}
			}
		}
		
		/** 
		 * Le nom de la police à utiliser (une seule police par TextField)
		 **/
		public function get fontName():String { return mFontName; }
		public function set fontName(value:String):void
		{
			if( !htmlBitmapFonts[value] )	throw new Error('font innexistante::', value)
			if( mFontName != value )
			{
				mFontName 		= value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * La taille de base de la police (sera traité char par char en html)
		 **/
		public function get fontSize():Number { return mSize; }
		public function set fontSize(value:Number):void
		{
			if( mSize != value )
			{
				mSize = value;
				mRequiresRedraw = true;
			}
		}
		
		/**
		 * La couleur de base de la police (sera traité char par char en html)
		 **/
		public function get color():uint { return mColor; }
		public function set color(value:uint):void
		{
			if( mColor != value )
			{
				mColor = value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * L'alignement horizontal du texte. @default center @see starling.utils.HAlign 
		 **/
		public function get hAlign():String { return mHAlign; }
		public function set hAlign(value:String):void
		{
			if( !HAlign.isValid(value) )	throw new ArgumentError("Invalid horizontal align: " + value);
			
			if( mHAlign != value )
			{
				mHAlign = value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * L'alignement vertical du texte. @default center @see starling.utils.VAlign 
		 **/
		public function get vAlign():String { return mVAlign; }
		public function set vAlign(value:String):void
		{
			if( !VAlign.isValid(value) )	throw new ArgumentError("Invalid vertical align: " + value);
			
			if( mVAlign != value )
			{
				mVAlign = value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * La propriété bold par défaut (sera traité char par char en html)
		 * @default false 
		 **/
		public function get bold():Boolean { return mBold; }
		public function set bold(value:Boolean):void 
		{
			if( mBold != value )
			{
				mBold = value;
				
				mStyle = BitmapFontStyle.REGULAR;
				if( mBold && mItalic ) 		mStyle = BitmapFontStyle.BOLD_ITALIC;	
				else if( mBold )			mStyle = BitmapFontStyle.BOLD;
				else if( mItalic )			mStyle = BitmapFontStyle.ITALIC;
				
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * La propriété italique par défaut (sera traité char par char en html)
		 * @default false 
		 **/
		public function get italic():Boolean { return mItalic; }
		public function set italic(value:Boolean):void
		{
			if( mItalic != value )
			{
				mItalic = value;
				
				mStyle = BitmapFontStyle.REGULAR;
				if( mBold && mItalic ) 		mStyle = BitmapFontStyle.BOLD_ITALIC;	
				else if( mBold )			mStyle = BitmapFontStyle.BOLD;
				else if( mItalic )			mStyle = BitmapFontStyle.ITALIC;
				
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * Indique si on doit utiliser les données de kerning. @default true 
		 **/
		public function get kerning():Boolean { return mKerning; }
		public function set kerning(value:Boolean):void
		{
			if (mKerning != value)
			{
				mKerning = value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * Indique si on tente de rétrécir la taille du texte (dans les tailles disponibles) pour qu'il rentre dans la zone
		 * @default false
		 */
		public function get autoScale():Boolean { return mAutoScale; }
		public function set autoScale(value:Boolean):void
		{
			if (mAutoScale != value)
			{
				mAutoScale = value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * forcer un redraw 
		 */
		public function forceRedraw():void
		{
			redrawContents();
		}
		
		/** recuperer le quad batch du champ texte **/
		public function get quadBatch():QuadBatch
		{
			if( !mExportedQuad )	mExportedQuad = new QuadBatch();
			else					mExportedQuad.reset();
			
			var bitmapFont:HTMLBitmapFonts = htmlBitmapFonts[mFontName.toLowerCase()];
			if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);
			
			mExportedQuad.x 		= this.x;
			mExportedQuad.y 		= this.y;
			mExportedQuad.scaleX 	= this.scaleX;
			mExportedQuad.scaleY 	= this.scaleY;
			mExportedQuad.pivotX 	= this.pivotX;
			mExportedQuad.pivotY 	= this.pivotY;
			
			// si html text on applique les tableaux de taille style et couleurs
			var sizes	:Array = mSizes && mSizes.length > 0 	? mSizes 	: [mSize];
			var styles	:Array = mStyles && mStyles.length > 0 	? mStyles 	: [mStyle];
			var colors	:Array = mColors && mColors.length > 0 	? mColors 	: [mColor];
			
			// sinon on met les valeurs de base
			if( !mIsHTML )
			{
				sizes 	= [mSize];
				styles 	= [mStyle];
				colors 	= [mColor];
			}
			
			bitmapFont.fillQuadBatch( mExportedQuad, mHitArea.width, mHitArea.height, mText, sizes, styles, colors, mHAlign, mVAlign, mAutoScale, mKerning );
			
			return mExportedQuad;
		}
		
		/** 
		 * Appliquer le TextField à un Quadbatch, le quad batch sera rempli avec les memes données que le textField
		 * @param quadBatch le QuadBatch à remplir
		 * @param applySize si true on appliquera les tailles du textField au quadBatch
		 * @param applyPos si true on appliquera les positions du textField au quadBatch
		 * @param applyScale si true on appliquara les scales du textField au quadBatch
		 * @param applyPivot si true, on appliquera les pivots du textField au quadBatch
		 **/
		public function fillQuadBatch( quadBatch:QuadBatch, applySize:Boolean = false, applyPos:Boolean = false, applyScale:Boolean = false, applyPivot:Boolean = false ):void
		{
			var bitmapFont:HTMLBitmapFonts = htmlBitmapFonts[mFontName.toLowerCase()];
			if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);
			
			var ww:Number;
			var hh:Number;
			
			// appliquer la taille du textField ou récupérer celle du quadBatch
			if( applySize )
			{
				ww = mHitArea.width;
				hh = mHitArea.height;
			}
			else
			{
				ww = quadBatch.width;
				hh = quadBatch.height;
			}
			
			// appliquer la position du textfield
			if( applyPos )
			{
				quadBatch.x 		= this.x;
				quadBatch.y 		= this.y;
			}
			
			// appliquer le scale du textfield
			if( applyScale )
			{
				quadBatch.scaleX 	= this.scaleX;
				quadBatch.scaleY 	= this.scaleY;
			}
			
			// appliquer le pivot du textfield
			if( applyPivot )
			{
				quadBatch.pivotX 	= this.pivotX;
				quadBatch.pivotY 	= this.pivotY;
			}
			
			// si html text on applique les tableaux de taille style et couleurs
			var sizes	:Array = mSizes && mSizes.length > 0 	? mSizes 	: [mSize];
			var styles	:Array = mStyles && mStyles.length > 0 	? mStyles 	: [mStyle];
			var colors	:Array = mColors && mColors.length > 0 	? mColors 	: [mColor];
			
			// sinon on met les valeurs de base
			if( !mIsHTML )
			{
				sizes 	= [mSize];
				styles 	= [mStyle];
				colors 	= [mColor];
			}
			
			// générer le texte
			bitmapFont.fillQuadBatch( quadBatch, ww, hh, mText, sizes, styles, colors, mHAlign, mVAlign, mAutoScale, mKerning );
		}
		
		/** 
		 * Enregistrer un HTMLBitmapFont qui pourra être utilisé dans n'importe quel HTMLTextField
		 **/
		public static function registerBitmapFont( texture:Texture, xml:XML, size:Number, bold:Boolean = false, italic:Boolean = false, name:String = null ):String
		{
			// si on a pas de tableau de fonts on le crée
			if( !htmlBitmapFonts )	htmlBitmapFonts = new Dictionary();
			// si le nom est null, on prend le nom dans le xml de la font
			if( name == null ) 		name = xml.info.@face.toString();
			// si ya pas encore d'entrée pour cette font on créé le HTMLBitmapFont
			if( !htmlBitmapFonts[name] )	htmlBitmapFonts[name] = new HTMLBitmapFonts( name );
			// on ajoute les infos de la font
			HTMLBitmapFonts(htmlBitmapFonts[name]).add( texture, xml, size, bold, italic );
			
			return name;
		}
		
		/** Désenregistrer un BitmapFont et le disposer */
		public static function unregisterBitmapFont(name:String, dispose:Boolean=true):void
		{
			// pas de tableau de bitmap font ca veut dire que aucune font n'est enregistrée -> on dégage
			if( !htmlBitmapFonts )									return;
			// si on doit disposer et que la font existe on appele la fonction dispose dessus
			if( dispose && htmlBitmapFonts[name] != undefined )		htmlBitmapFonts[name].dispose();
			// on delete l'index du dico
			delete htmlBitmapFonts[name];
		}
		
		/** Retourne le HTMLBitmapFont portant le nom <code>name</code> ou null s'il n'existe pas. */
		public static function getBitmapFont(name:String):HTMLBitmapFonts
		{
			return htmlBitmapFonts[name];
		}
	}
}