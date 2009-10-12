package org.papervision3d.core.proto
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import org.papervision3d.core.math.Quaternion;
	import org.papervision3d.core.math.utils.MathUtil;
	import org.papervision3d.core.ns.pv3d;
	
	/**
	 * Transform3D.
	 * <p></p>
	 * 
	 * @author Tim Knip / floorplanner.com
	 */ 
	public class Transform3D
	{
		use namespace pv3d;
		
		/** */
		public static var DEFAULT_LOOKAT_UP :Vector3D = new Vector3D(0, -1, 0);
		
		/** */
		public var worldTransform :Matrix3D;
		
		/** */
		public var viewTransform :Matrix3D;
		
		/** */
		public var screenTransform :Matrix3D;
		
		/** The X axis of the transform in world space */
		public var right :Vector3D;
		
		/** The Y axis of the transform in world space */
		public var up :Vector3D;
		
		/** The Z axis of the transform in world space */
		public var forward :Vector3D;
		
		/** */
		pv3d var scheduledLookAt :Transform3D;
		
		/** */
		pv3d var scheduledLookAtUp :Vector3D;
		
		/** */
		private var _parent :Transform3D;
		
		/** The position of the transform in world space. */
		private var _position :Vector3D;
		
		/** Position of the transform relative to the parent transform. */
		private var _localPosition :Vector3D;
		
		/** The rotation as Euler angles in degrees. */
		private var _eulerAngles :Vector3D;
		
		/** The rotation as Euler angles in degrees relative to the parent transform's rotation. */
		private var _localEulerAngles :Vector3D;
		
		/** The rotation of the transform in world space stored as a Quaternion. */
		private var _rotation :Quaternion;
		
		/** The rotation of the transform relative to the parent transform's rotation. */
		private var _localRotation :Quaternion;
		
		/** */
		private var _localScale :Vector3D;
		
		private var _transform :Matrix3D;
		private var _localTransform :Matrix3D;
		
		private var _dirty :Boolean;
		
		private var _do3d :DisplayObjectContainer3D;
		
		/**
		 * 
		 */ 
		public function Transform3D(do3d:DisplayObjectContainer3D)
		{
			_do3d = do3d;
			_position = new Vector3D();
			_localPosition = new Vector3D();
			_eulerAngles = new Vector3D();
			_localEulerAngles = new Vector3D();
			_rotation = new Quaternion();
			_localRotation = new Quaternion();
			_localScale = new Vector3D(1, 1, 1);
			_transform = new Matrix3D();
			_localTransform = new Matrix3D();
			
			this.right = new Vector3D();
			this.up = new Vector3D();
			this.forward = new Vector3D();
			
			this.worldTransform = new Matrix3D();
			this.viewTransform = new Matrix3D();
			this.screenTransform = new Matrix3D();
			
			_dirty = false;
		}
		
		/**
		 * Rotates the transform so the forward vector points at /target/'s current position.
		 * <p>Then it rotates the transform to point its up direction vector in the direction hinted at by the 
		 * worldUp vector. If you leave out the worldUp parameter, the function will use the world y axis. 
		 * worldUp is only a hint vector. The up vector of the rotation will only match the worldUp vector if 
		 * the forward direction is perpendicular to worldUp</p>
		 */ 
		public function lookAt(target:Transform3D, worldUp:Vector3D=null):void
		{
			// actually, we only make note that a lookAt is scheduled.
			// its up to some higher level class to deal with it.
			scheduledLookAt = target;
			scheduledLookAtUp = worldUp || DEFAULT_LOOKAT_UP;
		}
		
		/**
		 * Applies a rotation of eulerAngles.x degrees around the x axis, eulerAngles.y degrees around 
		 * the y axis and eulerAngles.z degrees around the z axis.
		 * 
		 * @param	eulerAngles
		 * @param	relativeToSelf
		 */ 
		public function rotate(eulerAngles:Vector3D, relativeToSelf:Boolean=true):void
		{
			if (relativeToSelf)
			{
				_localEulerAngles.x = eulerAngles.x % 360;
				_localEulerAngles.y = eulerAngles.y % 360;
				_localEulerAngles.z = eulerAngles.z % 360;
				
				_localRotation.setFromEuler(
					-_localEulerAngles.y * MathUtil.TO_RADIANS, 
					_localEulerAngles.z * MathUtil.TO_RADIANS,
					_localEulerAngles.x * MathUtil.TO_RADIANS
					);
			}
			else
			{
				_eulerAngles.x = eulerAngles.x % 360;
				_eulerAngles.y = eulerAngles.y % 360;
				_eulerAngles.z = eulerAngles.z % 360;
				
				_rotation.setFromEuler(
					-_eulerAngles.y * MathUtil.TO_RADIANS, 
					_eulerAngles.z * MathUtil.TO_RADIANS,
					_eulerAngles.x * MathUtil.TO_RADIANS
					);
			}
			_dirty = true;
		}
		
		/**
		 * 
		 */
		public function get dirty():Boolean
		{
			return _dirty;
		} 
		
		public function set dirty(value:Boolean):void
		{
			_dirty = value;
		}
		
		/** 
		 * The rotation as Euler angles in degrees. 
		 */
		public function get eulerAngles():Vector3D
		{
			return _eulerAngles;
		}
		
		public function set eulerAngles(value:Vector3D):void
		{
			_eulerAngles = value;
			_dirty = true;
		}
		
		/** 
		 * The rotation as Euler angles in degrees relative to the parent transform's rotation. 
		 */
		public function get localEulerAngles():Vector3D
		{
			return _localEulerAngles;
		}
		
		public function set localEulerAngles(value:Vector3D):void
		{
			_localEulerAngles = value;
			_dirty = true;
		}
		
		/**
		 * 
		 */ 
		public function get localToWorldMatrix():Matrix3D
		{
			if (_dirty && !scheduledLookAt)
			{
				
				rotate( _localEulerAngles, true );
				
				_transform.rawData = _localRotation.matrix.rawData;
				_transform.appendTranslation( _localPosition.x, _localPosition.y, _localPosition.z);
	
				rotate( _eulerAngles, false );
				_transform.append( _rotation.matrix );
				
				_transform.prependScale(_localScale.x, _localScale.y, _localScale.z);
	
				_transform.append( _rotation.matrix );
				
			}
			if( scheduledLookAt )
			{		
				_transform.rawData = _localRotation.matrix.rawData;
				_transform.appendTranslation( _localPosition.x, _localPosition.y, _localPosition.z);
			}
			_dirty = false;
			return _transform;
		}
		
		/**
		 * The position of the transform in world space.
		 */
		public function get position():Vector3D
		{
			return _position;
		} 
		
		public function set position(value:Vector3D):void
		{
			_position = value;
		//	_dirty = true;
		}
		
		/**
		 * Position of the transform relative to the parent transform.
		 */
		public function get localPosition():Vector3D
		{
			return _localPosition;
		} 
		
		public function set localPosition(value:Vector3D):void
		{
			_localPosition = value;
		//	_dirty = true;
		}
		
		/**
		 * 
		 */
		public function get rotation():Quaternion
		{
			return _rotation;
		} 
		
		public function set rotation(value:Quaternion):void
		{
			_rotation = value;	
		}
		
		/**
		 * 
		 */
		public function get localRotation():Quaternion
		{
			return _localRotation;
		} 
		
		public function set localRotation(value:Quaternion):void
		{
			_localRotation = value;	
		}
		
		/**
		 * 
		 */
		public function get localScale():Vector3D
		{
			return _localScale;
		} 
		
		public function set localScale(value:Vector3D):void
		{
			_localScale = value;
			_dirty = true;
		}
		
		public function get parent():Transform3D
		{
			return _parent;
		}
		
		public function set parent(value:Transform3D):void
		{
			_parent = value;
		}
	}
}