package starling.extensions.HTMLBitmapFonts
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.QuadBatch;
	import starling.events.Event;
	import starling.textures.Texture;
	import starling.utils.HAlign;
	import starling.utils.RectangleUtil;
	import starling.utils.VAlign;
	
	/** 
	 * A TextField to show simplified HTML text
	 */
	public class HTMLTextField extends DisplayObjectContainer
	{
		/** align rule that align the text to the left but keep the hole text centered in the container **/
		public static const LEFT_CENTERED		:String = 'left_centered';
		/** align rule that align the text to the right but keep the hole text centered in the container **/
		public static const RIGHT_CENTERED		:String = 'right_centered';
		
		/** available fonts **/
		public static var htmlBitmapFonts		:Dictionary;
		
		/** Helper objects. */
		protected static var sHelperMatrix		:Matrix 			= new Matrix();
		
		/** true when a redraw is needed **/
		protected var _mRequiresRedraw	:Boolean;
		
		//-- variables pour le texte standard --//
		
		/** the size of the text **/
		protected var mSize				:Number;
		/** the color of the text **/
		protected var mColor			:*;
		/** the style of the text **/
		protected var mStyle			:uint;
		/** the text (without html formatting) **/
		protected var mText				:String;
		/** the font name **/
		protected var mFontName			:String;
		/** the halign rule **/
		protected var mHAlign			:String;
		/** the vAlign rule **/
		protected var mVAlign			:String;
		/** bold **/
		protected var mBold				:Boolean;
		/** italic **/
		protected var mItalic			:Boolean;
		/** if true the text will be resized to fit in the width / height area (use only font size added the the BitmapFontStyle) **/
		protected var mAutoScale		:Boolean;
		/** use kerning **/
		protected var mKerning			:Boolean;
		
		//-- variables utiles pour le texte html --//
		
		/** true if text is HTML text **/
		protected var mIsHTML			:Boolean;
		/** the html text **/
		protected var mTextHTML			:String;
		/** the sizes list **/
		protected var mSizes			:Array = [];
		/** the styles list **/
		protected var mStyles			:Array = [];
		/** the color list **/
		protected var mColors			:Array = [];
		/** the line spacing **/
		protected var mLineSpacing		:int = 0;
		
		/** text bounds **/
		protected var mTextBounds		:Rectangle;
		/** hit area **/
		protected var mHitArea			:Rectangle;
		
		/** the quadBatch **/
		protected var mQuadBatch		:QuadBatch;
		/** an other quadBatch **/
		protected var mExportedQuad		:QuadBatch;
		
		/** if true, the size will be enlarged to contain the text **/
		public var resizeField			:Boolean = false;
		/** the base width of the textField (before resizing) **/
		protected var _baseWidth		:int;
		/** the base height of the textField (before resizing) **/
		protected var _baseHeight		:int;
		
		/** auto line break if line not fit in the width **/
		public var autoCR				:Boolean = true;
		
		/** Create a new text field with the given properties. */
		public function HTMLTextField( width:int, height:int, text:* = '', fontName:String='verdana', fontSize:int = 16, color:uint = 0xFFFFFF, bold:Boolean = false, italic:Boolean = false, isHtml:Boolean = true, resizeField:Boolean = false )
		{
			// creer le dico des bitmapFont si il n'est pas déja créé
			if( !htmlBitmapFonts ) 	htmlBitmapFonts = new Dictionary();
			
			// définir la police du textField
			this.fontName 	= fontName.toLowerCase();
			
			// définir les valeurs par défaut pour le textField
			mSize 			= fontSize;
			mColor 			= color;
			mHAlign 		= HAlign.CENTER;
			mVAlign 		= VAlign.CENTER;
			mKerning 		= true;
			mBold 			= bold;
			mItalic			= italic;
			mIsHTML			= isHtml;
			this.resizeField = resizeField;
			_baseWidth		= width>0?width:1;
			_baseHeight		= height>0?height:1;
			
			// définir le style de base pour le textfield
			mStyle = BitmapFontStyle.REGULAR;
			if( mBold && mItalic ) 		mStyle = BitmapFontStyle.BOLD_ITALIC;	
			else if( mBold )			mStyle = BitmapFontStyle.BOLD;
			else if( mItalic )			mStyle = BitmapFontStyle.ITALIC;
			
			mAutoScale 		= true;
			
			mHitArea 		= new Rectangle( 0, 0, width>0?width:1, height>0?height:1 );
			
			if( !isHtml )	this.text 		= text ? text : "";
			else			this.htmlText 	= text ? text : "";
			
			touchable = false;
			
			addEventListener( Event.FLATTEN, onFlatten );
		}
		
		/**
		 * @private
		 */
		protected function set mRequiresRedraw(value:Boolean):void
		{
			_mRequiresRedraw 		= value;
			if( value )				requiresRedrawQuadBatch = value;
			if( mExportedQuad )		updateExportedQuad();
		}
		
		/** dispose textures data. */
		public override function dispose():void
		{
			removeEventListener(Event.FLATTEN, onFlatten);
			
			//mTextHTML = mText = '';
			
			// disposer le QuadBatch du texte
			if( mQuadBatch )		mQuadBatch.dispose();
			// disposer le QuadBatch exporté
			if( mExportedQuad )		mExportedQuad.dispose();
			
			super.dispose();
		}
		
		/** redraw contents if needed **/
		protected function onFlatten():void
		{
			if( _mRequiresRedraw ) 	redrawContents();
		}
		
		/** @inheritDoc */
		public override function render(support:RenderSupport, parentAlpha:Number):void
		{
			if( _mRequiresRedraw ) 	redrawContents();
			super.render(support, parentAlpha);
		}
		
		/** redraw the content of the text field **/
		protected function redrawContents():void
		{
			// sera recréé à la demande
			mTextBounds 		= null; 	
			// on vien de refaire un redraw c'est plus à faire
			mRequiresRedraw 	= false;	
			
			// créer ou reset le quad batch
			if( mQuadBatch == null ) 
			{ 
				mQuadBatch = new QuadBatch(); 
				mQuadBatch.touchable = false;
				mQuadBatch.batchable = true;
				addChild( mQuadBatch ); 
			}
			else
				mQuadBatch.reset();
			
			// Récupérer le HTMLBitmapFont
			var bitmapFont:HTMLBitmapFonts = htmlBitmapFonts[mFontName];
			if (bitmapFont == null) 
			{
				return;
				//throw new Error("Bitmap font not registered: " + mFontName);
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
			
			// on fait draw le texte en fonction des parametres
			bitmapFont.lineSpacing = mLineSpacing;
			bitmapFont.fillQuadBatch( mQuadBatch, mHitArea.width, mHitArea.height, mText, sizes, styles, colors, mHAlign, mVAlign, mAutoScale, mKerning, resizeField, null, autoCR );
			
			if( resizeField )
			{
				mHitArea.width 	= _baseWidth >= mQuadBatch.width ? _baseWidth : mQuadBatch.width;
				mHitArea.height = _baseHeight >= mQuadBatch.height ? _baseHeight : mQuadBatch.height;
			}
			
			if( requiresRedrawQuadBatch && mExportedQuad )		this.updateExportedQuad();
		}
		
		/** get the bounds of the text. */
		public function get textBounds():Rectangle
		{
			if( _mRequiresRedraw ) 		redrawContents();
			if( mTextBounds == null ) 	mTextBounds = mQuadBatch.getBounds( mQuadBatch );
			return mTextBounds.clone();
		}
		
		/** @inheritDoc */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			getTransformationMatrix(targetSpace, sHelperMatrix);
			return RectangleUtil.getBounds(mHitArea, sHelperMatrix, resultRect);
		}
		
		/** @inheritDoc */
		public override function hitTest( localPoint:Point, forTouch:Boolean=false ):DisplayObject
		{
			if (forTouch && (!visible || !touchable)) 		return null;
			else if (mHitArea.containsPoint(localPoint)) 	return this;
			else return null;
		}
		
		/** @inheritDoc */
		public override function set width(value:Number):void
		{
			mHitArea.width 	= value;
			mRequiresRedraw = true;
			forceRedraw();
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
			forceRedraw();
		}
		public override function get height():Number
		{
			return mHitArea.height;
		}
		
		/** get the text width **/
		public function get textWidth():Number
		{
			if( _mRequiresRedraw ) 		redrawContents();
			return mQuadBatch ? mQuadBatch.width : 0;
		}
		/** get the text height **/
		public function get textHeight():Number
		{
			if( _mRequiresRedraw ) 		redrawContents();
			return  mQuadBatch ? mQuadBatch.height : 0;
		}
		
		/** 
		 * the text, use htmlText to use simplified HTML
		 **/
		public function get text():String { return mText; }
		public function set text(value:String):void
		{
			if( mText == value )	return;
			
			mIsHTML 		= false;
			mText 			= value;
			mTextHTML 		= mText;
			mRequiresRedraw = true;
		}
		
		/** 
		 * the simplified HTML text to show
		 **/
		public function get htmlText():String { return mTextHTML; }
		public function set htmlText(value:String):void
		{
			if( mTextHTML == value )	return;
			
			mIsHTML 		= true;
			mTextHTML 		= value;
			
			_parseTextHTML();
			mRequiresRedraw = true;
		}
		
		/** 
		 * Parse simplified HTML
		 **/
		protected function _parseTextHTML():void
		{
			mText = '';
			
			// sauts de lignes
			mTextHTML = mTextHTML.split( '<br>' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<BR>' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<br/>' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<BR/>' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<br />' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<BR />' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( String.fromCharCode(149) ).join( String.fromCharCode(8226) );
			
			// reset arrays
			mSizes.length = 0;
			mStyles.length = 0;
			mColors.length = 0;
			
			var sizeActu	:int 	= mSize;
			var colorActu	:* 		= mColor; // color or gradient
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
									// dégradé custom
								else if( colors.length == 4 )
								{
									if( colors[0].charAt(0) == '#' )	colorActu = [uint( "0x" + colors[0].substr(1) ), uint( "0x" + colors[1].substr(1) ), uint( "0x" + colors[2].substr(1) ), uint( "0x" + colors[3].substr(1) )];
									else								colorActu = [uint( colors[0] ), uint( colors[1] ), uint( colors[2] ), uint( colors[3] )];
								}
									// dégradé invalide -> couleur unie
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
					if( char.charCodeAt(0) != 10 && char.charCodeAt(0) != 13 )
					{
						// on ajoute la couleur actuelle
						mColors.push( colorActu );
					}
					// on ajoute la taille actuelle
					mSizes.push( sizeActu );
					// on ajoute le style actuel
					mStyles.push( styleActu );
				}
			}
		}
		
		/** 
		 * The font to use (only one by TexField)
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
		 * The base size of the text
		 **/
		public function get fontSize():Number { return mSize; }
		public function set fontSize(value:Number):void
		{
			if( mSize != value )
			{
				mSize = value;
				mSizes = [mSize];
				mRequiresRedraw = true;
			}
		}
		
		/**
		 * The base color of the text
		 **/
		public function get color():* { return mColor; }
		public function set color(value:*):void
		{
			if( mColor != value )
			{
				if( value is int )
				{
					mColor = value;
					
				}
				else if( value is Array )
				{
					if( value.length > 1 )
					{
						
						// dégradé top / bottom 2 couleurs
						if( value.length == 2 )
						{
							if( value[0] is String && value[0].charAt(0) == '#' )	mColor = [uint( "0x" + value[0].substr(1) ), uint( "0x" + value[0].substr(1) ), uint( "0x" + value[1].substr(1) ), uint( "0x" + value[1].substr(1) )];
							else													mColor = [uint( value[0] ), uint( value[0] ), uint( value[1] ), uint( value[1] )];
						}
							// dégradé custom
						else if( value.length == 4 )
						{
							if( value[0] is String && value[0].charAt(0) == '#' )	mColor = [uint( "0x" + value[0].substr(1) ), uint( "0x" + value[1].substr(1) ), uint( "0x" + value[2].substr(1) ), uint( "0x" + value[3].substr(1) )];
							else													mColor = [uint( value[0] ), uint( value[1] ), uint( value[2] ), uint( value[3] )];
						}
							// dégradé invalide -> couleur unie
						else
						{
							if( value[0] is String && value[0].charAt(0) == '#' )	mColor = uint( "0x" + value[0].substr(1) );
							else													mColor = uint( value[0] );
						}
					}
						// couleur unie
					else
					{
						if( value[0] is String && value[0].charAt(0) == '#' )		mColor = uint( "0x" + value[0].substr(1) );
						else														mColor = uint( value[0] );
					}
				}
				else
				{
					throw new Error('color must be uint or Array');
				}
				
				mColors = [mColor];
				
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * HAlign rule. @default center @see starling.utils.HAlign 
		 **/
		public function get hAlign():String { return mHAlign; }
		public function set hAlign(value:String):void
		{
			if( mHAlign != value )
			{
				mHAlign = value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * VAlign rule. @default center @see starling.utils.VAlign 
		 **/
		public function get vAlign():String { return mVAlign; }
		public function set vAlign(value:String):void
		{
			if( mVAlign != value )
			{
				mVAlign = value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * Bold
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
				
				mStyles = [mStyle];
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * Italic
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
				
				mStyles = [mStyle];
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * use Kerning. 
		 * @default true 
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
		 * Autoscale the content to fit the container (use only available sizes)
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
		
		/** changer l'espacement entre les lignes **/
		public function get lineSpacing():int { return mLineSpacing; }
		public function set lineSpacing( value:int ):void
		{
			mLineSpacing = value;
			mRequiresRedraw = true;
		}
		
		
		/** 
		 * force redraw 
		 */
		public function forceRedraw():void
		{
			redrawContents();
		}
		
		/** 
		 * Register a HTMLBitmapFont
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
		
		/** Unregister a BitmapFont and dispose it */
		public static function unregisterBitmapFont(name:String, dispose:Boolean=true):void
		{
			// pas de tableau de bitmap font ca veut dire que aucune font n'est enregistrée -> on dégage
			if( !htmlBitmapFonts )									return;
			// si on doit disposer et que la font existe on appele la fonction dispose dessus
			if( dispose && htmlBitmapFonts[name] != undefined )		htmlBitmapFonts[name].dispose();
			// on delete l'index du dico
			delete htmlBitmapFonts[name];
		}
		
		/** return the HTMLBitmapFont with the given name <code>name</code> or null. */
		public static function getBitmapFont(name:String):HTMLBitmapFonts
		{
			return htmlBitmapFonts[name];
		}
		
		protected var requiresRedrawQuadBatch:Boolean = false;
		
		/** recuperer le quad batch du champ texte si la font est un BitmapFont **/
		public function get quadBatch():QuadBatch
		{
			if( !mExportedQuad )			
			{
				mExportedQuad = new QuadBatch();
				mExportedQuad.touchable = false;
				mExportedQuad.batchable = true;
			}
			if( requiresRedrawQuadBatch )	updateExportedQuad();
			return mExportedQuad;
		}
		
		protected function updateExportedQuad():void
		{
			requiresRedrawQuadBatch = false;
			
			var bitmapFont:HTMLBitmapFonts = htmlBitmapFonts[mFontName.toLowerCase()];
			if (bitmapFont == null) throw new Error("Bitmap font not registered: " + mFontName);
			
			mExportedQuad.x 		= this.x;
			mExportedQuad.y 		= this.y;
			mExportedQuad.scaleX 	= this.scaleX;
			mExportedQuad.scaleY 	= this.scaleY;
			mExportedQuad.pivotX 	= this.pivotX;
			mExportedQuad.pivotY 	= this.pivotY;
			
			mExportedQuad.reset();
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
			bitmapFont.lineSpacing = mLineSpacing;
			bitmapFont.fillQuadBatch( mExportedQuad, mHitArea.width, mHitArea.height, mText, sizes, styles, colors, mHAlign, mVAlign, mAutoScale, mKerning, resizeField, null, autoCR );
			
			if( mExportedQuad.hasEventListener('update') )	mExportedQuad.dispatchEventWith( 'update' );
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
			bitmapFont.lineSpacing = mLineSpacing;
			bitmapFont.fillQuadBatch( quadBatch, ww, hh, mText, sizes, styles, colors, mHAlign, mVAlign, mAutoScale, mKerning, resizeField, null, autoCR );
		}
		
		public function getAvailableSizes( style:int ):Vector.<Number>
		{
			return HTMLBitmapFonts(htmlBitmapFonts[mFontName]).getAvailableSizesForStyle( style );
		}
		
		override public function set x(value:Number):void
		{
			super.x = int(value);
			//mRequiresRedraw = true;
			requiresRedrawQuadBatch = true;
			if( mExportedQuad )	updateExportedQuad();
		}
		override public function set y(value:Number):void
		{
			super.y = int(value);
			//mRequiresRedraw = true;
			requiresRedrawQuadBatch = true;
			if( mExportedQuad )	updateExportedQuad();
		}
		
		public function get xx():Number{ return super.x };
		public function set xx(value:Number):void
		{
			super.x = value;
		}
		public function get yy():Number{ return super.y };
		public function set yy(value:Number):void
		{
			super.y = value;
		}
	}
}

