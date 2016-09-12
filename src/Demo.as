package
{
	import com.lagoon.display.images.ImagePool;

	import flash.display.Sprite;
	import flash.events.Event;

	import starling.core.Starling;
	import starling.events.Event;

	[SWF(backgroundColor="#888888",height="800",width="1800")]
	public class Demo extends Sprite
	{
		private var mStarling:Starling;

		public function Demo()
		{
			addEventListener( flash.events.Event.ADDED_TO_STAGE, onStage );
		}
		private function onStage(e:flash.events.Event):void
		{
			// création de starling
			mStarling = new Starling( DeviceFontsSample, stage, null, null, 'auto', 'auto' );
			// on attend le root created
			mStarling.addEventListener( starling.events.Event.ROOT_CREATED, _onRootCreated );
			// on affiche les stats en debug sinon non
			mStarling.showStats = CONFIG::DEBUG;
			mStarling.enableErrorChecking = CONFIG::DEBUG;
			// et on lance starling
			mStarling.start();
		}

		private function _onRootCreated( event:starling.events.Event, demo:DeviceFontsSample ):void
		{
			ImagePool.init(50);

			mStarling.removeEventListener( event.type, _onRootCreated );

			// mettre le fps a 30 fps en mode software
			if( mStarling.context.driverInfo.toLowerCase().indexOf("software") != -1 )
				mStarling.nativeStage.frameRate = 30;
			else
				mStarling.nativeStage.frameRate = 60;

			demo.init();
		}
	}
}
