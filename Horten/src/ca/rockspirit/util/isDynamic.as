package ca.rockspirit.util
{
	
	/** A dirty check to see if an Object ( cursed be it's fuckery ) is dynamic or not. */
	public function isDynamic ( ob:* ):Boolean {
		if ( ob == null )
			return false;
		
		try {
			ob['____betterFuckingNotBeAProperty']
		} catch ( e:Error ) {
			return false;
		}
		
		return true;
	}
}



