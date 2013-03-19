package ca.rockspirit.horten
{
	import flash.events.Event;
	import flash.events.IEventDispatcher;
	import flash.utils.Proxy;
	import flash.utils.flash_proxy;
	
	/** Used to enable Horten's magical data property. */
	public dynamic class HortenProxy extends Proxy // implements IEventDispatcher
	{
		private var _horten:Horten;
		private var _path:String;
		
		public function HortenProxy( domain:Horten, path:String )
		{
			_horten = domain;
			_path = path;
		}
		
		//	----
		//	Cool
		//	----
		
		override flash_proxy function setProperty ( name:*, value:* ):void {
			_horten.set( _appendPath ( name ), value );
		}
		
		override flash_proxy function getProperty(name:*):* {
			return new HortenProxy ( _horten, _appendPath( name ) );
		}
		
		override flash_proxy function callProperty(methodName:*, ... args):* {
			var res:*;
			
			return res;
		}
		
		public function toString ():String {
			return String ( _horten.get( _path ) );
		}
		
		public function valueOf ():Object {
			return _horten.get ( _path );
		}
		
		private function _appendPath ( name:QName ):String {
			if ( _path == '' ) {
				return name.localName;
			}
			
			return _path+'/'+name.localName;
		}
		
		/*
		public function addListener ( listener:HortenListener, triggerNow:Boolean = false ):void {
			_horten.addListener( _path, listener, triggerNow );
		}
		*/
		
		/*
		//	--------------------------
		//	Implement IEventDispatcher
		//	--------------------------
		
		public function addEventListener(type:String, listener:Function, useCapture:Boolean=false, priority:int=0, useWeakReference:Boolean=false):void
		{
		}
		
		public function removeEventListener(type:String, listener:Function, useCapture:Boolean=false):void
		{
		}
		
		public function dispatchEvent(event:Event):Boolean
		{
			return false;
		}
		
		public function hasEventListener(type:String):Boolean
		{
			return false;
		}
		
		public function willTrigger(type:String):Boolean
		{
			return false;
		}
		*/
	}
}