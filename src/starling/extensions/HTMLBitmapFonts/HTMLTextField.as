package starling.extensions.HTMLBitmapFonts
{
	import flash.geom.Matrix;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.net.URLRequest;
	import flash.net.navigateToURL;
	import flash.ui.Mouse;
	import flash.ui.MouseCursor;
	import flash.utils.Dictionary;
	
	import starling.core.RenderSupport;
	import starling.display.DisplayObject;
	import starling.display.DisplayObjectContainer;
	import starling.display.QuadBatch;
	import starling.events.Event;
	import starling.events.Touch;
	import starling.events.TouchEvent;
	import starling.events.TouchPhase;
	import starling.text.BitmapChar;
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
		
		/** default blue color **/
		public static const DEFAULT_LINK_BLUE	:uint = 0x303DF0;
		/** define the default links color, null for no change (default null)**/
		public var defaultLinkColor				:* = null;
		
		/** the function to call to navigate to url (default flash.net.navigateToURL) **/
		public var navigateToURLFunction		:Function 			= HTMLTextField._navigateToURL;
		/** the urlRequest used by navigate to url function **/
		private static var _urlRequest			:URLRequest = new URLRequest();
		/** default navigate to urlFunction **/
		private static function _navigateToURL( url:String ):void
		{
			_urlRequest.url = url;
			navigateToURL( _urlRequest );
		}
		
		/** Helper objects. */
		protected static var sHelperMatrix		:Matrix 			= new Matrix();
		protected static var sHelperRect		:Rectangle			= new Rectangle();
		
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
		/** use kerning **/
		protected var mKerning					:Boolean;
		/** when true, the text will automaticaly go to the next line if it not fit in the width **/
		protected var mAutoCR					:Boolean = true;
		/** pass it to true if you want to hide the emotes but keep their place **/
		protected var mHideEmotes				:Boolean = false;
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
		protected var mShadowColor				:uint = 0x222222;
		
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
		/** the links list **/
		protected var mLinks					:Array;
		/** les rectangles de touch pour les lnks **/
		protected var mLinksRect				:Vector.<Rectangle>;
		/** the line spacing **/
		protected var mLineSpacing				:int = 0;
		
		/** text bounds **/
		protected var mTextBounds				:Rectangle;
		/** hit area **/
		protected var mHitArea					:Rectangle;
		
		/** the quadBatch **/
		protected var mQuadBatch				:QuadBatch;
		protected var mQuadBatchS				:QuadBatch;
		
		
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
		 * resizeField if true the text will have his width/height ajusted to the text size even if bigger than width/height value (see maxWidth).
		 **/
		public function HTMLTextField( width:int, height:int, text:String = '', fontName:String='verdana', fontSize:int = 16, color:* = 0xFFFFFF, bold:Boolean = false, italic:Boolean = false, isHtml:Boolean = true, resizeField:Boolean = false )
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
			this.fontName = fontName.toLowerCase();
			
			// définir les valeurs par défaut pour le textField
			mSize 				= fontSize;
			mColor 				= color;
			mHAlign 			= HAlign.CENTER;
			mVAlign 			= VAlign.CENTER;
			mKerning 			= true;
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
			
			addEventListener( Event.FLATTEN, onFlatten );
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
				if( mLinksRect[i].containsPoint(p) )	return i;
			}
			
			return -1;
		}
		
		/** dispose textures data. */
		public override function dispose():void
		{
			// disposer le QuadBatch du texte
			if( mQuadBatch )		mQuadBatch.dispose();
			if( mQuadBatchS )		mQuadBatchS.dispose();
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
			var sizes		:Array = mSizes && mSizes.length > 0 			? mSizes 		: [mSize];
			var styles		:Array = mStyles && mStyles.length > 0 			? mStyles 		: [mStyle];
			var colors		:Array = mColors && mColors.length > 0 			? mColors 		: [mColor];
			var underlines	:Array = mUnderlines && mUnderlines.length > 0 	? mUnderlines 	: [mUnderline];
			
			// sinon on met les valeurs de base
			if( !mIsHTML )
			{
				sizes 	= [mSize];
				styles 	= [mStyle];
				colors 	= [mColor];
			}
			
			var keepData:Object = mLinks && mLinks.length > 0 ? {} : null;
			// on fait draw le texte en fonction des parametres
			bitmapFont.lineSpacing = mLineSpacing;
			bitmapFont.fillQuadBatch( mQuadBatch, mHitArea.width, mHitArea.height, mText, sizes, styles, colors, underlines, mHAlign, mVAlign, mAutoScale, mKerning, mResizeField, keepData, mAutoCR, mMaxWidth, mHideEmotes, mMinFontSize );
			
			if( mShadowX != 0 || mShadowY != 0 )
			{
				if( mQuadBatchS == null ) 
				{ 
					mQuadBatchS = new QuadBatch(); 
					mQuadBatchS.touchable = false;
					mQuadBatchS.batchable = true;
					addChildAt( mQuadBatchS, 0 ); 
				}
				else
					mQuadBatchS.reset();
				
				bitmapFont.fillQuadBatch( mQuadBatchS, mHitArea.width, mHitArea.height, mText, sizes, styles, [mShadowColor], [false], mHAlign, mVAlign, mAutoScale, mKerning, mResizeField, false, mAutoCR, mMaxWidth, true, mMinFontSize );
				mQuadBatchS.x = mShadowX;
				mQuadBatchS.y = mShadowY;
			}
			else if( mQuadBatchS )
			{
				mQuadBatchS.removeFromParent(true);
				mQuadBatchS = null;
			}
			
			
			if( mResizeField )
			{
				mHitArea.width 	= _baseWidth >= mQuadBatch.width ? _baseWidth : mQuadBatch.width;
				mHitArea.height = _baseHeight >= mQuadBatch.height ? _baseHeight : mQuadBatch.height;
			}
			
			// apply vAlign
			mQuadBatch.getBounds(mQuadBatch, sHelperRect);
			var yOffset:int = 0;
			
			if( vAlign == VAlign.TOP )      	yOffset 	= -sHelperRect.y;
			else if( vAlign == VAlign.BOTTOM )  yOffset 	= -sHelperRect.y + (height-sHelperRect.height);
			else if( vAlign == VAlign.CENTER ) 	yOffset 	= -sHelperRect.y + (height-sHelperRect.height)/2;
			if( yOffset < 0 )					yOffset 	= 0;
			
			mQuadBatch.y = yOffset;
			if( mQuadBatchS )	
				mQuadBatchS.y 	= yOffset + shadowY;
			
			if( mLinks && mLinks.length > 0 )
			{
				var charLoc:Vector.<CharLocation> = keepData.loc;
				var charLen:int = charLoc.length-1;
				if( charLen < 0 )	charLen = 0;
				var len:int = mLinks.length;
				mLinksRect = new Vector.<Rectangle>(len);
				for( var i:int = 0; i<len; ++i )
				{
					if( mLinks[i][0] >= charLen	) mLinks[i][0] = charLen;
					if( mLinks[i][1] >= charLen	) mLinks[i][1] = charLen;
					if( mLinks[i][2] >= charLen	) mLinks[i][2] = charLen;
					if( mLinks[i][3] >= charLen	) mLinks[i][3] = charLen;
					
					// verifier qu'on soit pas sur plusieurs lignes
					if( charLoc[mLinks[i][3]].y > charLoc[mLinks[i][2]].y + charLoc[mLinks[i][2]].char.height )
					{
						var end:Array 		= getNextBR( mLinks[i][2], charLoc );
						var newEnd:int 		= end[0];
						var newStart:int 	= end[1];
						
						var hh:int = charLoc[newEnd].char.height;
						
						mLinksRect[i] = new Rectangle( 	charLoc[mLinks[i][2]].x,
							charLoc[mLinks[i][2]].y - hh + yOffset,
							(charLoc[newEnd].x + charLoc[newEnd].char.width) - charLoc[mLinks[i][2]].x,
							(charLoc[newEnd].y + charLoc[newEnd].char.height) - charLoc[mLinks[i][2]].y + hh + yOffset );
						
						if( newStart < charLoc.length )
						{
							// on met la suite du lien à la suite pour qu'il soit traité apres
							var newLink:Array = [ mLinks[i][0], mLinks[i][1], newStart, mLinks[i][3] ];
							mLinks.push(newLink);
							mLinksRect.length += 1;
							++len;
						}
					}
					else
					{
						hh = charLoc[mLinks[i][3]].char.height;
						
						mLinksRect[i] = new Rectangle( 	charLoc[mLinks[i][2]].x,
														charLoc[mLinks[i][2]].y - hh + yOffset,
														(charLoc[mLinks[i][3]].x + charLoc[mLinks[i][3]].char.width) - charLoc[mLinks[i][2]].x,
														(charLoc[mLinks[i][3]].y + charLoc[mLinks[i][3]].char.height) - charLoc[mLinks[i][2]].y + hh + yOffset );
					}
				}
				
				mLinksRect.fixed 	= true;
				mLinks.fixed 		= true;
				
				if( charLoc )	CharLocation.returnVector(charLoc);
				keepData = null;
				charLoc = null;
				
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
		
		[Inline]
		private final function getNextBR( start:int, charLoc:Vector.<CharLocation> ):Array
		{
			var len				:int = charLoc.length;
			var lastRealChar	:int = 0;
			var spaceCode		:int = String(' ').charCodeAt(0);
			for( var i:int = start+1; i<len; ++i )
			{
				if( lastRealChar > 0 && charLoc[i].y > charLoc[start].y + charLoc[start].char.height && charLoc[i].char.charID != spaceCode )		return [lastRealChar, i];
				if( charLoc[i].char.charID != 10 && charLoc[i].char.charID != 13 && charLoc[i].char.charID != spaceCode )							lastRealChar = i;
			}
			return [lastRealChar, len-1];
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
			
			// sauts de lignes
			mTextHTML = mTextHTML.split( '<br>' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<BR>' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<br/>' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<BR/>' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<br />' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( '<BR />' ).join( String.fromCharCode(10) );
			mTextHTML = mTextHTML.split( String.fromCharCode(149) ).join( String.fromCharCode(8226) );
			
			// reset arrays
			mSizes.length 	= 0;
			mStyles.length 	= 0;
			mColors.length 	= 0;
			if( mLinks )	mLinks.length = 0;
			
			var lastRealChar	:int = -1;
			var isRealChar		:Boolean = false;
			
			var sizeActu	:int 		= mSize;
			var colorActu	:* 			= mColor; // color or gradient
			var styleActu	:int 		= mStyle;
			
			var linkActu	:Array	= null;
			var linkStart	:Boolean = false;
			var linkEnd		:Boolean = false;
			
			var prevSizes	:Array = [mSize];
			var prevColors	:Array = [mColor];
			var prevStyles	:Array = [mStyle];
			
			var isBold		:Boolean = mBold;
			var isItalic	:Boolean = mItalic;
			var isUnderline	:Boolean = mUnderline;
			
			var colorStr	:String;
			var sizeStr		:String;
			
			var char		:String;
			
			var actualID	:int
			var actualIDComputed:Boolean = false;
			
			var len:int = mTextHTML.length;
			for( var i:int = 0; i<len; ++i )
			{
				char = mTextHTML.charAt(i);
				actualIDComputed = false;
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
							linkActu = [ 'link', mTextHTML.slice( mTextHTML.indexOf('"', i)+1, mTextHTML.indexOf('"', mTextHTML.indexOf('"', i)+1) ) ];
							linkStart = true;
							if( defaultLinkColor )	colorActu = defaultLinkColor;
							break;
						case 'f':
							linkActu = [ 'func', mTextHTML.slice( mTextHTML.indexOf('"', i)+1, mTextHTML.indexOf('"', mTextHTML.indexOf('"', i)+1) ) ];
							linkStart = true;
							if( defaultLinkColor )	colorActu = defaultLinkColor;
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
									linkEnd = true;
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
					// on ajoute le soulignage
					mUnderlines.push( isUnderline );
					
					if( char.charCodeAt(0) != 10 && char.charCodeAt(0) != 13 && char != ' ' )
					{
						lastRealChar 	= mColors.length-1;
						isRealChar 		= true;
					}
					else isRealChar = false;
					
					if( linkActu )
					{
						//saut de ligne en cours de lien
						if( linkActu.length > 2 && (char.charCodeAt(0) == 10 || char.charCodeAt(0) == 13) )
						{
							linkActu.push( htmlBitmapFonts[mFontName] ? htmlBitmapFonts[mFontName].getIndex(lastRealChar, mText) : lastRealChar );
							
							if( !mLinks )	mLinks = [];
							mLinks.push( linkActu );
							linkStart 	= true;
							linkActu 	= [ linkActu[0], linkActu[1] ];
							
							continue;
						}
						
						if( linkStart && isRealChar )	
						{
							if( !actualIDComputed )
							{
								actualID 			= htmlBitmapFonts[mFontName] ? htmlBitmapFonts[mFontName].getIndex(mColors.length-1, mText) : mColors.length-1;
								actualIDComputed 	= true;
							}
							
							linkActu.push( actualID );
							linkStart = false;
						}
						if( linkEnd )
						{
							linkActu.push( htmlBitmapFonts[mFontName] ? htmlBitmapFonts[mFontName].getIndex(lastRealChar, mText) : lastRealChar );
							linkEnd = false;
							
							if( !mLinks )	mLinks = [];
							mLinks.push( linkActu );
							linkActu = null;
						}
					}
				}
			}
			
			if( linkActu )
			{
				if( linkStart )
				{
					if( !actualIDComputed )
					{
						actualID 			= htmlBitmapFonts[mFontName] ? htmlBitmapFonts[mFontName].getIndex(mColors.length-1, mText) : mColors.length-1;
						actualIDComputed 	= true;
					}
					
					linkActu.push( actualID );
					linkStart = false;
				}
				if( linkEnd )	
				{
					linkActu.push( htmlBitmapFonts[mFontName] ? htmlBitmapFonts[mFontName].getIndex(lastRealChar, mText) : lastRealChar );
					linkEnd = false;
					
					if( !mLinks )	mLinks = [];
					mLinks.push( linkActu );
					linkActu = null;
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
		
		/** change the line spacing **/
		public function get lineSpacing():int { return mLineSpacing; }
		public function set lineSpacing( value:int ):void
		{
			mLineSpacing = value;
			mRequiresRedraw = true;
		}
		
		/** if true, the size will be enlarged to contain the text, the width is limited by maxWidth **/
		public function get resizeField():Boolean { return mResizeField; }
		public function set resizeField(value:Boolean):void
		{
			mResizeField = value;
			mRequiresRedraw = true;
		}
		
		/** the maximum width when resizeField is set to true **/
		public function get maxWidth():int { return mMaxWidth; }
		public function set maxWidth(value:int):void
		{
			mMaxWidth = value;
			mRequiresRedraw = true;
		}
		
		/** when true, the text will automaticaly go to the next line if it not fit in the width **/
		public function get autoCR():Boolean { return mAutoCR; }
		public function set autoCR(value:Boolean):void
		{
			mAutoCR = value;
			mRequiresRedraw = true;
		}
		
		/** pass it to true if you want to hide the emotes but keep their place **/
		public function get hideEmotes():Boolean { return mHideEmotes; }
		public function set hideEmotes(value:Boolean):void
		{
			mHideEmotes = value;
			mRequiresRedraw = true;
		}
		
		/** horizontal shadow offset (0 = no shadow)**/
		public function get shadowX():int { return mShadowX; }
		public function set shadowX(value:int):void
		{
			mShadowX = value;
			mRequiresRedraw = true;
		}
		/** vertical shadow offset (0 = no shadow)**/
		public function get shadowY():int { return mShadowY; }
		public function set shadowY(value:int):void
		{
			mShadowY = value;
			mRequiresRedraw = true;
		}
		
		/** shadow color (default 0x222222) **/
		public function get shadowColor():uint { return mShadowColor; }
		public function set shadowColor(value:uint):void
		{
			mShadowColor = value;
			mRequiresRedraw = true;
		}
		
		/** minimum font size to reduce to (default 10) **/
		public function get minFontSize():int { return mMinFontSize; }
		public function set minFontSize(value:int):void
		{
			mMinFontSize = value;
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
		 * Register emote shortcut and the texture associated 
		 * @param shortcut the shortcut of the emote
		 * @param texture the texture associated with ths emote
		 * @param xOffset a custom xOffset for the emote (default 0)
		 * @param yOffset a custom yOffset for the emote (default 0)
		 * @param xAdvance a custom xAdvance for the emote, if -1 advance will be texture.width (default -1)
		 **/
		public static function registerEmote( shortcut:String, texture:Texture, xOffset:int = 0, yOffset:int = 0, xAdvance:int = -1 ):void
		{
			HTMLBitmapFonts.registerEmote( shortcut, texture, xOffset, yOffset, xAdvance );
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
		
		/** return the available sizes for the given style **/
		public function getAvailableSizes( style:int ):Vector.<Number>
		{
			return HTMLBitmapFonts(htmlBitmapFonts[mFontName]).getAvailableSizesForStyle( style );
		}
		
		override public function set x(value:Number):void
		{
			super.x = int(value);
		}
		override public function set y(value:Number):void
		{
			super.y = int(value);
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
		
		//-- HELPER FUNCTIONS --//
		
		public function getChar( style:int, charID:int, sizeIndex:int ):BitmapChar
		{
			return htmlBitmapFonts[mFontName].getChar( style, charID, sizeIndex );
		}
		public function getBaseLine( style:int, sizeIndex:int ):Number
		{
			return htmlBitmapFonts[mFontName].getBaseLine( style, sizeIndex );
		}
		public function getLineHeight( style:int, sizeIndex:int ):Number
		{
			return htmlBitmapFonts[mFontName].getLineHeight( style, sizeIndex );
		}
	}
}