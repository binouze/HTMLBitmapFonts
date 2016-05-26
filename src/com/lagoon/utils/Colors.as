/**
 * Created by Benjamin BOUFFIER on 13/10/2015.
 */
package com.lagoon.utils
{
	public class Colors
	{
		public function Colors()
		{
		}

		public static function extractRed(c:uint):uint
		{
			return (( c >> 16 ) & 0xFF);
		}



		public static function extractGreen(c:uint):uint
		{
			return ( (c >> 8) & 0xFF );
		}



		public static function extractBlue(c:uint):uint
		{
			return ( c & 0xFF );
		}
	}
}
