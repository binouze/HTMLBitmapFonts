package starling.extensions.HTMLBitmapFonts
{
	import com.lagoon.display.images.ImagePool;

	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Dictionary;

	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.Image;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.extensions.HTMLBitmapFonts.deviceFonts.HTMLDeviceFonts;
	import starling.rendering.Painter;
	import starling.utils.Align;
	import starling.utils.RectangleUtil;

	/**
	 * A TextField to show simplified HTML text
	 */
	public class HTMLTextField extends DisplayObjectContainer
	{
		/** the default font name **/
		public static const DEFAULT_FONT_NAME	:String = 'Verdana';

		/** align rule that align the text to the left but keep the hole text centered in the container **/
		public static const LEFT_CENTERED		:String = 'left_centered';
		/** align rule that align the text to the right but keep the hole text centered in the container **/
		public static const RIGHT_CENTERED		:String = 'right_centered';
		
		/** available fonts **/
		public static var htmlBitmapFonts		:Dictionary;
		
		/** default blue color **/
		public static const DEFAULT_LINK_BLUE	:uint = 0x303DF0;
		/** define the default links color, null for no change (default null)**/
		public var defaultLinkColor				:* = DEFAULT_LINK_BLUE;
		
		/** static default method to navigate to url, you are still able to change it by field using the non static method ( function(url:String):void ) **/
		public static var navigateToURLFunction	:Function			= HTMLTextField._navigateToURL;
		/** the function to call to navigate to url ( function(url:String):void ) **/
		public var navigateToURLFunction		:Function 			= HTMLTextField.navigateToURLFunction;
		/** the urlRequest used by navigate to url function **/
		private static var _urlRequest			:URLRequest         = new URLRequest();
		/** default navigate to urlFunction **/
		private static function _navigateToURL( url:String ):void
		{
			_urlRequest.url = url;
			navigateToURL( _urlRequest );
		}
		
		/** Helper objects. */
		protected static var sHelperMatrix		:Matrix 			= new Matrix();
		
		/** true when a redraw is needed **/
		protected var _mRequiresRedraw			:Boolean;
		
		//-- variables pour le texte standard --//
		
		/** the size of the text **/
		protected var mSize						:Number;
		/** the color of the text **/
		protected var mColor					:*;
		/** the style of the text **/
		protected var mStyle					:uint;
		/** true for underlining the text **/
		protected var mUnderline				:Boolean;
		/** the text (without html formatting) **/
		protected var mText						:String;
		/** the font name **/
		protected var mFontName					:String;
		/** the halign rule **/
		protected var mHAlign					:String;
		/** the vAlign rule **/
		protected var mVAlign					:String;
		/** bold **/		
		protected var mBold						:Boolean;
		/** italic **/
		protected var mItalic					:Boolean;
		/** if true the text will be resized to fit in the width / height area (use only font size added the the BitmapFontStyle) **/
		protected var mAutoScale				:Boolean;
		/** when true, the text will automaticaly go to the next line if it not fit in the width **/
		protected var mAutoCR					:Boolean = true;
		/** the minimum font size to reduce to **/
		protected var mMinFontSize				:int = 10;
		
		//-- auto resize --//
		
		/** if true, the size will be enlarged to contain the text **/
		protected var mResizeField				:Boolean = false;
		/** the maximum width when resizeField is set to true **/
		protected var mMaxWidth					:int = 900;
		/** used when mResizeField is true to keep the base size **/
		protected var _baseWidth				:int;
		/** used when mResizeField is true to keep the base size **/
		protected var _baseHeight				:int;
		
		//-- Shadow --//
		
		/** horizontal shadow offset (0 = no shadow)**/
		protected var mShadowX					:int = 0;
		/** vertical shadow offset (0 = no shadow)**/
		protected var mShadowY					:int = 0;
		/** shadow color (default 0x222222) **/
		protected var mShadowColor				:uint = 0x0;

		//-- Contour (device only) --//

		/** la taille du contour **/
		protected var mContourSize              :uint = 0;
		/** la puissance du contour **/
		protected var mContourStrength          :uint = 1;
		/** la couleur du contour **/
		protected var mContourColor             :uint = 0x0;

		//-- variables utiles pour le texte html --//
		
		/** true if text is HTML text **/
		protected var mIsHTML					:Boolean;
		/** the html text **/
		protected var mTextHTML					:String;
		/** the sizes list **/
		protected var mSizes					:Array = [];
		/** the styles list **/
		protected var mStyles					:Array = [];
		/** the color list **/
		protected var mColors					:Array = [];
		/** the underlines list **/
		protected var mUnderlines				:Array = [];
		/** the links id list by char **/
		protected var mLinksIds					:Array = [];
		/** the links list **/
		protected var mLinks					:Array;
		/** les rectangles de touch pour les lnks **/
		protected var mLinksRect				:Vector.<LinkRect>;
		/** the line spacing **/
		protected var mLineSpacing				:int = 0;
		
		/** text bounds **/
		protected var mTextBounds				:Rectangle;
		/** hit area **/
		protected var mHitArea					:Rectangle;
		
		/** the image in case of using deviceFonts **/
		protected var mImage					:Image;
		
		/** 
		 * Create a new text field with the given properties. 
		 * width the desired max width of the text field
		 * height the desired max height of the text field
		 * text the text to fill the field with
		 * fontName the font to use
		 * fontSize the base size for the text
		 * color the base color for the text, uint for solid color or array for gradients (see color setter)
		 * bold 
		 * italic
		 * isHtml if true, the text will be parsed as simplified HTML
		 * resizeField if true the text will have his width/height ajusted to the text size even if bigger than
		 * width/height value (see maxWidth).
		 **/
		public function HTMLTextField( width:int, height:int, text:String = '', fontName:String=DEFAULT_FONT_NAME, fontSize:int = 16, color:* = 0xFFFFFF, bold:Boolean = false, italic:Boolean = false, isHtml:Boolean = true, resizeField:Boolean = false )
		{
			// creer le dico des bitmapFont si il n'est pas déja créé
			if( !htmlBitmapFonts ) 	htmlBitmapFonts = new Dictionary();
			
			// if the font name is empty take the first font name available
			if( fontName == '' ) 
			{
				// get the first fontName available
				var firstKey:String;
				for( firstKey in htmlBitmapFonts )
				{
					fontName = firstKey;
					break;
				}
			}
			// définir la police du textField
			this.fontName = fontName/*.toLowerCase()*/;
			
			// définir les valeurs par défaut pour le textField
			mSize 				= fontSize;
			mColor 				= color;
			mHAlign 			= Align.CENTER;
			mVAlign 			= Align.CENTER;
			mBold 				= bold;
			mItalic				= italic;
			mIsHTML				= isHtml;
			mResizeField 		= resizeField;
			_baseWidth			= width>0?width:1;
			_baseHeight			= height>0?height:1;
			
			// définir le style de base pour le textfield
			mStyle = BitmapFontStyle.REGULAR;
			if( mBold && mItalic ) 		mStyle = BitmapFontStyle.BOLD_ITALIC;	
			else if( mBold )			mStyle = BitmapFontStyle.BOLD;
			else if( mItalic )			mStyle = BitmapFontStyle.ITALIC;
			
			mAutoScale 		= true;
			
			mHitArea 		= new Rectangle( 0, 0, width>0?width:1, height>0?height:1 );
			
			if( !isHtml )	this.text 		= text ? text : "";
			else			this.htmlText 	= text ? text : "";
			
			_touchable = false;
			
			addEventListener( Event.ADDED_TO_STAGE, _onStage );
			addEventListener( Event.REMOVED_FROM_STAGE, _onRemove );
		}
		
		private var _userDefinedTouchable:Boolean = false;
		override public function set touchable(value:Boolean):void
		{
			_userDefinedTouchable = true;
			super.touchable = value;
		}
		private function set _touchable(value:Boolean):void
		{
			if( _userDefinedTouchable )	return;
			super.touchable = value;
		}
		
		/**
		 * @private
		 */
		protected function set mRequiresRedraw(value:Boolean):void
		{
			_mRequiresRedraw 		= value;
		}

		/** action to do when the textfield is added to stage **/
		protected function _onStage():void
		{
			// if there is links into the texts, add touch listener
			if( mLinksRect && mLinksRect.length > 0 )	
			{
				_touchable = true;
				addEventListener( TouchEvent.TOUCH, _onTouch );
			}
			else	_touchable = false;
		}
		
		/** actions to do when the textfield is removed from stage **/
		protected function _onRemove():void
		{
			// remove touch listener
			_touchable = false;
			removeEventListener( TouchEvent.TOUCH, _onTouch );
		}
		
		/** a static helper point used for the link touch detection **/
		private static var _hPoint		:Point 		= new Point();
		/** true when the mouse is over a link **/
		private var _isOver		:Boolean 	= false;
		/** true when the mouse is down on a link **/
		private var _isDown		:Boolean 	= false;
		/** touch process to detect links clicks **/
		private function _onTouch(e:TouchEvent):void
		{
			var touch:Touch = e.getTouch(this);
			if( !touch )
			{
				Mouse.cursor = MouseCursor.AUTO;
				_isOver = false;
				_isDown = false;
				return;
			}
			
			touch.getLocation(this,_hPoint);
			var idLink:int = mouseInLinkRect(_hPoint);
			
			if( idLink == -1 )
			{
				Mouse.cursor = MouseCursor.AUTO;
				_isOver = false;
				_isDown = false;
				return;
			}
			
			if( touch.phase == TouchPhase.HOVER )						// mouse over
			{
				Mouse.cursor = MouseCursor.BUTTON;
				_isOver = true;
			}
			else if( touch.phase == TouchPhase.BEGAN && !_isDown )		// mouse down
			{
				Mouse.cursor = MouseCursor.BUTTON;
				_isDown = true;
				_isOver = true;
			}
			else if( touch.phase == TouchPhase.ENDED && _isDown )		// mouse up -> click
			{
				_isDown = false;
				if( mLinks[idLink][0] == 'link' )	navigateToURLFunction( mLinks[idLink][1] );
				else								dispatchEventWith( mLinks[idLink][1] );
			}
		}
		
		[Inline]
		private final function mouseInLinkRect(p:Point):int
		{
			var len:int = mLinksRect.length;
			for( var i:int = 0; i<len; ++i )
			{
				if( mLinksRect[i].rect.containsPoint(p) )	return mLinksRect[i].id;
			}
			
			return -1;
		}
		
		/** dispose textures data. */
		public override function dispose():void
		{
			if( mImage )
			{
				if( mImage.texture )   mImage.texture.dispose();
				ImagePool.release(mImage);
				mImage = null;
			}
			super.dispose();
		}
		
		/** @inheritDoc */
		public override function render(painter:Painter):void
		{
			if( _mRequiresRedraw )  redrawContentDevice();
			super.render(painter);
		}
		
		/** the min height touch size for the links **/
		private static var MIN_TOUCH_HEIGHT:int = 15;
		
		private var _deviceFont:HTMLDeviceFonts;
		protected function redrawContentDevice():void
		{
			// sera recréé à la demande
			mTextBounds 		= null;
			// on vien de refaire un redraw c'est plus à faire
			mRequiresRedraw 	= false;
			
			// si html text on applique les tableaux de taille style et couleurs
			var sizes		:Array = mSizes && mSizes.length > 0 			? mSizes 		: [mSize];
			var styles		:Array = mStyles && mStyles.length > 0 			? mStyles 		: [mStyle];
			var colors		:Array = mColors && mColors.length > 0 			? mColors 		: [mColor];
			var underlines	:Array = mUnderlines && mUnderlines.length > 0 	? mUnderlines 	: [mUnderline];
			var links       :Array = mLinks && mLinksIds && mLinks.length > 0 && mLinksIds.length > 0 ? mLinksIds.concat() : null;

			// sinon on met les valeurs de base
			if( !mIsHTML )
			{
				sizes 	= [mSize];
				styles 	= [mStyle];
				colors 	= [mColor];
			}
			
			if( !_deviceFont )	_deviceFont = new HTMLDeviceFonts();

			_deviceFont.name        = mFontName;
			_deviceFont.lineSpacing = lineSpacing;

			mImage = _deviceFont.getImage( this, mHitArea.width, mHitArea.height, mText, mImage, sizes, styles, colors, underlines, links, mHAlign, mVAlign, mAutoScale, mResizeField, mAutoCR, mMaxWidth, mMinFontSize, mContourColor, mContourSize, mContourStrength,mShadowX, mShadowY, mShadowColor );
			addChild( mImage );

			if( mResizeField )
			{
				mHitArea.width 	= _baseWidth >= mImage.width ? _baseWidth : mImage.width;
				mHitArea.height = _baseHeight >= mImage.height ? _baseHeight : mImage.height;
			}

			// on gere les touch rect des liens
			if( links && links.length > 0 )
			{
				// on récupere le scaling et les offsets
				var scaling :Number = links.pop();
				var yoff    :Number = links.pop();
				var xoff    :Number = links.pop();

				// on prend des variables temps pour calculer le y et le height en fonction du MIN_TOUCH_HEIGHT
				var yy:Number;
				var hh:Number;

				var len     :int = links.length;
				mLinksRect = new Vector.<LinkRect>(len);
				for( var i:int = 0; i<len; ++i )
				{
					yy = (links[i][2]+yoff)*scaling;
					hh = links[i][4]*scaling;
					if( hh < MIN_TOUCH_HEIGHT )
					{
						yy -= (MIN_TOUCH_HEIGHT-hh)>>1;
						hh = MIN_TOUCH_HEIGHT;
					}
					mLinksRect[i] = new LinkRect( links[i][0], (links[i][1]+xoff)*scaling, yy, links[i][3]*scaling, hh );
				}

				// lancer le touch
				if( stage )
				{
					_touchable = true;
					addEventListener( TouchEvent.TOUCH, _onTouch );
				}
			}
			else if( touchable )
			{
				_touchable = false;
				removeEventListener( TouchEvent.TOUCH, _onTouch );
			}
		}

		/** get the bounds of the text. */
		public function get textBounds():Rectangle
		{
			if( _mRequiresRedraw ) 	    redrawContentDevice();
			if( mTextBounds == null ) 	mTextBounds = new Rectangle(mImage.x, mImage.y, mImage.width, mImage.height);//mImage.getBounds(
																													// this
																													// );
			
			return mTextBounds.clone();
		}
		
		/** @inheritDoc */
		public override function getBounds(targetSpace:DisplayObject, resultRect:Rectangle=null):Rectangle
		{
			getTransformationMatrix(targetSpace, sHelperMatrix);
			return RectangleUtil.getBounds(mHitArea, sHelperMatrix, resultRect);
		}
		
		/** @inheritDoc */
		public override function hitTest( localPoint:Point ):DisplayObject
		{
			if( !visible || !touchable ) 		            return null;
			else if (mHitArea.containsPoint(localPoint)) 	return this;
			else                                            return null;
		}
		
		/** @inheritDoc */
		public override function set width(value:Number):void
		{
			if( mHitArea.width == value )   return;
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
			if( mHitArea.height == value )   return;
			mHitArea.height = value;
			mRequiresRedraw = true;
		}
		public override function get height():Number
		{
			return mHitArea.height;
		}
		
		/** get the text width **/
		public function get textWidth():Number
		{
			if( _mRequiresRedraw ) 		redrawContentDevice();
			return mImage ? mImage.width : 0;
		}
		/** get the text height **/
		public function get textHeight():Number
		{
			if( _mRequiresRedraw ) 		redrawContentDevice();
			return mImage ? mImage.height : 0;
		}
		
		/** 
		 * the text, use htmlText to use simplified HTML
		 **/
		public function get text():String { return mText; }
		public function set text(value:String):void
		{
			if( !value )			value = '';
			if( mText == value )	return;
			
			if( mLinks )	mLinks.length = 0;
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
			if( !value )				value = '';
			if( mTextHTML == value )	return;
			
			if( mLinks )	mLinks.length = 0;
			mIsHTML 	= true;
			mTextHTML 	= value;
			
			_parseTextHTML();
			mRequiresRedraw = true;
		}
		
		/** 
		 * Parse simplified HTML
		 **/
		protected function _parseTextHTML():void
		{
			mText = '';
			if( !mTextHTML )	        return;
			
			// reset arrays
			mSizes.length 		        = 0;
			mStyles.length 		        = 0;
			mColors.length 		        = 0;
			if( mLinks )		        mLinks.length = 0;
			mUnderlines.length 	        = 0;
			mLinksIds.length            = 0;

			var sizeActu	:int 	    = mSize;
			var colorActu	:* 		    = mColor; // color or gradient
			var styleActu	:int 	    = mStyle;

			var params      :Array;

			var linkStart	:Array      = null;
			var linkID      :int        = -1;

			var prevSizes	:Array      = [mSize];
			var prevColors	:Array      = [mColor];
			
			var isBold		:Boolean    = mBold;
			var isItalic	:Boolean    = mItalic;
			var isUnderline	:Boolean    = mUnderline;
			
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
						case 'l':
							linkStart = [ 'link', mTextHTML.slice( mTextHTML.indexOf('"', i)+1, mTextHTML.indexOf('"', mTextHTML.indexOf('"', i)+1) ) ];
							if( defaultLinkColor )	colorActu = defaultLinkColor;
							break;
						case 'f':
							linkStart = [ 'func', mTextHTML.slice( mTextHTML.indexOf('"', i)+1, mTextHTML.indexOf('"', mTextHTML.indexOf('"', i)+1) ) ];
							if( defaultLinkColor )	colorActu = defaultLinkColor;
							break;
						case 'o':
							params = mTextHTML.slice( mTextHTML.indexOf('"', i)+1, mTextHTML.indexOf('"', mTextHTML.indexOf('"', i)+1) ).split(',');
							if( params.length == 1 )
								shadowX = shadowY = int(params[0]);
							else
								shadowX = int(params[0]);
							if( params.length > 1 ) shadowY     = int(params[1]);
							if( params.length > 2 ) shadowColor = int(params[2]);
							break;
						case 'a':
							params = mTextHTML.slice( mTextHTML.indexOf('"', i)+1, mTextHTML.indexOf('"', mTextHTML.indexOf('"', i)+1) ).split(',');
							contourSize = int(params[0]);
							if( params.length > 1 ) contourColor    = int(params[1]);
							if( params.length > 2 ) contourStrength = int(params[2]);
							break;
						case 'u':
							isUnderline = true;
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
								case 'l':
								case 'f':
									linkID = -1;
									if( defaultLinkColor )
									{
										if( prevColors.length > 1 )	prevColors.pop();
										colorActu = prevColors[prevColors.length-1];
									}
									break;
								case 'u':
									isUnderline = false;
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
					if( linkStart )
					{
						if( !mLinks )	mLinks = [];
						mLinks.push( linkStart );

						linkID          = mLinks.length-1;
						linkStart       = null;
					}

					// sinon on ajoute tel quel le caractere
					mText += char;
					// on ajoute la couleur actuelle
					mColors.push( colorActu );
					// on ajoute le soulignage
					mUnderlines.push( isUnderline );
					// on ajoute la taille actuelle
					mSizes.push( sizeActu );
					// on ajoute le style actuel
					mStyles.push( styleActu );
					// on ajoute le lien actuel
					mLinksIds.push( linkID );
				}
			}
		}
		
		/** 
		 * The font to use (only one by TexField)
		 **/
		public function get fontName():String { return mFontName; }
		public function set fontName(value:String):void
		{
			value = value.toLowerCase();
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
		 * Underline the text
		 **/
		public function get underline():Boolean { return mUnderline; }
		public function set underline(value:Boolean):void
		{
			if( mUnderline != value )
			{
				mUnderline = value;
				mUnderlines = [value];
				mRequiresRedraw = true;
			}
		}
		
		/**
		 * The base color of the text<br/>
		 * uint : 0x000000 -> solid color<br/>
		 * array 2 : [0x000000, 0xFF0000] -> top / bottom gradient<br/>
		 * array 4 : [0x000000, 0xFF0000, 0xFF0000, 0x000000] -> custom gradient<b/>
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
		
		/** change the line spacing **/
		public function get lineSpacing():int { return mLineSpacing; }
		public function set lineSpacing( value:int ):void
		{
			if( mLineSpacing != value )
			{
				mLineSpacing    = value;
				mRequiresRedraw = true;
			}
		}
		
		/** if true, the size will be enlarged to contain the text, the width is limited by maxWidth **/
		public function get resizeField():Boolean { return mResizeField; }
		public function set resizeField(value:Boolean):void
		{
			if( mResizeField != value )
			{
				mResizeField    = value;
				mRequiresRedraw = true;
			}
		}
		
		/** the maximum width when resizeField is set to true **/
		public function get maxWidth():int { return mMaxWidth; }
		public function set maxWidth(value:int):void
		{
			if( mMaxWidth != value )
			{
				mMaxWidth       = value;
				mRequiresRedraw = true;
			}
		}
		
		/** when true, the text will automaticaly go to the next line if it not fit in the width **/
		public function get autoCR():Boolean { return mAutoCR; }
		public function set autoCR(value:Boolean):void
		{
			if( mAutoCR != value )
			{
				mAutoCR         = value;
				mRequiresRedraw = true;
			}
		}

		/** horizontal shadow offset (0 = no shadow)**/
		public function get shadowX():int { return mShadowX; }
		public function set shadowX(value:int):void
		{
			if( mShadowX != value )
			{
				mShadowX        = value;
				mRequiresRedraw = true;
			}
		}
		/** vertical shadow offset (0 = no shadow)**/
		public function get shadowY():int { return mShadowY; }
		public function set shadowY(value:int):void
		{
			if( mShadowY != value )
			{
				mShadowY        = value;
				mRequiresRedraw = true;
			}
		}
		
		/** shadow color (default 0x0) **/
		public function get shadowColor():uint { return mShadowColor; }
		public function set shadowColor(value:uint):void
		{
			if( mShadowColor != value )
			{
				mShadowColor    = value;
				mRequiresRedraw = true;
			}
		}

		/** contour color (default 0x0) **/
		public function get contourColor():uint { return mContourColor; }
		public function set contourColor(value:uint):void
		{
			if( mContourColor != value )
			{
				mContourColor    = value;
				mRequiresRedraw = true;
			}
		}

		/** contour size : 0 -> pas de contour (default 0) **/
		public function get contourSize():uint { return mContourSize; }
		public function set contourSize(value:uint):void
		{
			if( mContourSize != value )
			{
				mContourSize    = value;
				mRequiresRedraw = true;
			}
		}

		/** contour force (default 1) **/
		public function get contourStrength():uint { return mContourStrength; }
		public function set contourStrength(value:uint):void
		{
			if( mContourStrength != value )
			{
				mContourStrength    = value;
				mRequiresRedraw     = true;
			}
		}


		/** minimum font size to reduce to (default 10) **/
		public function get minFontSize():int { return mMinFontSize; }
		public function set minFontSize(value:int):void
		{
			if( mMinFontSize != value )
			{
				mMinFontSize    = value;
				mRequiresRedraw = true;
			}
		}
		
		/** 
		 * force redraw 
		 */
		public function forceRedraw():void
		{
			redrawContentDevice();
		}
		
		/*override public function set x(value:Number):void
		{
			super.x = int(value);
		}
		override public function set y(value:Number):void
		{
			super.y = int(value);
		}*/
		
		public function get xint():Number{ return super.x };
		public function set xint(value:Number):void
		{
			super.x = int(value);
		}
		public function get yint():Number{ return super.y };
		public function set yint(value:Number):void
		{
			super.y = int(value);
		}
	}
}

import flash.geom.Rectangle;

internal class LinkRect
{
	public var id   :int;
	public var rect :Rectangle;

	public function LinkRect(id:int, x:Number, y:Number, width:Number, height:Number)
	{
		this.id     = id;
		this.rect   = new Rectangle(x,y,width,height);
	}
}