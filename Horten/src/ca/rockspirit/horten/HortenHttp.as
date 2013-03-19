package ca.rockspirit.horten
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;

	public class HortenHttp extends HortenListener
	{
		protected var _url:String;
		
		public function HortenHttp ( 
			url:String, 
			localPath:* = '/', 
			horten:Horten = null
		) {
			_url = url;
			
			super( localPath, null, true, horten );
		}
		
		public override function attach(horten:Horten=null):void
		{
			/* 
			Does nothing. This listener doesn't actually care what's
			going on with horten unless we're explicitely told to push.
			*/
		}
		
		public override function push ( path:* = null ):void {
			var pathStr:String = Horten.pathString( path );
			
			var loader:URLLoader = new URLLoader ();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError );
			loader.addEventListener(Event.COMPLETE, onPushLoaderComplete );
			
			// Assume here that _url has no trailing slash
			var req:URLRequest = new URLRequest ( _url + pathStr );
			req.method = URLRequestMethod.POST;
			req.data = JSON.stringify( this.get ( path ) );
			
			loader.load( req );			
			
		}
		
		protected function pull ():void {
			
			var req:URLRequest = new URLRequest ( _url );
			req.method = URLRequestMethod.GET;
			
			var loader:URLLoader = new URLLoader();
			loader.dataFormat = URLLoaderDataFormat.TEXT;
			loader.addEventListener(IOErrorEvent.IO_ERROR, onLoaderError );
			loader.addEventListener(Event.COMPLETE, onPullLoaderComplete );
			
			loader.load( req );
			
		}

		
		//	--------------------
		//	Dealing with loaders
		//	--------------------
		
		protected function onPullLoaderComplete ( e:Event ):void {
			var loader:URLLoader = e.target as URLLoader;
			var str:String = String ( loader.data );
			//var data:Object = JSON.parse( str )
			try {
				var data:Object = JSON.parse( str );
			} catch ( e:Error ) {
				trace ( "**** WARNING Couldn't decode json from", _url );
				return;
			}
			
			this.set( data );
		}
		
		protected function onPushLoaderComplete ( e:Event ):void {
			//
		}
		
		protected function onLoaderError ( e:IOErrorEvent ):void {
			var loader:URLLoader = e.target as URLLoader;
			cleanUpLoader ( loader );
		}
		
		protected function cleanUpLoader ( loader:URLLoader ):void {
			loader.removeEventListener(Event.COMPLETE, onPullLoaderComplete );
			loader.removeEventListener(Event.COMPLETE, onPushLoaderComplete );
			loader.removeEventListener(IOErrorEvent.IO_ERROR, onLoaderError );
		}
		
	}
}