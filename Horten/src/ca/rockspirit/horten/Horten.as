package ca.rockspirit.horten
{
	import ca.rockspirit.util.isDynamic;

	public class Horten
	{
		// Magic object to declare that data needs to be fetched.
		internal static const FILL_DATA:Object = {};
		
		// Our actual data
		protected var _data:Object = {};
		
		public function Horten()
		{
			if ( !__instance ) {
				__instance = this;
			}
		}
		
		//	-------------------
		//	Getting and Setting
		//	-------------------
		
		public function set ( path:*, value:*, fromListener:HortenListener = null ):void {
			var pathStr:String = pathString( path );
			setMultiple ( flattenObject ( value, pathStr ) );
		}
		
		public function get ( path:* = null ):* {
			if ( path as String || !path ) {
				var pa:Array = pathArray ( path );
				var d:* = _data;
				var k:uint = pa.length;
				
				for ( var i:int = 0; i < k && d != null; i ++ ) {
					d = d[pa[i]];
				}
				
				return d;
			}
		}
		
		public function setMultiple ( values:Object, fromListener:HortenListener = null ):void {
			
			var triggers:Object = {};
		
			for ( var path:String in values ) {
				
				
				
				var value:* = values[path];
				
				
				trace ( "horten", path, '=>', value );
				
				var pa:Array 	= pathArray( path );
				var ps:String 	= pathString( path );
				
				//
				//	Set our internal, heirarchial data store
				//
				
				var changed:Boolean = false;
				
				var l:int = pa.length - 1;
				if ( l >= 0 ) {
					var w:* = _data;
					
					for ( var i:uint = 0; i < l; i ++ ) {
						var k:String = pa[i];
						var v:* = w[k];
						
						if ( ca.rockspirit.util.isDynamic( v ) ) {
							w = v;
						} else {
							if ( v != null ) { 
								// Along our way to the path we want,
								// we're replacing what used to be a
								// primitive with an object. Not a 
								// big deal, but probably need to
								// throw out some caches.
							}
							w[k] = {};
							w = w[k];
							changed = true;
						}; 
					};
					
					k = pa[i];
					if ( w[k] != value ) {
						w[k] = value;
						changed = true;
					}
					
				} else {
					// This is the setting of the root value to a primitive,
					// which is something we really don't want to do,
					// and will break stuff.
					
					// For now, bail.
					continue;
				}
				
				// Bail if nothing changed.
				if ( !changed )
					continue;
				
				for ( var listenerPath:String in _listenersGeneral ) {
					if ( ps.substr( 0, listenerPath.length ) == listenerPath ) {
						for each ( var listener:HortenListener in _listenersGeneral[ listenerPath ] ) {
							if ( listener == fromListener )
								continue;
							
							listener.setFromHorten( ps, value );
						}
					}
				}
				
				triggers[path] = value;
				
				//
				//  Set triggers for parent paths
				//
				while ( pa.length ) {
					pa.pop();
					
					var p:String = pa.length ? '/' + pa.join('/') + '/' : '/';
					
					if ( triggers[pa] )
						break; // This tree's been walked
					
					triggers[p] = FILL_DATA;
				}
			}
			
			for ( path in triggers ) {
				var listeners:Array = _listenersExact[path];
				
				if ( !listeners )
					continue; 
				
				value = triggers[path];
				
				if ( value === FILL_DATA )
					value = this.get ( path );
				
				for each ( listener in listeners ) {
					if ( listener == fromListener )
						continue;
					
					listener.setFromHorten( path, value );
				}
			}
			
			
		}
		
		//	------------------
		//	Magical Data Proxy
		//	------------------
		
		/** Allows the easy getting and setting of values using dot-syntax. For example:
		 * 
		 * horten.data.hello.world = 'example';
		 * 
		 * is the equivelent of 
		 * 
		 * horten.set ( '/hello/world/', 'example' );
		 * 
		 * As well, this can be used to add listeners:
		 * 
		 * horten.data.hello.addListener ( listener );
		 * 
		 */
		public function get data ():HortenProxy {
			return new HortenProxy ( this, '/' );
		}
		
		//	---------
		//	Listeners
		//	---------
		
		protected var _listenersExact:Object 	= {};
		protected var _listenersGeneral:Object 	= {};
		
		public function addListener ( paths:*, listener:HortenListener, triggerNow:Boolean = false ):void {
			var addToOb:Object = listener.exactPath ? _listenersExact : _listenersGeneral;
			
			paths = multiplePaths ( paths );
			
			for each ( var path:String in paths ) {
				var arr:Array = addToOb[ path ];
				if ( !arr )
					arr = addToOb[ path ] = [];
				
				arr.push( listener );
			}
			
			if ( triggerNow ) {
				for each ( path in paths ) {
					listener.setFromHorten( path, get ( path ) );
				}
			}
			
		}
		
		public function removeListener ( listener:HortenListener ):void 
		{
			for each ( var list:Object in [ _listenersExact, _listenersGeneral ] ) {
				for ( var path:String in list ) {
					var arr:Array = list[path];
					do {
						var ind:int = arr.indexOf( listener );
						if ( ind != -1 )
							arr.splice( ind, 1 );
					} while ( ind != -1 );
					
					if ( arr.length == 0 )
						delete list[path];
				}
			}
		}
		
		//	--------
		//	Plumbing
		//	--------
		
		/** 
		 * Flatten an object. Given an object, return an object with each property of the object and sub-objects
		 * as a single level hash with the key being a slashed path. For example:
		 * 
		 * { 'a': 1, 'b': 2 }  =>   { '/a/': 1, '/b/':2 }
		 * { 'a': { 'b': 1, 'c': 2 } } => { '/a/b/': 1, '/a/c/': 2 }
		 * 'foo' => { '/': 'foo' }
		 * 
		 * 
		 * @param ob
		 * @param path  The base path of the flattening. Used for recursion. If supplied, must have leading and trailing slashes.
		 * @param ret   The return object. Used for recursion.
		 * @returns The flattened object
		 */
		
		internal static function flattenObject ( ob:Object, path:String = null, ret:Object = null ):Object {
			// Make sure ret exists
			if ( !ret )
				ret = {};
			
			if ( !path )
				path = "/";
			
			if ( ob === false || ob === true || ob as String || ob as Number || ob as int || ob as uint || ob === null ) {
				// Primitives, easy.
				ret[path] = ob;
				
			} else {
				// 'Object', easier than Javascript
				for ( var p:String in ob ) {
					flattenObject ( ob[p], path+p+'/', ret );
				}
			}
			
			return ret;
		};
		
		//	------------
		//	Path Parsing
		//	------------
		
		public static function pathString ( path:* ):String {
			if ( path as Array ) {
				path = '/' + path.join ( '/' ) + '/';
			} else if ( path == null ) {
				// Default to '/'. Bad idea? Probably.
				path = '/';
			} else if ( !( path is String ) ) {
				throw new Error ( 'Bad path' );
			}
			
			if ( path.substr( 0, 1 ) != '/' )
				path = '/' + path;
			
			if ( path.substr( -1 ) != '/' )
				path = path + '/';
			
			// Trash double slashes. They shouldn't be there.
			while ( path.indexOf ( '//' ) != -1 )
				path = path.replace ( '//', '/' );
			
			return path;
		}
		
		public static function pathArray ( path:* ):Array {
			if ( !( path as Array ) ) {
				if ( path as String )
					path = path.split ( '/' );
				else {
					throw new Error ( 'Bad path' );
					path = [];
				}
			}
			
			path = path.filter ( function ( el:*, index:int, array:Array ):Boolean {
				return ( ( el as String ) && el.length > 0 );
			} );
			
			return path;			
		}
		
		public static function multiplePaths ( paths:* ):Array
		{
			if ( paths as String ) {
				return [ pathString ( paths ) ];
			}
			
			return [];
		}
		
		//	----------------
		//	Pseudo-singleton
		//	----------------
		
		protected static var __instance:Horten;
		
		public static function getInstance ():Horten
		{
			if ( !__instance ) {
				__instance = new Horten ();
			}
			
			return __instance;
		}
		
	}
}