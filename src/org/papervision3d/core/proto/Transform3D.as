package org.papervision3d.core.proto
{
	import flash.geom.Matrix3D;
	import flash.geom.Vector3D;
	
	import org.papervision3d.core.math.Quaternion;
	import org.papervision3d.core.math.utils.MathUtil;
	
	public class Transform3D
	{
		/** */
		public static var DEFAULT_LOOKAT_UP :Vector3D = new Vector3D(0, -1, 0);
		
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
		
		/** The X axis of the transform in world space */
		private var _right :Vector3D;
		
		/** The Y axis of the transform in world space */
		private var _up :Vector3D;
		
		/** The Z axis of the transform in world space */
		private var _forward :Vector3D;
		
		/** The rotation of the transform in world space stored as a Quaternion. */
		private var _rotation :Quaternion;
		
		/** The rotation of the transform relative to the parent transform's rotation. */
		private var _localRotation :Quaternion;
		
		/** */
		private var _localScale :Vector3D;
		
		private var _transform :Matrix3D;
		private var _localTransform :Matrix3D;
		
		private var _dirty :Boolean;
		
		/**
		 * 
		 */ 
		public function Transform3D()
		{
			_position = new Vector3D();
			_localPosition = new Vector3D();
			_eulerAngles = new Vector3D();
			_localEulerAngles = new Vector3D();
			_right = new Vector3D();
			_up = new Vector3D();
			_forward = new Vector3D();
			_rotation = new Quaternion();
			_localRotation = new Quaternion();
			_localScale = new Vector3D(1, 1, 1);
			_transform = new Matrix3D();
			_localTransform = new Matrix3D();
			_dirty = true;
		}
		
		private var _f :Vector3D = new Vector3D();
		private var _s :Vector3D = new Vector3D();
		private var _u :Vector3D = new Vector3D();
		
		/**
		 * 
		 */ 
		public function lookAt(target:Transform3D, up:Vector3D=null):void
		{
			_f.x = target.position.x - _position.x;
			_f.y = target.position.y - _position.y;
			_f.z = target.position.z - _position.z;
			_f.normalize();
			
			up = up || DEFAULT_LOOKAT_UP;
			
			_s.x = (up.y * _f.z) - (up.z * _f.y);
			_s.y = (up.z * _f.x) - (up.x * _f.z);
			_s.z = (up.x * _f.y) - (up.y * _f.x);
			_s.normalize();
			
			_u.x = (_s.y * _f.z) - (_s.z * _f.y);
			_u.y = (_s.z * _f.x) - (_s.x * _f.z);
			_u.z = (_s.x * _f.y) - (_s.y * _f.x);
			_u.normalize();
			
			var v :Vector.<Number> = Vector.<Number>([
				_s.x, _s.y, _s.z, 0,
				_u.x, _u.y, _u.z, 0,
				-_f.x, -_f.y, -_f.z, 0,
				0, 0, 0, 1
			]);
			
			_lookAt = _lookAt || new Matrix3D();
			_lookAt.rawData = v;
			
			_dirty = true;
		}
		
		public var _lookAt :Matrix3D;
		
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
			if (_dirty)
			{
				rotate( _localEulerAngles, true );
				
				_transform.rawData = _localRotation.matrix.rawData;
			
				
				_transform.appendTranslation( _localPosition.x, _localPosition.y, _localPosition.z);
	
				rotate( _eulerAngles, false );
				_transform.append( _rotation.matrix );
				
				_transform.prependScale(_localScale.x, _localScale.y, _localScale.z);
				_dirty = false;

			}		

			if (_lookAt)
			{
				//_transform = _lookAt.clone();
				//_transform.appendTranslation(0, 300, 0);
				//_transform.appendTranslation( -_position.x, -_position.y, -_position.z);
			//	_transform.invert();
			//	_transform.prepend(_lookAt);
			}
			
			if (parent)
			{
			//	var mat :Matrix3D = parent.localToWorldMatrix.clone();
			//	mat.append(_transform);
			//	_position = mat.transformVector(_localPosition);
			}	
			
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
			_dirty = true;
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
			_dirty = true;
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