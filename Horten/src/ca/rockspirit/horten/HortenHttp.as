package ca.rockspirit.horten
{
	import flash.events.Event;
	import flash.events.IOErrorEvent;
	import flash.events.TimerEvent;
	import flash.net.URLLoader;
	import flash.net.URLLoaderDataFormat;
	import flash.net.URLRequest;
	import flash.net.URLRequestMethod;
	import flash.utils.Timer;

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
		
		//	---------------------
		//	Auto Push / Auto Pull
		//	---------------------
		
		protected var _pushTimer:Timer;
		protected var _pullTimer:Timer;
		
		public function set autoPush ( seconds:Number ):void {
			if ( seconds > 0 && !isNaN ( seconds ) ) {
				if ( !_pushTimer ) {
					_pushTimer = new Timer ( seconds * 1000 );
					_pushTimer.addEventListener(TimerEvent.TIMER, onAutoPush );
					_pushTimer.start();
				} else {
					_pushTimer.delay = seconds * 1000;
				}
			} else if ( _pushTimer ) {
				_pushTimer.removeEventListener(TimerEvent.TIMER, onAutoPush );
				_pushTimer.stop();
				_pushTimer = null;
			}
		}
		
		public function get autoPush ():Number {
			return _pushTimer ? _pushTimer.delay / 1000.0 : 0;
		}
		
		public function set autoPull ( seconds:Number ):void {
			if ( seconds > 0 && !isNaN ( seconds ) ) {
				if ( !_pullTimer ) {
					_pullTimer = new Timer ( seconds * 1000 );
					_pullTimer.addEventListener(TimerEvent.TIMER, onAutoPull );
					_pullTimer.start();
				} else {
					_pullTimer.delay = seconds * 1000;
				}
			} else if ( _pullTimer ) {
				_pullTimer.removeEventListener(TimerEvent.TIMER, onAutoPull );
				_pullTimer.stop();
				_pullTimer = null;
			}
		}
		
		public function get autoPull ():Number {
			return _pullTimer ? _pullTimer.delay / 1000.0 : 0;
		}
		
		
		protected function onAutoPull ( e:Event ):void {
			pull ();
		}
		
		protected function onAutoPush ( e:Event ):void {
			push ();
		}
		
		
		//	-----------
		//	Push / Pull
		//	-----------
		
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
		
		public function pull ():void {
			
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