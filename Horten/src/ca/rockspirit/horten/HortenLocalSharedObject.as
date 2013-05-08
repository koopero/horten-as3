package ca.rockspirit.horten
{
	import flash.net.SharedObject;

	public class HortenLocalSharedObject extends HortenListener
	{
		protected var _so:SharedObject
		
		public function HortenLocalSharedObject( path:*, sharedKey:String = 'horten', horten:Horten=null)
		{
			_so = SharedObject.getLocal( sharedKey, '/' );
			super( path, null, true, horten);
			this.callback = onData;
			pull();
			
		}
		
		public function pull ():void
		{
			var d:* = _so.data.value;
			
			trace ( "************", "local data", JSON.stringify( d ) );
			
			this.set ( d );
		}
		
		protected function onData ( path:String, value:* ):void {
			trace ( "************", "local data set", JSON.stringify( value ) );
			
			_so.data.value = value;
			_so.flush();
		}
	}
}