package ca.rockspirit.horten
{
	public class HortenListener
	{
		
		internal var _exactPath:Boolean = false;
		
		/** A function to call when the value of a path being listened to changes. The callback must
		 * be of the signature function ( path:String, value:* ). 'path' will be sent as
		 * a Horten-style path with leading and trailing slashes, and value will be the
		 * most current value of the path.
		 * 
		 * If exactPath is set to true, path will always be path where the listener was
		 * added to Horten, and value will be an object of all values beneath this path.
		 * 
		 * If exactPath is false, the path can be any path beneath the path where the
		 * listener was added, and the value should always be a primitive.
		 */ 
		public var callback:Function;
		
		/** An object upon which to set 'property'.*/
		public var context:Object;
		
		/** A property to be set on the object defined in 'context'. When a path
		 * being listened to changed, the property is set. For this to work,
		 * both 'context' and 'property' must be set, and 'exactPath' must
		 * be true.
		 * 
		 * This is most useful when used with a setter on the target object.
		 * 
		 */
		public var property:String;
		
		protected var _horten:Horten;
		protected var _hortenPath:String;
		protected var _myPath:String;
		protected var _pathsAreTheSame:Boolean;


		public function HortenListener( hortenPath:*, myPath:* = null, exactPath:Boolean = true, horten:Horten = null )
		{
			if ( !horten )
				horten = Horten.getInstance();
			
			_hortenPath = Horten.pathString( hortenPath );
			_myPath = Horten.pathString( myPath );
			
			_pathsAreTheSame = _hortenPath == _myPath;
			
			
			this._horten = horten;
			this._exactPath = exactPath;
			
			listening = true;
		}
		
		
		protected var _listening:Boolean = false;
		
		public function set listening ( value:Boolean ):void {
			if ( value == _listening )
				return;
			
			_listening = value;
			if ( value ) 
				attach ( _horten );
			else 
				remove ();
		}
		
		
		public function attach ( horten:Horten = null ):void {
			remove ();
			
			horten = horten || _horten;
			
			_horten = horten;
			
			if ( _horten && _listening ) {
				_horten.addListener( _hortenPath, this, false);
			}
			
		}
		
		public function remove ():void {
			if ( _horten ) {
				_horten.removeListener( this );
			}
		}
		
		
		/** 
		 * Whether or not the listen is in 'exact path' mode. When exactPath is true ( default ),
		 * the listener's callback will be fired on the path specified by the listener, and only that
		 * path. The entire hierarchy under our path will be returned.
		 * 
		 * When exactPath is false, individual, primitive changes are sent to the callback with
		 * their paths relative to the listener.
		 */
		public function get exactPath ():Boolean
		{
			return _exactPath;
		}
		
		//
		//
		//
		
		/** 
		 * The Horten instance we're either currently attached to or were attached to if removed.
		 * Setting will either attach this listener to a new Horten instance, or detach if set to null.
		 */
		public function get horten ():Horten
		{
			return _horten;
		}
		
		public function set horten ( v:Horten ):void {
			if ( v == null ) {
				remove();
				_horten = null;
			} else {
				attach ( v );
			}
		}
		

		//	----
		//	Path
		//	----
		
		public function set path ( p:* ):void {
			if ( !p ) {
				remove();
				return;
			}
			
			p = Horten.pathString( p );
			
			if ( p == _hortenPath )
				return;
			
			remove ();
			_hortenPath = p;
			attach ( _horten );
		}
		
		public function get path ():String {
			return _hortenPath;
		}
		
		
		public function set ( value:* ):void {
			if ( _horten ) {
				_horten.set( _hortenPath, value );
			}
		}
		
		public function get ( path:* = null ):* {
			if ( _horten ) {
				return _horten.get( _hortenPath + Horten.pathString( path ) );
			}
			
			return null;
		}
		
		//	-----------
		//	Push / Pull
		//	-----------

		
		/** Push all data from Horten to the listener. */
		public function push ( path:* = null ):void {
			if ( _exactPath ) {
				this.setFromHorten ( _hortenPath, _horten.get( _hortenPath ) );
			} else {
				var p:String = Horten.pathString( path );
				var d:Object = _horten.get( this.remoteToLocalPath( p ) );
				d = Horten.flattenObject( d, p );
				
				for ( var k:String in d ) {
					this.setFromHorten( k, d[k], true );
				}
			}
		}
		
		
		//	----------------
		//	Path Translation
		//	----------------
		
		public function localToRemotePath ( localPath:String ):String {
			if ( _pathsAreTheSame )
				return localPath;
			
			if ( localPath.substr( 0, _hortenPath.length ) != _hortenPath )
				return null;
			
			return _myPath + localPath.substr( _hortenPath.length );
		}
		
		public function remoteToLocalPath ( remotePath:String ):String {
			if ( _pathsAreTheSame )
				return remotePath;
			
			if ( remotePath.substr( 0, _myPath.length ) != _myPath )
				return null;
			
			return _hortenPath + remotePath.substr( _myPath.length );
		}
		
		
		/** Called by Horten when a value changes. */
		internal function setFromHorten ( path:String, value:*, pathIsLocal:Boolean = false ):void {
			var pathLen:int = _hortenPath.length;
			
			if ( !pathIsLocal ) {
				if ( path.substr( 0, pathLen ) != _hortenPath )
					throw new Error ( 'Unneeded data sent to listener' );
				
				path = localToRemotePath ( path );
			}
			
			if ( callback != null ) {
				callback ( path, value );
			}
			
			if ( _exactPath && context != null && property != null )
				context[property] = value;
		}
		

		

	}
}